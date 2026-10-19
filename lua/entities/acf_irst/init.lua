AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local ACF          = ACF
local Classes      = ACF.Classes
local Contraption  = ACF.Contraption
local Damage       = ACF.Damage
local Sounds       = ACF.Utilities.Sounds
local RadarHelpers = ACF.RadarHelpers
local TimerExists  = timer.Exists
local TimerCreate  = timer.Create
local TimerRemove  = timer.Remove
local Forward      = Vector(1, 0, 0)
local Sensors      = {}
local Indexes      = {}
local Unused       = {}
local IndexCount   = 0

--===============================================================================================--
-- Local Funcs and Vars
--===============================================================================================--

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

	Entity:CallOnRemove("IRST Index", function()
		Indexes[Entity] = nil
		Unused[EntID] = true
	end)

	return EntID
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

local function ScanForEntities(Entity)
	ClearTargets(Entity)

	if Entity.ACF.Health <= 0 then return end -- Destroyed

	local Shape      = Entity:GetScanShape()
	local Origin     = Shape.Position
	local Own        = Entity:CFW_GetContraption()
	local TargetInfo = Entity.TargetInfo
	local Targets    = Entity.Targets
	local EntDamage  = Entity.Damage
	local Spread     = ACF.MaxDamageInaccuracy * EntDamage
	local Closest    = math.huge
	local Count      = 0
	local Detected   = ACF.GetEntitiesInCone(Origin, Shape.Direction, Shape.Degrees, Own)

	for Ply in pairs(RadarHelpers.GetPlayersInShapes({ Shape }, Own)) do
		Detected[Ply] = true
	end

	for Ent in pairs(Detected) do
		local EntPos = RadarHelpers.GetTargetPos(Ent)

		if not Entity:CheckTargetLOS(Origin, Ent, EntPos) then continue end
		if math.Rand(0, 1) < (EntDamage / 10) then continue end

		local EntDist          = Origin:Distance(EntPos)
		local EntSize, EntType = RadarHelpers.GetEntSizeAndType(Ent)
		local EntSpread        = VectorRand(-Spread, Spread)
		local EntVel           = (Ent.ACF_Velocity or Ent:GetVelocity()) + EntSpread
		local Owner            = RadarHelpers.GetEntityOwner(Entity.Owner, Ent)
		local Index            = GetEntityIndex(Ent)

		EntPos = EntPos + EntSpread
		Count  = Count + 1

		Targets[Ent] = {
			Index    = Index,
			Owner    = Owner,
			Position = EntPos,
			Velocity = EntVel,
			Distance = EntDist,
			Spread   = EntSpread,
			Type     = EntType,
		}

		TargetInfo.ID[Count]       = Index
		TargetInfo.Owner[Count]    = Owner
		TargetInfo.Position[Count] = EntPos
		TargetInfo.Velocity[Count] = EntVel
		TargetInfo.Distance[Count] = EntDist
		TargetInfo.Size[Count]     = EntSize
		TargetInfo.Type[Count]     = EntType

		if EntDist < Closest then
			Closest = EntDist
		end
	end

	WireLib.TriggerOutput(Entity, "ClosestDistance", Closest < math.huge and Closest or 0)
	WireLib.TriggerOutput(Entity, "IDs", TargetInfo.ID)
	WireLib.TriggerOutput(Entity, "Owner", TargetInfo.Owner)
	WireLib.TriggerOutput(Entity, "Position", TargetInfo.Position)
	WireLib.TriggerOutput(Entity, "Velocity", TargetInfo.Velocity)
	WireLib.TriggerOutput(Entity, "Distance", TargetInfo.Distance)
	WireLib.TriggerOutput(Entity, "Detected", Count)
	WireLib.TriggerOutput(Entity, "Size", TargetInfo.Size)
	WireLib.TriggerOutput(Entity, "Type", TargetInfo.Type)

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
	Entity.Scanning    = Active
	Entity.TickCounter = 0

	ResetOutputs(Entity)

	WireLib.TriggerOutput(Entity, "Scanning", Active and 1 or 0)

	if IsValid(Entity.SyncSource) then
		Entity.SyncSource:RefreshRateGroups()
	end

	Entity:UpdateOverlay()
end

local function SetActive(Entity, Active)
	if Entity.Active == Active then return end

	local TimerName = "ACF IRST Switch " .. Entity:EntIndex()

	Entity.Active = Active

	if TimerExists(TimerName) then
		TimerRemove(TimerName)
	end

	if not Active then return SetScanning(Entity, false) end

	Entity:UpdateOverlay()

	TimerCreate(TimerName, Entity.SwitchDelay, 1, function()
		if IsValid(Entity) then
			SetScanning(Entity, true)
		end
	end)
end

hook.Add("ACF_OnTick", "ACF IRST Scan", function()
	for Entity in pairs(Sensors) do
		if not IsValid(Entity) then continue end

		if not Entity.InputHitPos:IsZero() then AimAtHitPos(Entity) end

		UpdateGimbal(Entity)

		if not Entity.Scanning or IsValid(Entity.SyncSource) then continue end

		Entity.TickCounter = Entity.TickCounter + 1

		if Entity.TickCounter >= Entity.ThinkTicks then
			Entity.TickCounter = 0

			ScanForEntities(Entity)
		end
	end
end)

ACF.AddInputAction("acf_irst", "Active", function(Entity, Value)
	SetActive(Entity, tobool(Value))
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

	self.Damage = 1 - math.Round(self.ACF.Health / self.ACF.MaxHealth, 2)

	return HitRes
end

function ENT:ACF_OnRepaired() -- OldArmor, OldHealth, Armor, Health
	self.Damage = 1 - math.Round(self.ACF.Health / self.ACF.MaxHealth, 2)
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
	if self.TargetCount > 0 then
		State:AddSuccess(self.TargetCount .. " target(s) detected")
	elseif not self.Active then
		State:AddWarning("Idle")
	elseif self.Scanning then
		State:AddSuccess("Active")
	else
		State:AddWarning("Activating")
	end

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
		ResetOutputs(self)
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

	TimerRemove("ACF IRST Switch " .. self:EntIndex())
end
