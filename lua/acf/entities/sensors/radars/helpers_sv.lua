-- Shared detection-scan helpers used by acf_radar, acf_irst and acf_sensorsync
local ACF = ACF
ACF.RadarHelpers = ACF.RadarHelpers or {}

local RadarHelpers = ACF.RadarHelpers
local TraceData = { start = true, endpos = true, mask = MASK_SOLID_BRUSHONLY, filter = {} }
local Trace = ACF.trace

-- Minimum target size (in inches) detectable at a given distance, given the radar's own MinSizeAtRange
-- (the smallest target it can see at its own max range) and Range. Scales down toward 0 as distance
-- approaches 0, so all radars can see small targets up close, but only larger radars can see
-- small targets far away. Non linear to mimic how realistic detection strength falls off with range.
-- Higher exponent = detection of small targets falls off faster with range (near targets barely change)
local MinSizeExponent = 2

function RadarHelpers.GetMinDetectableSize(Radar, EntDist)
	local MinSizeAtRange = Radar.MinSizeAtRange

	if not MinSizeAtRange or not Radar.Range then return 0 end

	return MinSizeAtRange * (EntDist / Radar.Range) ^ MinSizeExponent
end

-- World only line of sight check between a radar's origin and a candidate's position
function RadarHelpers.CheckLOS(Start, End)
	TraceData.start = Start
	TraceData.endpos = End

	return not Trace(TraceData).Hit
end

-- If radar info is restricted and the radar's owner doesn't have permissions on the target, its name is
-- withheld as Unknown. Otherwise resolves to the target's actual owner name, or World/Unknown if it has none
function RadarHelpers.GetEntityOwner(Owner, Entity)
	if ACF.RestrictRadarInfo and (not IsValid(Owner) or not Entity:CPPICanTool(Owner)) then
		return "Unknown"
	end

	if Entity:IsPlayer() then return Entity:GetName() end

	local EntOwner = Entity:CPPIGetOwner()

	if not IsValid(EntOwner) then
		return EntOwner == game.GetWorld() and "World" or "Unknown"
	end

	return EntOwner:GetName()
end

-- Measuring a contraption walks all its entities, so every sensor shares one size per contraption for a while
local SizeCacheTime = 0.5
local SizeCache     = setmetatable({}, { __mode = "k" }) -- Contraption -> size cache
local SizeExpiry    = setmetatable({}, { __mode = "k" }) -- Contraption -> cache expiry time

-- Classifies a detected candidate and measures its size. Missiles are sized by caliber, contraptions and
-- players by their bounding box diagonal. Returns 0, nil for anything else
function RadarHelpers.GetEntSizeAndType(Ent)
	if Ent.IsACFMissile then
		return math.Round((Ent.Caliber or 0) / ACF.InchToMm), "Missile"
	end

	if Ent:IsPlayer() then
		local Mins, Maxs = Ent:OBBMins(), Ent:OBBMaxs()

		return math.Round((Maxs - Mins):Length()), "Player"
	end

	local EntContraption = Ent:CFW_GetContraption()

	if EntContraption then
		local Now = CurTime()

		if Now >= (SizeExpiry[EntContraption] or 0) then
			local Mins, Maxs = EntContraption:GetAABB()

			SizeCache[EntContraption]  = math.Round((Maxs - Mins):Length())
			SizeExpiry[EntContraption] = Now + SizeCacheTime
		end

		return SizeCache[EntContraption], "Contraption"
	end

	return 0, nil
end

function RadarHelpers.GetTargetPos(Ent)
	if Ent:IsPlayer() then return Ent:WorldSpaceCenter() end

	return Ent.ACF_Position or Ent:GetPos()
end

-- Seated players are skipped; the contraption they're riding is what gets detected
function RadarHelpers.GetPlayersInShapes(Shapes, Contraption)
	local Result = {}

	for _, Ply in player.Iterator() do
		if not Ply:Alive() or Ply:InVehicle() then continue end
		if Contraption and Ply:CFW_GetContraption() == Contraption then continue end

		ACF.Countermeasures.MatchShapes(Result, Ply, Ply:WorldSpaceCenter(), Shapes)
	end

	return Result
end

