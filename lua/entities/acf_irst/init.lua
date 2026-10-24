AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local ACF          = ACF
local Classes      = ACF.Classes
local Contraption  = ACF.Contraption
local Damage       = ACF.Damage
local RadarHelpers = ACF.RadarHelpers
local Forward      = Vector(1, 0, 0)
local Sensors      = {}

--===============================================================================================--
-- Local Funcs and Vars
--===============================================================================================--

local function ClampToGimbal(Dir, Gimbal)
	local Limit = math.cos(math.rad(Gimbal))

	if Dir.x >= Limit then return Dir end

	local Side = Vector(0, Dir.y, Dir.z)

	if Side:IsZero() then return Vector(Forward) end

	Side:Normalize()

	return Forward * Limit + Side * math.sin(math.rad(Gimbal))
end

-- Same convention as the optical guidance computer: positive pitch is up, positive yaw is right
local function GetLocalDirection(Pitch, Yaw, Gimbal)
	return ClampToGimbal(Angle(-Pitch, -Yaw, 0):Forward(), Gimbal)
end

-- Re-aimed every tick so it keeps tracking the position while the sensor moves
local function AimAtHitPos(Entity)
	local Dir = Entity:WorldToLocal(Entity.InputHitPos) - Entity.Origin

	if Dir:IsZero() then return end

	Dir:Normalize()

	Entity.TargetDir = ClampToGimbal(Dir, Entity.GimbalCone)
end

local function UpdateGimbal(Entity)
	local Current = Entity.LookDir
	local Target  = Entity.TargetDir
	local Delta   = math.deg(math.acos(math.Clamp(Current:Dot(Target), -1, 1)))

	if Delta < 0.001 then return end

	local Step = Entity.SlewRate * engine.TickInterval()

	if Delta <= Step then
		Entity.LookDir = Vector(Target)
	else
		Entity.LookDir = LerpVector(Step / Delta, Current, Target):GetNormalized()
	end

	local LookAng = Entity.LookDir:Angle()

	WireLib.TriggerOutput(Entity, "Current Pitch", -math.NormalizeAngle(LookAng.p))
	WireLib.TriggerOutput(Entity, "Current Yaw", -math.NormalizeAngle(LookAng.y))

	Entity:SetNW2Vector("ACF_IRSTDir", Entity.LookDir)
end

hook.Add("ACF_OnTick", "ACF IRST Scan", function()
	for Entity in pairs(Sensors) do
		if not IsValid(Entity) then continue end

		if not Entity.InputHitPos:IsZero() then AimAtHitPos(Entity) end

		UpdateGimbal(Entity)

		RadarHelpers.TickScan(Entity)
	end
end)

ACF.AddInputAction("acf_irst", "Active", function(Entity, Value)
	RadarHelpers.SetActive(Entity, tobool(Value))
end)

ACF.AddInputAction("acf_irst", "Pitch", function(Entity, Value)
	Entity.InputPitch = Value
	Entity.TargetDir  = GetLocalDirection(Value, Entity.InputYaw, Entity.GimbalCone)
end)

ACF.AddInputAction("acf_irst", "Yaw", function(Entity, Value)
	Entity.InputYaw  = Value
	Entity.TargetDir = GetLocalDirection(Entity.InputPitch, Value, Entity.GimbalCone)
end)

-- A non-zero HitPos overrides Pitch and Yaw, setting it back to zero hands control back to them
ACF.AddInputAction("acf_irst", "HitPos", function(Entity, Value)
	Entity.InputHitPos = Value

	if Value:IsZero() then
		Entity.TargetDir = GetLocalDirection(Entity.InputPitch, Entity.InputYaw, Entity.GimbalCone)
	end
end)

--===============================================================================================--
-- Spawning and Updating
--===============================================================================================--

