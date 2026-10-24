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

-- Linked turrets are slaved to this radar's locked target (see acf_controller/modules/radar.lua)
ACF.RegisterClassLink("acf_radar", "acf_turret", function(Radar, Turret)
	if Radar.Turrets[Turret] then return false, "This turret is already linked to this radar!" end
	if Turret.Radar == Radar then return false, "This turret is already linked to this radar!" end

	Radar.Turrets[Turret] = true
	Turret.Radar = Radar

	Radar:UpdateOverlay()
	Turret:UpdateOverlay()

	return true, "Turret linked successfully!"
end)

ACF.RegisterClassUnlink("acf_radar", "acf_turret", function(Radar, Turret)
	if Radar.Turrets[Turret] or Turret.Radar == Radar then
		Radar.Turrets[Turret] = nil
		Turret.Radar = nil

		Radar:UpdateOverlay()
		Turret:UpdateOverlay()

		return true, "Turret unlinked successfully!"
	end

	return false, "This turret is not linked to this radar."
end)

--===============================================================================================--
-- Local Funcs and Vars
--===============================================================================================--

local Radars	  = ACF.ActiveRadars
local Damage      = ACF.Damage
local RadarHelpers = ACF.RadarHelpers
local MaxDistance = ACF.LinkDistance * ACF.LinkDistance
local SwitchDelay = 2 -- Seconds between activation and the first scan
local hook        = hook

local function SetSequence(Entity, Active)
	local Sequence = Entity:LookupSequence("idle")

	Entity:ResetSequence(Sequence or 0)

	Entity.AutomaticFrameAdvance = false

	Entity:SetNW2Bool("ACF_RadarSpin", Active) -- Clients spin the dish bone themselves, see cl_init.lua
end

-- Synced radars are skipped, the Synchronizer scans for them (see lua/entities/acf_sensorsync/init.lua)
hook.Add("ACF_OnTick", "ACF Radar Scan", function()
	for Entity in pairs(Radars) do
		if IsValid(Entity) then RadarHelpers.TickScan(Entity) end
	end
end)

-- Watched by the link system, which unlinks and warns the owner once out of range
local function CheckLinkDistance(Radar, Target)
	if Radar:GetPos():DistToSqr(Target:GetPos()) <= MaxDistance then return true end

	return false, "The radar is too far from this entity."
end

ACF.RegisterClassLinkCheck("acf_radar", "acf_rack", CheckLinkDistance)
ACF.RegisterClassLinkCheck("acf_radar", "acf_turret", CheckLinkDistance)

ACF.AddInputAction("acf_radar", "Active", function(Entity, Value)
	RadarHelpers.SetActive(Entity, tobool(Value))
end)

--===============================================================================================--

-- Radars must be turned off before they can be reconfigured.
hook.Add("ACF_PreUpdateEntity", "ACF Radar Update Guard", function(Class, Entity)
	if Class ~= "acf_radar" then return end
	if Entity.Active then return false, "Turn off the radar before updating it!" end
end)

ACF.RegisterLinkSource("acf_radar", "Weapons")
ACF.RegisterLinkSource("acf_radar", "Turrets")

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
		self.SwitchDelay = SwitchDelay
		self.Weapons     = {}
		self.Turrets     = {}
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
	end

	-- Radars share the sensor limit with the other sensors, but also have their own
	-- (_acf_radar is counted by the entity registration, only the sensor count is added here)
	function ENT.ACF_CheckSpawnLimit(Player)
		return Player:CheckLimit("_acf_sensor") and Player:CheckLimit("_acf_radar")
	end

	function ENT:ACF_PostSpawn(Player)
		if IsValid(Player) then
			Player:AddCount("_acf_sensor", self)
		end

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
		self.ThinkTicks     = Sensor.ThinkTicks -- Number of ticks between scans
		self.TickCounter    = self.TickCounter or 0
		self.Origin         = AttachData and self:WorldToLocal(AttachData.Pos) or Vector()

		self:ACF_SetEntityName("ACF " .. self.Name)

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

	RadarHelpers.UpdateDamage(self)

	return HitRes
end

function ENT:ACF_OnRepaired() -- OldArmor, OldHealth, Armor, Health
	RadarHelpers.UpdateDamage(self)
end

-- Spins the dish and registers the radar as emitting, see the antiradiation guidance
function ENT:OnScanningChanged(Active)
	SetSequence(self, Active)

	Radars[self] = Active or nil
end

-- Called when this radar gets linked to a Sensor Synchronizer: zeroes this radar's own outputs. The shared
-- ACF_OnTick scan hook already skips any radar with a valid SyncSource, so no scan cycle needs stopping
-- here; Active/Scanning stay meaningful for the Synchronizer to read.
function ENT:StopIndependentScanning()
	RadarHelpers.ResetTargets(self)
end

-- Called when this radar gets unlinked from a Sensor Synchronizer, its own scan cycle restarts
function ENT:ResumeIndependentScanning()
	self.TickCounter = 0
end

-- Linked racks read the Synchronizer's combined targets while this radar is synced
function ENT:GetTargets()
	local Source = IsValid(self.SyncSource) and self.SyncSource or self

	return Source.Targets, Source.TargetCount
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
	RadarHelpers.AddScanState(self, State)

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

do -- Sensor Synchronizer interface
	function ENT:GetScanShape()
		local Origin = self:LocalToWorld(self.Origin)

		if self.ConeDegs then
			return { Radar = self, Position = Origin, Direction = self:GetForward(), Degrees = self.ConeDegs }
		end

		return { Radar = self, Position = Origin, Radius = self.Range }
	end

	function ENT:CheckTargetLOS(Origin, _, EntPos)
		return RadarHelpers.CheckLOS(Origin, EntPos)
	end
end

-- AutoRegister runs the ACF_OnEntityLast hook and WireLib.Remove around this
function ENT:OnRemove()
	local OldClass = self.ClassData -- Not set if the radar was removed before it finished spawning

	if OldClass and OldClass.OnLast then
		OldClass.OnLast(self, OldClass)
	end

	if self.Weapons then
		for Weapon in pairs(self.Weapons) do
			self:Unlink(Weapon)
		end
	end

	if self.Turrets then
		for Turret in pairs(self.Turrets) do
			self:Unlink(Turret)
		end
	end

	if IsValid(self.SyncSource) then
		self.SyncSource:Unlink(self)
	end

	if Radars[self] then
		Radars[self] = nil
	end

	RadarHelpers.CancelSwitch(self)
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