do -- MARK: Target publishing
	local Indexes    = {}
	local Unused     = {}
	local IndexCount = 0

	-- Stable integer ID per target, shared by every sensor so one target has one ID everywhere
	function RadarHelpers.GetTargetIndex(Ent)
		if Indexes[Ent] then return Indexes[Ent] end

		local Index = next(Unused)

		if Index then
			Unused[Index] = nil
		else
			IndexCount = IndexCount + 1
			Index      = IndexCount
		end

		Indexes[Ent] = Index

		Ent:CallOnRemove("ACF Sensor Index", function()
			Indexes[Ent] = nil
			Unused[Index] = true
		end)

		return Index
	end

	local function ClearTargets(Entity)
		local Targets = Entity.Targets

		for Target in pairs(Targets) do
			Targets[Target] = nil
		end

		for _, List in pairs(Entity.TargetInfo) do
			for Index in ipairs(List) do
				List[Index] = nil
			end
		end
	end

	local function TriggerTargetOutputs(Entity, Count, Closest)
		local TargetInfo = Entity.TargetInfo

		WireLib.TriggerOutput(Entity, "ClosestDistance", Closest)
		WireLib.TriggerOutput(Entity, "IDs", TargetInfo.ID)
		WireLib.TriggerOutput(Entity, "Owner", TargetInfo.Owner)
		WireLib.TriggerOutput(Entity, "Position", TargetInfo.Position)
		WireLib.TriggerOutput(Entity, "Velocity", TargetInfo.Velocity)
		WireLib.TriggerOutput(Entity, "Distance", TargetInfo.Distance)
		WireLib.TriggerOutput(Entity, "Detected", Count)
		WireLib.TriggerOutput(Entity, "Size", TargetInfo.Size)
		WireLib.TriggerOutput(Entity, "Type", TargetInfo.Type)

		if TargetInfo.Sensor then
			WireLib.TriggerOutput(Entity, "Sensor", TargetInfo.Sensor)
		end
	end

	-- Rewrites Targets/TargetInfo from Detections (target -> detection data) and fires the wire outputs
	-- Clk only bumps when Bump is true, the detection sound only plays when the count goes up
	function RadarHelpers.PublishTargets(Entity, Detections, Bump)
		ClearTargets(Entity)

		local TargetInfo = Entity.TargetInfo
		local Targets    = Entity.Targets
		local Sensors    = TargetInfo.Sensor
		local Closest    = math.huge
		local Count      = 0

		for Ent, Data in pairs(Detections) do
			local Index = RadarHelpers.GetTargetIndex(Ent)

			Count = Count + 1

			Targets[Ent] = {
				Index    = Index,
				Owner    = Data.Owner,
				Position = Data.Position,
				Velocity = Data.Velocity,
				Distance = Data.Distance,
				Spread   = Data.Spread,
				Type     = Data.Type,
				Sensor   = Data.Sensor,
			}

			TargetInfo.ID[Count]       = Index
			TargetInfo.Owner[Count]    = Data.Owner
			TargetInfo.Position[Count] = Data.Position
			TargetInfo.Velocity[Count] = Data.Velocity
			TargetInfo.Distance[Count] = Data.Distance
			TargetInfo.Size[Count]     = Data.Size
			TargetInfo.Type[Count]     = Data.Type

			if Sensors then Sensors[Count] = Data.Sensor end

			if Data.Distance < Closest then
				Closest = Data.Distance
			end
		end

		TriggerTargetOutputs(Entity, Count, Closest < math.huge and Closest or 0)

		if Bump then
			WireLib.TriggerOutput(Entity, "Clk", engine.TickCount())
		end

		if Count == Entity.TargetCount then return end

		if Count > Entity.TargetCount then
			ACF.Utilities.Sounds.SendSound(Entity, Entity.SoundPath, 70, 100, 1)
		end

		Entity.TargetCount = Count

		Entity:UpdateOverlay()
	end

	-- Clears every target and zeroes the outputs, skipped if there was nothing to clear
	function RadarHelpers.ResetTargets(Entity)
		if Entity.TargetCount == 0 then return end

		RadarHelpers.PublishTargets(Entity, {}, false)
	end
end