local DefaultType = "ACF.Sensors.IRST.Infrared.Standard"

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
		self.TickCounter = 0
		self.InputPitch  = 0
		self.InputYaw    = 0
		self.InputHitPos = Vector()
		self.LookDir     = Vector(Forward)
		self.TargetDir   = Vector(Forward)
		self.Targets     = {}
		self.TargetInfo  = {
			ID = {},
			Owner = {},
			Position = {},
			Velocity = {},
			Distance = {},
			Size = {},
			Type = {}
		}

		Sensors[self] = true
	end

	function ENT:ACF_PostSpawn()
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

		self.Name               = Sensor.Name
		self.ShortName          = Sensor.ID
		self.EntType            = Group.Name
		self.ClassType          = Group.ID
		self.ClassData          = Group
		self.SoundPath          = Sensor.Sound or ACF.DefaultRadarSound
		self.DefaultSound       = self.SoundPath
		self.BaseCost           = Sensor.Cost
		self.ConeDegs           = Sensor.ViewCone
		self.GimbalCone         = Sensor.GimbalCone
		self.SlewRate           = Sensor.SlewRate
		self.SwitchDelay        = Sensor.SwitchDelay
		self.ThinkTicks         = Sensor.ThinkTicks
		self.Origin             = Sensor.Offset
		self.DetectContraptions = true
		self.DetectPlayers      = true
		self.TargetDir          = GetLocalDirection(self.InputPitch, self.InputYaw, self.GimbalCone)

		self:SetNW2Vector("ACF_IRSTOffset", self.Origin)
		self:SetNW2Float("ACF_IRSTCone", self.ConeDegs)
		self:SetNW2Float("ACF_IRSTGimbal", self.GimbalCone)
		self:SetNW2Vector("ACF_IRSTDir", self.LookDir)

		self:ACF_SetEntityName("ACF " .. self.Name)

		WireLib.TriggerOutput(self, "Think Delay", self.ThinkTicks * engine.TickInterval())

		-- ACF.Activate(self, true) is invoked automatically by ACF_UpdateEntityData after this.

		Contraption.SetMass(self, Sensor.Mass)

		if IsValid(self.SyncSource) then
			self.SyncSource:RefreshRateGroups()
		end
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

function ENT:GetCost()
	return self.BaseCost or 0
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

	State:AddKeyValue("View cone", self.ConeDegs * 2 .. " degrees")
	State:AddKeyValue("Gimbal range", self.GimbalCone * 2 .. " degrees")
	State:AddKeyValue("Detects", "Contraptions, Players")
end

do -- Sensor Synchronizer interface
	local TraceData = { start = true, endpos = true, mask = MASK_SOLID, filter = true }
	local MaxClipRetries = 8

	function ENT:GetScanShape()
		local Direction = Vector(self.LookDir)

		Direction:Rotate(self:GetAngles())

		return { Radar = self, Position = self:LocalToWorld(self.Origin), Direction = Direction, Degrees = self.ConeDegs }
	end

	-- Blocked by terrain, smoke and its own contraption, but not by anything else, so other contraptions'
	-- armor doesn't hide their baseplate while armoring the sensor itself from the front isn't possible
	function ENT:CheckTargetLOS(Origin, _, EntPos)
		if ACF.TraceSmoke(Origin, EntPos) then return false end

		local Own     = self:CFW_GetContraption()
		local Ignored = { [self] = true }

		TraceData.start  = Origin
		TraceData.endpos = EntPos
		TraceData.filter = function(Ent)
			if Ignored[Ent] then return false end
			if Ent:IsWorld() then return true end
			if Ent:IsPlayer() or Ent:IsNPC() or Ent:IsNextBot() then return false end
			if not IsValid(Ent:CPPIGetOwner()) then return true end -- Map entities count as terrain

			return Own ~= nil and Ent:CFW_GetContraption() == Own
		end

		for _ = 1, MaxClipRetries do
			local Result = util.TraceLine(TraceData)

			if not Result.Hit then return true end
			if not Result.HitNonWorld or not ACF.CheckClips(Result.Entity, Result.HitPos) then return false end

			Ignored[Result.Entity] = true -- Went through a clipped away part of the prop
		end

		return false
	end

	function ENT:StopIndependentScanning()
		RadarHelpers.ResetTargets(self)
	end

	function ENT:ResumeIndependentScanning()
		self.TickCounter = 0
	end
end

-- AutoRegister runs the ACF_OnEntityLast hook and WireLib.Remove around this
function ENT:OnRemove()
	local OldClass = self.ClassData

	if OldClass and OldClass.OnLast then
		OldClass.OnLast(self, OldClass)
	end

	if IsValid(self.SyncSource) then
		self.SyncSource:Unlink(self)
	end

	Sensors[self] = nil

	RadarHelpers.CancelSwitch(self)
end
