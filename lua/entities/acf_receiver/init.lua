
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local ACF = ACF
local Contraption	= ACF.Contraption

--===============================================================================================--
-- Local Funcs and Vars
--===============================================================================================--

local Damage      = ACF.Damage
local Sounds      = ACF.Utilities.Sounds
local TimerExists = timer.Exists
local TimerCreate = timer.Create
local TimerRemove = timer.Remove
local hook        = hook

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

do -- Spawn and Update functions
	local Classes  = ACF.Classes
	local WireIO   = ACF.Utilities.WireIO
	local Entities = Classes.Entities
	local Sensors  = Classes.Sensors

	local Outputs = {
		"Detected (Returns 1 if something is detected.)",
		"Direction (The direction to a source.) [VECTOR]",
		"Angle (The direction to a source.) [ANGLE]",
		"Entity (The receiver itself.) [ENTITY]"
	}

	local function VerifyData(Data)
		if not Data.Receiver then
			Data.Receiver = Data.Sensor or Data.Id
		end

		local Class = Classes.GetGroup(Sensors, Data.Receiver)

		if not Class or Class.Entity ~= "acf_receiver" then
			Data.Receiver = "LAS-Receiver"

			Class = Classes.GetGroup(Sensors, "LAS-Receiver")
		end

		do -- External verifications
			if Class.VerifyData then
				Class.VerifyData(Data, Class)
			end

			hook.Run("ACF_OnVerifyData", "acf_receiver", Data, Class)
		end
	end

	local function UpdateReceiver(Entity, Data, Class, Receiver)
		local Tick  = engine.TickInterval()
		local Delay = Receiver.ThinkDelay

		Entity.ACF = Entity.ACF or {}

		Contraption.SetModel(Entity, Receiver.Model)

		Entity:PhysicsInit(SOLID_VPHYSICS)
		Entity:SetMoveType(MOVETYPE_VPHYSICS)

		-- Storing all the relevant information on the entity for duping
		for _, V in ipairs(Entity.DataStore) do
			Entity[V] = Data[V]
		end

		Entity.Name         = Receiver.Name
		Entity.ShortName    = Receiver.Name
		Entity.EntType      = Class.Name
		Entity.ClassType    = Class.ID
		Entity.ClassData    = Class
		Entity.SoundPath    = Class.Sound or ACF.DefaultRadarSound -- customizable sound?
		Entity.DefaultSound = Entity.SoundPath
		Entity.ThinkDelay   = math.Round(Delay / Tick) * Tick -- Uses a timer, so has to be tied to CurTime/tickrate
		Entity.GetSources	= Receiver.Detect or Class.Detect
		Entity.CheckLOS		= Receiver.CheckLOS
		Entity.Origin       = Receiver.Offset
		Entity.TimerID 		= "ACF Receiver Clock " .. Entity:EntIndex()
		Entity.Divisor		= Receiver.Divisor
		Entity.Cone			= Receiver.Cone

		Entity.ForcedHealth	= Receiver.Health
		Entity.ForcedArmor	= Receiver.Armor

		WireIO.SetupOutputs(Entity, Outputs, Data, Class, Receiver)

		Entity:SetNWString("WireName", "ACF " .. Entity.Name)

		WireLib.TriggerOutput(Entity, "Think Delay", Entity.ThinkDelay)

		ACF.Activate(Entity, true)

		Contraption.SetMass(Entity, Receiver.Mass)
	end

	function ACF.MakeReceiver(Player, Pos, Ang, Data)
		VerifyData(Data)

		local Class = Classes.GetGroup(Sensors, Data.Receiver)
		local ReceiverData = Class.Lookup[Data.Receiver]
		local Limit = Class.LimitConVar.Name

		if not Player:CheckLimit(Limit) then return false end

		local CanSpawn = hook.Run("ACF_PreSpawnEntity", "acf_receiver", Player, Data, Class, ReceiverData)
		if CanSpawn == false then return false end

		local Receiver = ents.Create("acf_receiver")

		if not IsValid(Receiver) then return end

		Receiver:SetAngles(Ang)
		Receiver:SetPos(Pos)
		Receiver:Spawn()

		Player:AddCleanup("acf_receiver", Receiver)
		Player:AddCount(Limit, Receiver)

		Receiver.DataStore   = Entities.GetArguments("acf_receiver")
		Receiver.Damage		 = 0

		UpdateReceiver(Receiver, Data, Class, ReceiverData)

		if Class.OnSpawn then
			Class.OnSpawn(Receiver, Data, Class, ReceiverData)
		end

		hook.Run("ACF_OnSpawnEntity", "acf_receiver", Receiver, Data, Class, ReceiverData)

		duplicator.ClearEntityModifier(Receiver, "mass")

		SetActive(Receiver, true)

		return Receiver
	end

	Entities.Register("acf_receiver", ACF.MakeReceiver, "Receiver")

	-- Compatibility with ACE receiver entities
	Entities.Register("ace_rwr_dir", ACF.MakeReceiver, "Receiver")
	Entities.Register("ace_rwr_sphere", ACF.MakeReceiver, "Receiver")

	------------------- Updating ---------------------

	function ENT:Update(Data)
		VerifyData(Data)

		local Class    = Classes.GetGroup(Sensors, Data.Receiver)
		local Receiver = Class.Lookup[Data.Receiver]
		local OldClass = self.ClassData

		if OldClass.OnLast then
			OldClass.OnLast(self, OldClass)
		end

		hook.Run("ACF_OnEntityLast", "acf_receiver", self, OldClass)

		ACF.SaveEntity(self)

		UpdateReceiver(self, Data, Class, Receiver)

		ACF.RestoreEntity(self)

		if Class.OnUpdate then
			Class.OnUpdate(self, Data, Class, Receiver)
		end

		hook.Run("ACF_OnUpdateEntity", "acf_receiver", self, Data, Class, Receiver)

		return true, "Receiver updated successfully!"
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
	local OldClass = self.ClassData

	if OldClass.OnLast then
		OldClass.OnLast(self, OldClass)
	end

	hook.Run("ACF_OnEntityLast", "acf_receiver", self, OldClass)

	TimerRemove(self.TimerID)

	WireLib.Remove(self)
end
