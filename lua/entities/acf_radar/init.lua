AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local ACF = ACF
local Contraption	= ACF.Contraption

ACF.RegisterClassLink("acf_radar", "acf_rack", function(Radar, Target)
	if Radar.Weapons[Target] then return false, "This rack is already linked to this radar!" end
	if Target.Radar == Radar then return false, "This rack is already linked to this radar!" end

	Radar.Weapons[Target] = true
	Target.Radar = Radar

	Radar:UpdateOverlay()
	Target:UpdateOverlay()

	return true, "Rack linked successfully!"
end)

ACF.RegisterClassUnlink("acf_radar", "acf_rack", function(Radar, Target)
	if Radar.Weapons[Target] or Target.Radar == Radar then
		Radar.Weapons[Target] = nil
		Target.Radar = nil

		Radar:UpdateOverlay()
		Target:UpdateOverlay()

		return true, "Rack unlinked successfully!"
	end

	return false, "This rack is not linked to this radar."
end)

-- Radar Synchronizer link: when linked, a radar stops running its own scan timer/outputs and instead
-- becomes a passive reference point for the Synchronizer (see SetScanning below and 
-- lua/entities/acf_radarsync/init.lua for the aggregation side)
ACF.RegisterClassLink("acf_radarsync", "acf_radar", function(Sync, Radar)
	if IsValid(Radar.SyncSource) then return false, "This radar is already linked to a synchronizer!" end

	Sync.Radars[Radar] = true
	Radar.SyncSource = Sync

	Radar:StopIndependentScanning()
	Sync:RefreshRateGroups()

	Sync:UpdateOverlay()
	Radar:UpdateOverlay()

	return true, "Radar linked successfully!"
end)

ACF.RegisterClassUnlink("acf_radarsync", "acf_radar", function(Sync, Radar)
	if not Sync.Radars[Radar] and Radar.SyncSource ~= Sync then
		return false, "This radar is not linked to this synchronizer."
	end

	Sync.Radars[Radar] = nil
	Radar.SyncSource = nil

	Radar:ResumeIndependentScanning()

	if IsValid(Sync) then Sync:RefreshRateGroups() end

	Sync:UpdateOverlay()
	Radar:UpdateOverlay()

	return true, "Radar unlinked successfully!"
end)

--===============================================================================================--
-- Local Funcs and Vars
--===============================================================================================--

local Radars	  = ACF.ActiveRadars
local Damage      = ACF.Damage
local Sounds      = ACF.Utilities.Sounds
local UnlinkSound = "physics/metal/metal_box_impact_bullet%s.wav"
local MaxDistance = ACF.LinkDistance * ACF.LinkDistance
local TraceData	  = { start = true, endpos = true, mask = MASK_SOLID_BRUSHONLY, filter = {} }
local Indexes	  = {}
local Unused	  = {}
local IndexCount  = 0
local Trace       = ACF.trace
local TimerExists = timer.Exists
local TimerCreate = timer.Create
local TimerRemove = timer.Remove
local hook        = hook

-- TODO: Optimize this so the entries are only cleared when the target is no longer detected by the radar
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

local function ResetOutputs(Entity)
	if Entity.TargetCount == 0 then return end

	local TargetInfo = Entity.TargetInfo

	ClearTargets(Entity)

	Entity.TargetCount = 0

	WireLib.TriggerOutput(Entity, "Detected", 0)
	WireLib.TriggerOutput(Entity, "ClosestDistance", 0)
	WireLib.TriggerOutput(Entity, "IDs", TargetInfo.ID)
	WireLib.TriggerOutput(Entity, "Owner", TargetInfo.Owner)
	WireLib.TriggerOutput(Entity, "Position", TargetInfo.Position)
	WireLib.TriggerOutput(Entity, "Velocity", TargetInfo.Velocity)
	WireLib.TriggerOutput(Entity, "Distance", TargetInfo.Distance)
	WireLib.TriggerOutput(Entity, "Size", TargetInfo.Size)
	WireLib.TriggerOutput(Entity, "Type", TargetInfo.Type)
end

