AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local ACF         = ACF
local Classes     = ACF.Classes
local Contraption = ACF.Contraption
local Damage      = ACF.Damage
local Sounds      = ACF.Utilities.Sounds
local RadarHelpers = ACF.RadarHelpers
local UnlinkSound = "physics/metal/metal_box_impact_bullet%s.wav"
local MaxDistance = ACF.LinkDistance * ACF.LinkDistance
local TimerCreate = timer.Create
local TimerRemove = timer.Remove
local hook        = hook


-- Tracks every currently-spawned Synchronizer so the shared ACF_OnTick hook below can advance each one's
-- rate-group counters; mirrors the ACF.ActiveRadars pattern used for standalone radars
local ActiveSyncs = {}

-- Uses the same stable per-target integer ID scheme as acf_radar (own pool, not shared), so IDs stay
-- consistent for a target across scans within this synchronizer
local Indexes = {}
local Unused  = {}
local IndexCount = 0

local function GetEntityIndex(Entity)
	if Indexes[Entity] then return Indexes[Entity] end

	if next(Unused) then
		local Index = next(Unused)

		Indexes[Entity] = Index
		Unused[Index] = nil
	else
		IndexCount = IndexCount + 1

		Indexes[Entity] = IndexCount
	end

	local EntID = Indexes[Entity]

	Entity:CallOnRemove("SensorSync Index", function()
		Indexes[Entity] = nil
		Unused[EntID] = true
	end)

	return EntID
end

local function ClearTargets(Entity)
	local TargetInfo = Entity.TargetInfo
	local Targets = Entity.Targets

	for Target in pairs(Targets) do
		Targets[Target] = nil
	end

	for _, List in pairs(TargetInfo) do
		for Index in ipairs(List) do
			List[Index] = nil
		end
	end
end

local function SortByDamage(A, B)
	return (A.Damage or 0) < (B.Damage or 0)
end

-- Rewrites this Synchronizer's combined Targets/TargetInfo from the current BatchResults snapshot and
-- re-fires wire outputs. Safe to call with an empty BatchResults (e.g. all sensors unlinked). Clk only
-- bumps when the calling batch itself confirmed a detection this cycle
local function RefreshOutputs(Entity, BatchDetected)
	local TargetInfo = Entity.TargetInfo
	local Targets = Entity.Targets

	ClearTargets(Entity)

	local IDs = TargetInfo.ID
	local Own = TargetInfo.Owner
	local Position = TargetInfo.Position
	local Velocity = TargetInfo.Velocity
	local Distance = TargetInfo.Distance
	local Size = TargetInfo.Size
	local Type = TargetInfo.Type
	local Sensor = TargetInfo.Sensor
	local Closest = math.huge
	local Count = 0

	for Ent, Data in pairs(Entity.BatchResults) do
		local Index = GetEntityIndex(Ent)

		Count = Count + 1

		Targets[Ent] = {
			Index    = Index,
			Owner    = Data.Owner,
			Position = Data.Position,
			Velocity = Data.Velocity,
			Distance = Data.Distance,
			Spread   = Data.Spread,
			Type     = Data.Type,
			Sensor   = Data.FromSensor,
		}

		IDs[Count] = Index
		Own[Count] = Data.Owner
		Position[Count] = Data.Position
		Velocity[Count] = Data.Velocity
		Distance[Count] = Data.Distance
		Size[Count] = Data.Size
		Type[Count] = Data.Type
		Sensor[Count] = Data.FromSensor

		if Data.Distance < Closest then
			Closest = Data.Distance
		end
	end

	Closest = Closest < math.huge and Closest or 0

	WireLib.TriggerOutput(Entity, "ClosestDistance", Closest)
	WireLib.TriggerOutput(Entity, "IDs", IDs)
	WireLib.TriggerOutput(Entity, "Owner", Own)
	WireLib.TriggerOutput(Entity, "Position", Position)
	WireLib.TriggerOutput(Entity, "Velocity", Velocity)
	WireLib.TriggerOutput(Entity, "Distance", Distance)
	WireLib.TriggerOutput(Entity, "Detected", Count)
	WireLib.TriggerOutput(Entity, "Size", Size)
	WireLib.TriggerOutput(Entity, "Type", Type)
	WireLib.TriggerOutput(Entity, "Sensor", Sensor)

	local LinkedCount = 0
	for Linked in pairs(Entity.Sensors) do
		if IsValid(Linked) then LinkedCount = LinkedCount + 1 end
	end
	WireLib.TriggerOutput(Entity, "Linked Sensors", LinkedCount)

	-- Only bump Clk when this specific batch confirmed a detection
	if BatchDetected then
		WireLib.TriggerOutput(Entity, "Clk", engine.TickCount())
	end

	if Count ~= Entity.TargetCount then
		if Count > Entity.TargetCount then
			Sounds.SendSound(Entity, Entity.SoundPath, 70, 100, 1)
		end

		Entity.TargetCount = Count

		Entity:UpdateOverlay()
	end

	-- Guidance packages read a rack-linked radar's own .Targets/.TargetCount directly; mirror this
	-- Synchronizer's combined results back onto every currently-linked radar so a rack linked to any one
	-- of them transparently sees the aggregated picture with no guidance-side changes needed
	for Linked in pairs(Entity.Sensors) do
		if not IsValid(Linked) or Linked:GetClass() ~= "acf_radar" then continue end

		Linked.Targets = Targets
		Linked.TargetCount = Count
	end
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

