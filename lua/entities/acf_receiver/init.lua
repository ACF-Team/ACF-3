AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local ACF = ACF
local Classes		= ACF.Classes
local Contraption	= ACF.Contraption

--===============================================================================================--
-- Local Funcs and Vars
--===============================================================================================--

local Damage      = ACF.Damage
local Sounds      = ACF.Utilities.Sounds
local TimerExists = timer.Exists
local TimerCreate = timer.Create
local TimerRemove = timer.Remove

local function ResetOutputs(Entity)
	if not Entity.Detected then return end

	Entity.Detected = false

	WireLib.TriggerOutput(Entity, "Detected", 0)
	WireLib.TriggerOutput(Entity, "Angle", Angle())
	WireLib.TriggerOutput(Entity, "Direction", Vector())
end

local function CheckReceive(Entity)
	local IsDetected = false
	local Dir = Vector()
	local Ang = Angle()

	if not Entity.GetSources then return end
	if not Entity.CheckLOS then return end

	local Sources = Entity:GetSources()

	local Origin = Entity:LocalToWorld(Entity.Origin)

	for Ent in pairs(Sources) do
		local EntPos = Ent.ACF_Position or Ent:GetPos()
		local EntDamage = Entity.Damage
		local Spread = math.max(Entity.Divisor, 15) * 2 * EntDamage

		if Entity.CheckLOS(Entity, Ent, Origin, EntPos) and (math.Rand(0, 1) >= (EntDamage / 5)) then
			IsDetected = true

			local PreAng = Entity:WorldToLocalAngles((EntPos - Origin):Angle())
			local LocalAng = Angle(math.Round((PreAng.p + math.random(-Spread, Spread)) / Entity.Divisor), math.Round((PreAng.y + math.random(-Spread, Spread)) / Entity.Divisor), 0) * Entity.Divisor
			Ang = Entity:LocalToWorldAngles(LocalAng)
			Dir = Ang:Forward()

			break -- Stop at the first valid source
		end
	end

	if IsDetected ~= Entity.Detected then
		Entity.Detected = IsDetected
		WireLib.TriggerOutput(Entity, "Detected", IsDetected and 1 or 0)

		if IsDetected then
			Sounds.SendSound(Entity, Entity.SoundPath, 70, 100, 1)
		end

		Entity:UpdateOverlay()
	end

	WireLib.TriggerOutput(Entity, "Direction", Dir)
	WireLib.TriggerOutput(Entity, "Angle", Ang)
end

local function SetActive(Entity, Bool)
	ResetOutputs(Entity)

	if Bool then
		if not TimerExists(Entity.TimerID) then
			TimerCreate(Entity.TimerID, Entity.ThinkDelay, 0, function()

				if IsValid(Entity) then
					return CheckReceive(Entity)
				end

				TimerRemove(Entity.TimerID)
			end)
		end
	else
		TimerRemove(Entity.TimerID)
	end
end

--===============================================================================================--
-- Spawning and Updating
--===============================================================================================--

local DefaultType = "ACF.Sensors.Receiver.Warning.Laser"

do -- Spawning
	function ENT:ACF_PreSpawn(_, _, _, Data)
		self.ACF = {}

		local Sensor = Data and Data.Sensor
		local Class  = Classes.GetTypeByName(Sensor and Sensor.Type or DefaultType) or Classes.GetTypeByName(DefaultType)

		Contraption.SetModel(self, Class.Model)
	end

	function ENT:ACF_OnSpawn()
		self.Damage = 0
	end

	function ENT:ACF_PostSpawn()
		WireLib.TriggerOutput(self, "Entity", self)

		SetActive(self, true)
	end
end

do -- Updating
	function ENT:ACF_PostUpdateEntityData()
		local Sensor = self:ACF_GetUserVar("Sensor")
		local Class  = Sensor:GetType()
		local Group  = Classes.GetBaseClass(Class)
		local Tick   = engine.TickInterval()
		local Delay  = Sensor.ThinkDelay

		Contraption.SetModel(self, Sensor.Model)

		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)

		self.Name         = Sensor.Name
		self.ShortName    = Sensor.Name
		self.EntType      = Group.Name
		self.ClassType    = Group.ID
		self.SoundPath    = Sensor.Sound or ACF.DefaultRadarSound -- customizable sound?
		self.DefaultSound = self.SoundPath
		self.ThinkDelay   = math.Round(Delay / Tick) * Tick -- Uses a timer, so has to be tied to CurTime/tickrate
		self.GetSources   = Sensor.Detect
		self.CheckLOS     = Sensor.CheckLOS
		self.Origin       = Sensor.Offset
		self.TimerID      = "ACF Receiver Clock " .. self:EntIndex()
		self.Divisor      = Sensor.Divisor
		self.Cone         = Sensor.Cone

		self.ForcedHealth = Sensor.Health
		self.ForcedArmor  = Sensor.Armor

		self:SetNWString("WireName", "ACF " .. self.Name)

		-- ACF.Activate(self, true) is invoked automatically by ACF_UpdateEntityData after this.

		Contraption.SetMass(self, Sensor.Mass)
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

function ENT:ACF_Activate(Recalc)
	local PhysObj = self.ACF.PhysObj
	local Area    = PhysObj:GetSurfaceArea()
	local Armor   = self.ForcedArmor
	local Health  = self.ForcedHealth
	local Percent = 1

	if Recalc and self.ACF.Health and self.ACF.MaxHealth then
		Percent = self.ACF.Health / self.ACF.MaxHealth
	end

	self.ACF.Area      = Area
	self.ACF.Ductility = 0
	self.ACF.Health    = Health * Percent
	self.ACF.MaxHealth = Health
	self.ACF.Armour    = Armor * (0.5 + Percent * 0.5)
	self.ACF.MaxArmour = Armor * ACF.ArmorMod
	self.ACF.Type      = "Prop"
end

function ENT:Enable()
	if not ACF.CheckLegal(self) then return end

	SetActive(self, true)

	self:UpdateOverlay()
end

function ENT:Disable()
	SetActive(self, false)
end

function ENT:ACF_UpdateOverlayState(State)
	if self.Detected then
		State:AddSuccess("Detected")
	else
		State:AddWarning("Undetected")
	end
end

function ENT:OnRemove()
	TimerRemove(self.TimerID)
end