local function SetSequence(Entity, Active)
	local SequenceName = Active and "active" or "idle"
	local Sequence = Entity:LookupSequence(SequenceName)

	Entity:ResetSequence(Sequence or 0)

	Entity.AutomaticFrameAdvance = Active
end

local function CheckLOS(Start, End)
	TraceData.start = Start
	TraceData.endpos = End

	return not Trace(TraceData).Hit
end

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

	Entity:CallOnRemove("Radar Index", function()
		Indexes[Entity] = nil
		Unused[EntID] = true
	end)

	return EntID
end

local function GetEntityOwner(Owner, Entity)
	-- If radar info is restricted and the radar owner doesn't have permissions on this entity then return Unknown
	if ACF.RestrictRadarInfo and (not IsValid(Owner) or not Entity:CPPICanTool(Owner)) then
		return "Unknown"
	end

	local EntOwner = Entity:CPPIGetOwner()

	if not IsValid(EntOwner) then
		EntOwner = EntOwner == game.GetWorld() and "World" or "Unknown"
	else
		EntOwner = EntOwner:GetName()
	end

	return EntOwner
end

-- Minimum target size (in inches) detectable at a given distance, given the radar's own MinSizeAtRange
-- (the smallest target it can see at its own max range) and Range. Scales down toward 0 as distance
-- approaches 0, so all radars can see small targets up close, but only larger radars can see
-- small targets far away. Non linear to mimic how realistic detection strength falls off with range
local MinSizeExponent = 1.5

local function GetMinDetectableSize(Entity, EntDist)
	local MinSizeAtRange = Entity.MinSizeAtRange

	if not MinSizeAtRange or not Entity.Range then return 0 end

	return MinSizeAtRange * (EntDist / Entity.Range) ^ MinSizeExponent
end

local function ScanForEntities(Entity)
	ClearTargets(Entity)

	if Entity.ACF.Health <= 0 then return end -- Destroyed
	if not Entity.GetDetected then return end

	local Detected = Entity:GetDetected()

	local Origin = Entity:LocalToWorld(Entity.Origin)
	local TargetInfo = Entity.TargetInfo
	local Targets = Entity.Targets
	local Closest = math.huge
	local Count = 0

	local IDs = TargetInfo.ID
	local Own = TargetInfo.Owner
	local Position = TargetInfo.Position
	local Velocity = TargetInfo.Velocity
	local Distance = TargetInfo.Distance
	local Size = TargetInfo.Size
	local Type = TargetInfo.Type

	local EntDamage = Entity.Damage
	local Spread = ACF.MaxDamageInaccuracy * EntDamage

	for Ent in pairs(Detected) do
		local EntPos = Ent.ACF_Position or Ent:GetPos()

		if CheckLOS(Origin, EntPos) and (math.Rand(0, 1) >= (EntDamage / 10)) then
			local EntDist = Origin:Distance(EntPos)

			local EntSize = 0
			local EntType

			if Ent.IsACFMissile then
				EntSize = (Ent.Caliber or 0) / ACF.InchToMm
				EntType = "Missile"
			elseif Ent:CFW_GetContraption() then
				local Mins, Maxs, _ = Ent:CFW_GetContraption():GetAABB()
				EntSize = (Maxs - Mins):Length()
				EntType = "Contraption"
			end
			EntSize = math.Round(EntSize) -- Round to nearest inch

			if EntSize < GetMinDetectableSize(Entity, EntDist) then continue end

			local EntSpread = VectorRand(-Spread, Spread)
			local EntVel = Ent.ACF_Velocity or Ent:GetVelocity()
			local Owner = GetEntityOwner(Entity.Owner, Ent)
			local Index = GetEntityIndex(Ent)

			EntPos = EntPos + EntSpread
			EntVel = EntVel + EntSpread
			Count = Count + 1

			Targets[Ent] = {
				Index = Index,
				Owner = Owner,
				Position = EntPos,
				Velocity = EntVel,
				Distance = EntDist,
				Spread   = EntSpread,
				Type     = EntType,
			}

			IDs[Count] = Index
			Own[Count] = Owner
			Position[Count] = EntPos
			Velocity[Count] = EntVel
			Distance[Count] = EntDist
			Size[Count] = EntSize
			Type[Count] = EntType

			if EntDist < Closest then
				Closest = EntDist
			end
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

	-- Only bump Clk on scans that actually found something
	if Count > 0 then
		WireLib.TriggerOutput(Entity, "Clk", engine.TickCount())
	end

	if Count ~= Entity.TargetCount then
		if Count > Entity.TargetCount then
			Sounds.SendSound(Entity, Entity.SoundPath, 70, 100, 1)
		end

		Entity.TargetCount = Count

		Entity:UpdateOverlay()
	end