do -- MARK: Target detection
	local function SortByDamage(A, B)
		return (A.Damage or 0) < (B.Damage or 0)
	end

	local function MergeMatches(Matches, Found)
		for Ent, MatchedSensors in pairs(Found) do
			local List = Matches[Ent]

			if not List then
				Matches[Ent] = MatchedSensors
			else
				for _, Sensor in ipairs(MatchedSensors) do
					List[#List + 1] = Sensor
				end
			end
		end
	end

	-- Scans for every sensor in Sensors at once, one pass per candidate pool instead of one per sensor
	-- Each target goes to the least damaged sensor that sees it, Entity is the owner of the results
	function RadarHelpers.DetectTargets(Entity, Sensors)
		local ContraptionShapes = {}
		local MissileShapes     = {}
		local PlayerShapes      = {}
		local Detections        = {}

		for Sensor in pairs(Sensors) do
			if not IsValid(Sensor) or ACF.IsDestroyed(Sensor) then continue end

			local Shape = Sensor:GetScanShape()

			if Sensor.DetectContraptions then ContraptionShapes[#ContraptionShapes + 1] = Shape end
			if Sensor.DetectMissiles then MissileShapes[#MissileShapes + 1] = Shape end
			if Sensor.DetectPlayers then PlayerShapes[#PlayerShapes + 1] = Shape end
		end

		local OwnContraption = Entity:CFW_GetContraption()
		local Matches        = {}

		if ContraptionShapes[1] then MergeMatches(Matches, ACF.GetEntitiesInShapes(ContraptionShapes, OwnContraption)) end
		if MissileShapes[1] then MergeMatches(Matches, ACF.Countermeasures.GetMissilesInShapes(MissileShapes)) end
		if PlayerShapes[1] then MergeMatches(Matches, RadarHelpers.GetPlayersInShapes(PlayerShapes, OwnContraption)) end

		for Ent, MatchedSensors in pairs(Matches) do
			local EntPos = RadarHelpers.GetTargetPos(Ent)
			local Sensor, Origin

			table.sort(MatchedSensors, SortByDamage)

			for _, Candidate in ipairs(MatchedSensors) do
				local CandidateOrigin = Candidate:LocalToWorld(Candidate.Origin)

				if Candidate:CheckTargetLOS(CandidateOrigin, Ent, EntPos) then
					Sensor = Candidate
					Origin = CandidateOrigin

					break
				end
			end

			if not Sensor then continue end

			local EntDamage = Sensor.Damage or 0
			if math.Rand(0, 1) < (EntDamage / 10) then continue end

			local EntDist          = Origin:Distance(EntPos)
			local EntSize, EntType = RadarHelpers.GetEntSizeAndType(Ent)

			if EntSize < RadarHelpers.GetMinDetectableSize(Sensor, EntDist) then continue end

			local Spread    = ACF.MaxDamageInaccuracy * EntDamage
			local EntSpread = VectorRand(-Spread, Spread)
			local EntVel    = Ent.ACF_Velocity or Ent:GetVelocity()

			Detections[Ent] = {
				Owner    = RadarHelpers.GetEntityOwner(Entity.Owner, Ent),
				Position = EntPos + EntSpread,
				Velocity = EntVel + EntSpread,
				Distance = EntDist,
				Size     = EntSize,
				Type     = EntType,
				Spread   = EntSpread,
				Sensor   = Sensor,
			}
		end

		return Detections
	end
end

do -- MARK: Sensor lifecycle
	local function SwitchTimer(Entity)
		return "ACF Sensor Switch " .. Entity:EntIndex()
	end

	-- Entities can define OnScanningChanged(Active) for their own side effects
	function RadarHelpers.SetScanning(Entity, Active)
		Entity.Scanning    = Active
		Entity.TickCounter = 0

		RadarHelpers.ResetTargets(Entity)

		WireLib.TriggerOutput(Entity, "Scanning", Active and 1 or 0)

		if Entity.OnScanningChanged then
			Entity:OnScanningChanged(Active)
		end

		if IsValid(Entity.SyncSource) then
			Entity.SyncSource:RefreshRateGroups()
		end

		Entity:UpdateOverlay()
	end

	-- Scanning starts Entity.SwitchDelay seconds after activation and stops as soon as it's deactivated
	function RadarHelpers.SetActive(Entity, Active)
		if Entity.Active == Active then return end

		local TimerName = SwitchTimer(Entity)

		Entity.Active = Active

		timer.Remove(TimerName)

		if not Active then return RadarHelpers.SetScanning(Entity, false) end

		Entity:UpdateOverlay()

		timer.Create(TimerName, Entity.SwitchDelay, 1, function()
			if IsValid(Entity) then
				RadarHelpers.SetScanning(Entity, true)
			end
		end)
	end

	function RadarHelpers.CancelSwitch(Entity)
		timer.Remove(SwitchTimer(Entity))
	end

	-- Called every tick, scans every Entity.ThinkTicks ticks unless a Synchronizer is scanning for it
	function RadarHelpers.TickScan(Entity)
		if not Entity.Scanning or IsValid(Entity.SyncSource) then return end

		Entity.TickCounter = Entity.TickCounter + 1

		if Entity.TickCounter < Entity.ThinkTicks then return end

		local Detections = RadarHelpers.DetectTargets(Entity, { [Entity] = true })

		Entity.TickCounter = 0

		RadarHelpers.PublishTargets(Entity, Detections, next(Detections) ~= nil)
	end

	-- Damage fraction that drives the detection miss chance and target spread
	function RadarHelpers.UpdateDamage(Entity)
		Entity.Damage = 1 - math.Round(Entity.ACF.Health / Entity.ACF.MaxHealth, 2)
	end

	function RadarHelpers.AddScanState(Entity, State)
		if Entity.TargetCount > 0 then
			State:AddSuccess(Entity.TargetCount .. " target(s) detected")
		elseif not Entity.Active then
			State:AddWarning("Idle")
		elseif Entity.Scanning then
			State:AddSuccess("Active")
		else
			State:AddWarning("Activating")
		end
	end
end
