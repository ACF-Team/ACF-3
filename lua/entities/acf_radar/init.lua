AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local ACF = ACF
local Classes		= ACF.Classes
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
local RadarHelpers = ACF.RadarHelpers
local UnlinkSound = "physics/metal/metal_box_impact_bullet%s.wav"
local MaxDistance = ACF.LinkDistance * ACF.LinkDistance
local Indexes	  = {}
local Unused	  = {}
local IndexCount  = 0
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

		if RadarHelpers.CheckLOS(Origin, EntPos) and (math.Rand(0, 1) >= (EntDamage / 10)) then
			local EntDist = Origin:Distance(EntPos)
			local EntSize, EntType = RadarHelpers.GetEntSizeAndType(Ent)

			if EntSize < RadarHelpers.GetMinDetectableSize(Entity, EntDist) then continue end

			local EntSpread = VectorRand(-Spread, Spread)
			local EntVel = Ent.ACF_Velocity or Ent:GetVelocity()
			local Owner = RadarHelpers.GetEntityOwner(Entity.Owner, Ent)
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

-- Radars must be turned off before they can be reconfigured.
hook.Add("ACF_PreUpdateEntity", "ACF Radar Update Guard", function(Class, Entity)
	if Class ~= "acf_radar" then return end
	if Entity.Active then return false, "Turn off the radar before updating it!" end
end)

ACF.RegisterLinkSource("acf_radar", "Weapons")

--===============================================================================================--
-- Spawning and Updating
--===============================================================================================--

local DefaultType = "ACF.Sensors.Radar.Standard.SmallDirectional"

do -- Spawning
	function ENT:ACF_PreSpawn(_, _, _, Data)
		self.ACF = {}

		local Sensor = Data and Data.Sensor
		local Class  = Classes.GetTypeByName(Sensor and Sensor.Type or DefaultType) or Classes.GetTypeByName(DefaultType)

		Contraption.SetModel(self, Class.Model)
	end

	function ENT:ACF_OnSpawn()
		self.Active      = false
		self.Scanning    = false
		self.TargetCount = 0
		self.Damage      = 0
		self.Weapons     = {}
		self.Targets     = {}
		self.SyncSource  = nil
		self.TickCounter = 0
		self.TargetInfo  = {
			ID = {},
			Owner = {},
			Position = {},
			Velocity = {},
			Distance = {},
			Size = {},
			Type = {}
		}

		TimerCreate("ACF Radar Clock " .. self:EntIndex(), 3, 0, function()
			if not IsValid(self) then return end

			CheckDistantLinks(self, "Weapons")
		end)
	end

	function ENT:ACF_PostSpawn()
		-- Radars should be active by default
		self:TriggerInput("Active", 1)
	end
end

do -- Updating
	function ENT:ACF_PostUpdateEntityData()
		local Sensor = self:ACF_GetUserVar("Sensor")
		local Class  = Sensor:GetType()
		local Group  = Classes.GetBaseClass(Class)

		Contraption.SetModel(self, Sensor.Model)

		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)

		local OriginAttach = self:LookupAttachment(Sensor.Origin)
		local AttachData   = self:GetAttachment(OriginAttach)

		-- A radar must be able to detect at least one target type. If both were explicitly turned
		-- off, force contraption detection back on rather than leaving a radar that sees nothing.
		local DetectContraptions = tobool(self:ACF_GetUserVar("DetectContraptions"))
		local DetectMissiles     = tobool(self:ACF_GetUserVar("DetectMissiles"))

		if not DetectContraptions and not DetectMissiles then
			DetectContraptions = true
		end

		self.DetectContraptions = DetectContraptions
		self.DetectMissiles     = DetectMissiles

		self.Name           = Sensor.Name
		self.ShortName      = Sensor.ID
		self.EntType        = Group.Name
		self.ClassType      = Group.ID
		self.ClassData      = Group
		self.SoundPath      = Sensor.Sound or ACF.DefaultRadarSound
		self.DefaultSound   = self.SoundPath
		self.ConeDegs       = Sensor.ViewCone
		self.Range          = Sensor.Range
		self.MinSizeAtRange = Sensor.MinSizeAtRange
		self.BaseCost       = Sensor.Cost
		self.SwitchDelay    = Sensor.SwitchDelay
		self.ThinkTicks     = Sensor.ThinkTicks -- Number of ticks between scans
		self.TickCounter    = self.TickCounter or 0
		self.GetDetected    = Sensor.Detect or Group.Detect
		self.Origin         = AttachData and self:WorldToLocal(AttachData.Pos) or Vector()

		self:SetNWString("WireName", "ACF " .. self.Name)

		WireLib.TriggerOutput(self, "Think Delay", self.ThinkTicks * engine.TickInterval())

		-- ACF.Activate(self, true) is invoked automatically by ACF_UpdateEntityData after this.

		Contraption.SetMass(self, Sensor.Mass)
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

function ENT:GetCost()
	local selftbl = self:GetTable()
	local Cost = selftbl.BaseCost or 0

	if selftbl.DetectContraptions ~= selftbl.DetectMissiles then
		Cost = Cost - ACF.RadarSingleTypeDiscount
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

do -- Duplicator support
	function ENT:PreEntityCopy()
		if IsValid(self.SyncSource) then
			duplicator.StoreEntityModifier(self, "ACFRadarSync", { self.SyncSource:EntIndex() })
		end

		self.BaseClass.PreEntityCopy(self)
	end

	function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
		local EntMods = Ent.EntityMods

		if EntMods.ACFRadarSync then
			local _, EntIndex = next(EntMods.ACFRadarSync)
			local Sync = CreatedEntities[EntIndex]

			if IsValid(Sync) then Sync:Link(self) end

			EntMods.ACFRadarSync = nil
		end

		self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
	end
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