end

local function SetScanning(Entity, Active)
	Entity.Scanning = Active
	Entity.TickCounter = 0

	Entity:UpdateOverlay()

	ResetOutputs(Entity)
	SetSequence(Entity, Active)

	Radars[Entity] = Active or nil

	WireLib.TriggerOutput(Entity, "Scanning", Active and 1 or 0)

	-- When linked to a Radar Synchronizer, this radar is used as a passive reference point for the 
	-- Synchronizer's own aggregated scan; it does not run its own scan cycle or populate its own
	-- outputs. Its Scanning/Active state is still used (a synced radar can still be turned off, which
	-- excludes it from the Synchronizer's aggregation), only the independent scan loop is skipped
	if IsValid(Entity.SyncSource) then
		Entity.SyncSource:RefreshRateGroups()
	end

	-- Actual scanning (both standalone and Synchronizer-driven) happens on the shared ACF_OnTick tick
	-- counter below, not here. This just flips Scanning and resets the counter so the next tick starts clean
end

-- Deterministic, tick-counted scan rate: one shared hook advances every currently-scanning, standalone
-- radar's own tick counter each tick, and runs a scan exactly every Entity.ThinkTicks ticks- as opposed 
-- to a timer, which may not be precise. Radars linked to a Radar Synchronizer are skipped 
-- here; their scanning is driven by the Synchronizer's own batching logic instead 
-- (see lua/entities/acf_radarsync/init.lua)
hook.Add("ACF_OnTick", "ACF Radar Scan", function()
	for Entity in pairs(Radars) do
		if not IsValid(Entity) or not Entity.Scanning then continue end
		if IsValid(Entity.SyncSource) then continue end

		Entity.TickCounter = Entity.TickCounter + 1

		if Entity.TickCounter >= Entity.ThinkTicks then
			Entity.TickCounter = 0

			ScanForEntities(Entity)
		end
	end
end)

local function SetActive(Entity, Active)
	if Entity.Active == Active then return end

	Entity.Active = Active

	Entity:UpdateOverlay()

	if TimerExists("ACF Radar Switch " .. Entity:EntIndex()) then
		TimerRemove("ACF Radar Switch " .. Entity:EntIndex())
	end

	if not Active then return SetScanning(Entity, Active) end

	TimerCreate("ACF Radar Switch " .. Entity:EntIndex(), Entity.SwitchDelay, 1, function()
		if IsValid(Entity) then
			return SetScanning(Entity, Active)
		end
	end)
end

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

ACF.AddInputAction("acf_radar", "Active", function(Entity, Value)
	SetActive(Entity, tobool(Value))
end)

--===============================================================================================--

do -- Spawn and Update functions
	local Classes  = ACF.Classes
	local WireIO   = ACF.Utilities.WireIO
	local Entities = Classes.Entities
	local Sensors  = Classes.Sensors
	local Inputs   = { "Active (If set to a non-zero value, attempts to start the radar activation.)" }

	local Outputs = {
		"Scanning (Returns 1 if the radar is currently scanning.)",
		"Detected (Returns the amount of targets detected by the radar.)",
		"ClosestDistance (Returns the distance in inches of the closest target detected by the radar.)",
		"IDs (Returns a list of IDs from all the detected targets.) [ARRAY]",
		"Owner (Returns a list of owner names from all the detected targets.) [ARRAY]",
		"Position (Returns a list of position vectors from all the detected targets.) [ARRAY]",
		"Velocity (Returns a list of velocity vectors from all the detected targets.) [ARRAY]",
		"Distance (Returns a list of distances from all the detected targets.) [ARRAY]",
		"Size (Returns a list of diameters, in inches, of all the detected targets.) [ARRAY]",
		"Type (Returns a list of target types for all detected targets.) [ARRAY]",
		"Think Delay (Returns the amount of time in seconds between each scan.)",
		"Clk (Returns engine.TickCount at the moment of the radar's last scan.)",
		"Entity (The radar itself.) [ENTITY]"
	}

	local function VerifyData(Data)
		if not Data.Radar then
			Data.Radar = Data.Sensor or Data.Id
		end

		local Class = Classes.GetGroup(Sensors, Data.Radar)

		-- Backwards compatibility for pre-merged Missile/Targeting radar classes and items
		if not Class then
			local AliasData = ACF.Compatibility.Radars.CheckGroupItem(Data.Radar)

			if AliasData then
				Data.Radar = AliasData.ID

				-- Old antimissile radars only detected missiles, and old targeting radars only
				-- detected contraptions. Carry that forward as an explicit default rather than
				-- giving old dupes both detection types
				if AliasData.Overrides then
					for K, V in pairs(AliasData.Overrides) do
						if Data[K] == nil then Data[K] = V end
					end
				end

				Class = Classes.GetGroup(Sensors, Data.Radar)
			end
		end

		if not Class or Class.Entity ~= "acf_radar" then
			Data.Radar = "SmallDIR"

			Class = Classes.GetGroup(Sensors, "SmallDIR")
		end

		-- A radar must be able to detect at least one target type. Default to both if nothing was
		-- specified, and force at least one on if both were explicitly turned off
		local DetectContraptions = Data.DetectContraptions
		local DetectMissiles     = Data.DetectMissiles

		if DetectContraptions == nil and DetectMissiles == nil then
			DetectContraptions = true
			DetectMissiles     = true
		end

		DetectContraptions = tobool(DetectContraptions)
		DetectMissiles     = tobool(DetectMissiles)

		if not DetectContraptions and not DetectMissiles then
			DetectContraptions = true
		end

		Data.DetectContraptions = DetectContraptions
		Data.DetectMissiles     = DetectMissiles

		do -- External verifications
			if Class.VerifyData then
				Class.VerifyData(Data, Class)
			end

			hook.Run("ACF_OnVerifyData", "acf_radar", Data, Class)
		end
	end

	local function UpdateRadar(Entity, Data, Class, Radar)
		Entity.ACF = Entity.ACF or {}

		Contraption.SetModel(Entity, Radar.Model)

		Entity:PhysicsInit(SOLID_VPHYSICS)
		Entity:SetMoveType(MOVETYPE_VPHYSICS)

		local OriginAttach = Entity:LookupAttachment(Radar.Origin)
		local AttachData = Entity:GetAttachment(OriginAttach)

		-- Storing all the relevant information on the entity for duping
		for _, V in ipairs(Entity.DataStore) do
			Entity[V] = Data[V]
		end

		Entity.Name         = Radar.Name
		Entity.ShortName    = Radar.ID
		Entity.EntType      = Class.Name
		Entity.ClassType    = Class.ID
		Entity.ClassData    = Class
		Entity.SoundPath    = Class.Sound or ACF.DefaultRadarSound
		Entity.DefaultSound = Entity.SoundPath
		Entity.ConeDegs     = Radar.ViewCone
		Entity.Range        = Radar.Range
		Entity.MinSizeAtRange = Radar.MinSizeAtRange
		Entity.SwitchDelay  = Radar.SwitchDelay
		Entity.ThinkTicks   = Radar.ThinkTicks -- Number of ticks between scans
		Entity.TickCounter  = Entity.TickCounter or 0
		Entity.GetDetected  = Radar.Detect or Class.Detect
		Entity.Origin       = AttachData and Entity:WorldToLocal(AttachData.Pos) or Vector()

		WireIO.SetupInputs(Entity, Inputs, Data, Class, Radar)
		WireIO.SetupOutputs(Entity, Outputs, Data, Class, Radar)

		Entity:SetNWString("WireName", "ACF " .. Entity.Name)

		WireLib.TriggerOutput(Entity, "Think Delay", Entity.ThinkTicks * engine.TickInterval())

		ACF.Activate(Entity, true)

		Contraption.SetMass(Entity, Radar.Mass)
	end

	function ACF.MakeRadar(Player, Pos, Angle, Data)
		VerifyData(Data)

		local Class = Classes.GetGroup(Sensors, Data.Radar)
		local RadarData = Class.Lookup[Data.Radar]
		local Limit = Class.LimitConVar.Name

		if not Player:CheckLimit(Limit) then return false end

		local CanSpawn = hook.Run("ACF_PreSpawnEntity", "acf_radar", Player, Data, Class, RadarData)
		if CanSpawn == false then return false end

		local Radar = ents.Create("acf_radar")

		if not IsValid(Radar) then return end

		Radar:SetAngles(Angle)
		Radar:SetPos(Pos)
		Radar:Spawn()

		Player:AddCleanup("acf_radar", Radar)
		Player:AddCount(Limit, Radar)

		Radar.Active      = false
		Radar.Scanning    = false
		Radar.TargetCount = 0
		Radar.Damage	  = 0
		Radar.Weapons     = {}
		Radar.Targets     = {}
		Radar.SyncSource  = nil
		Radar.DataStore   = Entities.GetArguments("acf_radar")
		Radar.TargetInfo  = {
			ID = {},
			Owner = {},
			Position = {},
			Velocity = {},
			Distance = {},
			Size = {},
			Type = {}
		}

		UpdateRadar(Radar, Data, Class, RadarData)

		if Class.OnSpawn then
			Class.OnSpawn(Radar, Data, Class, RadarData)
		end

		hook.Run("ACF_OnSpawnEntity", "acf_radar", Radar, Data, Class, RadarData)

		duplicator.ClearEntityModifier(Radar, "mass")

		TimerCreate("ACF Radar Clock " .. Radar:EntIndex(), 3, 0, function()
			if not IsValid(Radar) then return end

			CheckDistantLinks(Radar, "Weapons")
		end)

		-- Radars should be active by default
		Radar:TriggerInput("Active", 1)

		return Radar
	end

	Entities.Register("acf_missileradar", ACF.MakeRadar, "Radar", "DetectContraptions", "DetectMissiles") -- Backwards compatibility
	Entities.Register("acf_radar", ACF.MakeRadar, "Radar", "DetectContraptions", "DetectMissiles")

	-- Compatibility with ACE radar entities
	Entities.Register("ace_trackingradar", ACF.MakeRadar, "Radar", "DetectContraptions", "DetectMissiles")
	Entities.Register("ace_searchradar", ACF.MakeRadar, "Radar", "DetectContraptions", "DetectMissiles")

	ACF.RegisterLinkSource("acf_radar", "Weapons")

	------------------- Updating ---------------------

	function ENT:Update(Data)
		if self.Active then return false, "Turn off the radar before updating it!" end

		VerifyData(Data)

		local Class    = Classes.GetGroup(Sensors, Data.Radar)
		local Radar    = Class.Lookup[Data.Radar]
		local OldClass = self.ClassData

		if OldClass.OnLast then
			OldClass.OnLast(self, OldClass)
		end

		hook.Run("ACF_OnEntityLast", "acf_radar", self, OldClass)

		ACF.SaveEntity(self)

		UpdateRadar(self, Data, Class, Radar)

		ACF.RestoreEntity(self)

		if Class.OnUpdate then
			Class.OnUpdate(self, Data, Class, Radar)
		end

		hook.Run("ACF_OnUpdateEntity", "acf_radar", self, Data, Class, Radar)

		-- ThinkTicks/ConeDegs/Range may have changed; if linked to a synchronizer, its rate-group
		-- membership and cached geometry need to be refreshed to match
		if IsValid(self.SyncSource) then
			self.SyncSource:RefreshRateGroups()
		end

		return true, "Radar updated successfully!"
	end
end

--===============================================================================================--
-- Meta Funcs
--===============================================================================================--

function ENT:ACF_OnDamage(DmgResult, DmgInfo)
	local HitRes = Damage.doPropDamage(self, DmgResult, DmgInfo)

	self.Damage = (1 - math.Round(self.ACF.Health / self.ACF.MaxHealth, 2))

	return HitRes
end

function ENT:ACF_OnRepaired() -- OldArmor, OldHealth, Armor, Health
	self.Damage = (1 - math.Round(self.ACF.Health / self.ACF.MaxHealth, 2))
end

-- Called when this radar gets linked to a Radar Synchronizer: zeroes this radar's own outputs. The shared
-- ACF_OnTick scan hook already skips any radar with a valid SyncSource, so no scan cycle needs stopping
-- here; Active/Scanning stay meaningful for the Synchronizer to read.
function ENT:StopIndependentScanning()
	ResetOutputs(self)
end

-- Called when this radar gets unlinked from a Radar Synchronizer: resumes independent scanning exactly
-- as if freshly spawned, if it's still meant to be active.
function ENT:ResumeIndependentScanning()
	if self.Active and self.Scanning then
		SetScanning(self, true)
	end
end

-- Static base cost per radar item, independent of the current detection-type selection
local BaseCost = {
	SmallDIR   = 12.5,
	MediumDIR  = 25,
	LargeDIR   = 50,
	SmallOMNI  = 20,
	MediumOMNI = 40,
	LargeOMNI  = 80,
}

-- Discount applied when a radar can only detect one target type instead of both
local SingleTypeDiscount = 5

function ENT:GetCost()
	local selftbl = self:GetTable()
	local Cost = BaseCost[selftbl.ShortName] or 0

	if selftbl.DetectContraptions ~= selftbl.DetectMissiles then
		Cost = Cost - SingleTypeDiscount
	end

	return Cost
end

function ENT:Enable()
	if not ACF.CheckLegal(self) then return end

	if self.Inputs.Active.Path then
		self:TriggerInput("Active", self.Inputs.Active.Value)
	end

	self:UpdateOverlay()
end

function ENT:Disable()
	self:TriggerInput("Active", 0)
end

function ENT:ACF_UpdateOverlayState(State)
	if self.TargetCount > 0 then
		State:AddSuccess(self.TargetCount .. " target(s) detected")
	elseif not self.Active then
		State:AddWarning("Idle")
	else
		if self.Scanning then
			State:AddSuccess("Active")
		else
			State:AddWarning("Activating")
		end
	end

	State:AddKeyValue("Detection range", math.Round(self.Range / ACF.MeterToInch) .. " meters")
	State:AddNumber("Scanning angle", self.ConeDegs and math.Round(self.ConeDegs, 2) or 360)

	local Detects
	if self.DetectContraptions and self.DetectMissiles then
		Detects = "Contraptions, Missiles"
	elseif self.DetectContraptions then
		Detects = "Contraptions"
	else
		Detects = "Missiles"
	end
	State:AddKeyValue("Detects", Detects)
end

function ENT:OnRemove()
	local OldClass = self.ClassData

	if OldClass.OnLast then
		OldClass.OnLast(self, OldClass)
	end

	hook.Run("ACF_OnEntityLast", "acf_radar", self, OldClass)

	for Weapon in pairs(self.Weapons) do
		self:Unlink(Weapon)
	end

	if IsValid(self.SyncSource) then
		self.SyncSource:Unlink(self)
	end

	if Radars[self] then
		Radars[self] = nil
	end

	timer.Remove("ACF Radar Clock " .. self:EntIndex())

	WireLib.Remove(self)
end

do	-- Overlay/networking
	util.AddNetworkString("ACF.RequestRadarInfo")
	net.Receive("ACF.RequestRadarInfo", function(_, Ply)
		local Radar = net.ReadEntity()
		if not IsValid(Radar) then return end

		local RadarInfo	= {}
		RadarInfo.Spherical = (Radar.ConeDegs == nil) and true or false
		RadarInfo.Cone	= Radar.ConeDegs and math.Round(Radar.ConeDegs, 2) or 0
		RadarInfo.Range	= Radar.Range and math.Round(Radar.Range, 2) or 0
		RadarInfo.Origin	= Radar.Origin

		net.Start("ACF.RequestRadarInfo")
			net.WriteEntity(Radar)
			net.WriteString(util.TableToJSON(RadarInfo))
		net.Send(Ply)
	end)
end