-- Runs one rate-group batch: gathers all its sensors' geometry into one pass per candidate pool
-- (contraptions, missiles, players) instead of one pass per sensor, then attributes each candidate to the
-- healthiest matching sensor that has line of sight to it. Sensors are only added to the pools they're
-- set to detect, so e.g. a missile-only radar never contributes to contraption detection here
local function RunBatch(Entity, GroupSensors)
	local ContraptionShapes = {}
	local MissileShapes = {}
	local PlayerShapes = {}

	for Sensor in pairs(GroupSensors) do
		if not IsValid(Sensor) or Sensor.ACF.Health <= 0 then continue end

		local Shape = Sensor:GetScanShape()

		if Sensor.DetectContraptions then ContraptionShapes[#ContraptionShapes + 1] = Shape end
		if Sensor.DetectMissiles then MissileShapes[#MissileShapes + 1] = Shape end
		if Sensor.DetectPlayers then PlayerShapes[#PlayerShapes + 1] = Shape end
	end

	if #ContraptionShapes == 0 and #MissileShapes == 0 and #PlayerShapes == 0 then return RefreshOutputs(Entity, false) end

	local OwnContraption = Entity:CFW_GetContraption()
	local Matches = {}

	if #ContraptionShapes > 0 then MergeMatches(Matches, ACF.GetEntitiesInShapes(ContraptionShapes, OwnContraption)) end
	if #MissileShapes > 0 then MergeMatches(Matches, ACF.Countermeasures.GetMissilesInShapes(MissileShapes)) end
	if #PlayerShapes > 0 then MergeMatches(Matches, RadarHelpers.GetPlayersInShapes(PlayerShapes, OwnContraption)) end

	local Confirmed = {}

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

		local EntDist = Origin:Distance(EntPos)
		local EntSize, EntType = RadarHelpers.GetEntSizeAndType(Ent)

		if EntSize < RadarHelpers.GetMinDetectableSize(Sensor, EntDist) then continue end

		local Spread = ACF.MaxDamageInaccuracy * EntDamage
		local EntSpread = VectorRand(-Spread, Spread)
		local EntVel = Ent.ACF_Velocity or Ent:GetVelocity()

		Confirmed[Ent] = true

		Entity.BatchResults[Ent] = {
			Owner      = RadarHelpers.GetEntityOwner(Entity.Owner, Ent),
			Position   = EntPos + EntSpread,
			Velocity   = EntVel + EntSpread,
			Distance   = EntDist,
			Size       = EntSize,
			Type       = EntType,
			Spread     = EntSpread,
			FromSensor = Sensor,
		}
	end

	-- Drop stale results this rate-group no longer confirms (failed LOS/damage-roll/min-size this cycle,
	-- or moved out of every linked sensor's zone), without touching results still being reported by other
	-- rate-groups
	for Ent, Data in pairs(Entity.BatchResults) do
		if GroupSensors[Data.FromSensor] and not Confirmed[Ent] then
			Entity.BatchResults[Ent] = nil
		end
	end

	RefreshOutputs(Entity, next(Confirmed) ~= nil)
end

-- Regroups this Synchronizer's linked sensors by their exact ThinkTicks, so sensors are never sped up or
-- slowed down by another linked sensor's scan rate. Each distinct tick interval gets its own counter,
-- advanced by the shared ACF_OnTick hook below
local function RebuildRateGroups(Entity)
	local Groups = {}

	for Sensor in pairs(Entity.Sensors) do
		if not IsValid(Sensor) or not Sensor.Active then continue end

		local Ticks = Sensor.ThinkTicks
		Groups[Ticks] = Groups[Ticks] or { Sensors = {}, Counter = 0, ThinkTicks = Ticks }
		Groups[Ticks].Sensors[Sensor] = true
	end

	Entity.RateGroups = Groups

	-- Prune results attributed to a sensor that's no longer linked/active in any current group
	for Ent, Data in pairs(Entity.BatchResults) do
		local Group = Data.FromSensor and Groups[Data.FromSensor.ThinkTicks]
		local StillGrouped = Group and Group.Sensors[Data.FromSensor]

		if not StillGrouped then
			Entity.BatchResults[Ent] = nil
		end
	end

	if not next(Groups) then
		-- No active linked sensors left
		RefreshOutputs(Entity, false)

		return
	end

	-- Run each group once immediately so it doesn't wait a full cycle for its first result
	for _, Group in pairs(Groups) do
		RunBatch(Entity, Group.Sensors)
	end
end

-- Advances every currently-spawned Synchronizer's rate-group counters each server tick, running a group's
-- batch every N ticks (N = that group's shared ThinkTicks), same scan rate as standalone sensors
hook.Add("ACF_OnTick", "ACF SensorSync Scan", function()
	for Entity in pairs(ActiveSyncs) do
		if not IsValid(Entity) then continue end

		for _, Group in pairs(Entity.RateGroups) do
			Group.Counter = Group.Counter + 1

			if Group.Counter >= Group.ThinkTicks then
				Group.Counter = 0

				RunBatch(Entity, Group.Sensors)
			end
		end
	end
end)

local function CheckDistantLinks(Entity, Source)
	local Position = Entity:GetPos()

	for Link in pairs(Entity[Source]) do
		if Position:DistToSqr(Link:GetPos()) > MaxDistance then
			local Sound = UnlinkSound:format(math.random(1, 3))

			Sounds.SendSound(Entity, Sound, 70, 100, 1)
			Sounds.SendSound(Link, Sound, 70, 100, 1)

			Entity:Unlink(Link)
		end
	end
end

--===============================================================================================--

-- When linked, a sensor stops running its own scan and outputs, and instead becomes a passive
-- reference point for the Synchronizer's aggregated scan
for SensorClass in pairs(ENT.ACF_SensorClasses) do
	ACF.RegisterClassLink("acf_sensorsync", SensorClass, function(Sync, Sensor)
		if IsValid(Sensor.SyncSource) then return false, "This sensor is already linked to a synchronizer!" end

		Sync.Sensors[Sensor] = true
		Sensor.SyncSource = Sync

		Sensor:StopIndependentScanning()
		Sync:RefreshRateGroups()

		Sync:UpdateOverlay()
		Sensor:UpdateOverlay()

		return true, "Sensor linked successfully!"
	end)

	ACF.RegisterClassUnlink("acf_sensorsync", SensorClass, function(Sync, Sensor)
		if not Sync.Sensors[Sensor] and Sensor.SyncSource ~= Sync then
			return false, "This sensor is not linked to this synchronizer."
		end

		Sync.Sensors[Sensor] = nil
		Sensor.SyncSource = nil

		Sensor:ResumeIndependentScanning()

		if IsValid(Sync) then Sync:RefreshRateGroups() end

		Sync:UpdateOverlay()
		Sensor:UpdateOverlay()

		return true, "Sensor unlinked successfully!"
	end)
end

ACF.RegisterLinkSource("acf_sensorsync", "Sensors")

--===============================================================================================--
-- Spawning and Updating
--===============================================================================================--

local SyncClass = "ACF.Components.SensorSync"

do -- Spawning
	function ENT:ACF_PreSpawn()
		self.ACF = {}

		local Class = Classes.GetTypeByName(SyncClass)

		Contraption.SetModel(self, Class.Model)
	end

	function ENT:ACF_OnSpawn()
		self.RateGroups   = {}
		self.BatchResults = {}
		self.TargetCount  = 0
		self.Targets      = {}
		self.TargetInfo   = {
			ID = {},
			Owner = {},
			Position = {},
			Velocity = {},
			Distance = {},
			Size = {},
			Type = {},
			Sensor = {}
		}

		ActiveSyncs[self] = true

		TimerCreate("ACF SensorSync Clock " .. self:EntIndex(), 3, 0, function()
			if not IsValid(self) then return end

			CheckDistantLinks(self, "Sensors")
		end)
	end
end

do -- Updating
	function ENT:ACF_PostUpdateEntityData()
		local Class = Classes.GetTypeByName(SyncClass)

		Contraption.SetModel(self, Class.Model)

		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)

		self.Name      = Class.Name
		self.ShortName = Class.ID
		self.EntType   = Class.Name
		self.ClassType = Class.ID
		self.ClassData = Class
		self.SoundPath = Class.Sound or ACF.DefaultRadarSound
		self.Origin    = Vector()
		self.Sensors   = self:ACF_GetUserVar("Sensors") -- Auto-registered linked field, so dupes save and restore links

		self:SetNWString("WireName", "ACF " .. self.Name)

		-- ACF.Activate(self, true) is invoked automatically by ACF_UpdateEntityData after this.

		Contraption.SetMass(self, Class.Mass)
	end
end

--===============================================================================================--
-- Meta Funcs
--===============================================================================================--

function ENT:ACF_OnDamage(DmgResult, DmgInfo)
	return Damage.doPropDamage(self, DmgResult, DmgInfo)
end

function ENT:GetCost()
	return ACF.SensorSyncCost
end

function ENT:Enable() end
function ENT:Disable() end

function ENT:ACF_UpdateOverlayState(State)
	local LinkedCount = 0
	for Sensor in pairs(self.Sensors) do
		if IsValid(Sensor) then LinkedCount = LinkedCount + 1 end
	end

	if self.TargetCount > 0 then
		State:AddSuccess(self.TargetCount .. " target(s) detected")
	elseif LinkedCount == 0 then
		State:AddWarning("No sensors linked")
	else
		State:AddSuccess("Active")
	end

	State:AddKeyValue("Linked sensors", LinkedCount)
end

-- Called by a linked sensor whenever its own ThinkTicks or Active state changes so this Synchronizer's
-- rate groups stay in sync
function ENT:RefreshRateGroups()
	RebuildRateGroups(self)
end

function ENT:OnRemove()
	for Sensor in pairs(self.Sensors) do
		self:Unlink(Sensor)
	end

	ActiveSyncs[self] = nil

	TimerRemove("ACF SensorSync Clock " .. self:EntIndex())

	WireLib.Remove(self)
end
