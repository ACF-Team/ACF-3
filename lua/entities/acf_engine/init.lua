AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

--===============================================================================================--
-- Engine class setup
--===============================================================================================--
do
	ACF.RegisterClassLink("acf_engine", "acf_fueltank", function(Engine, Target)
		if Engine.FuelTanks[Target] then return false, "This engine is already linked to this fuel tank!" end
		if Target.Engines[Engine] then return false, "This engine is already linked to this fuel tank!" end
		if Engine.FuelType ~= "Multifuel" and Engine.FuelType ~= Target.FuelType then return false, "Cannot link because fuel type is incompatible." end
		if Target.NoLinks then return false, "This fuel tank doesn't allow linking." end

		Engine.FuelTanks[Target] = true
		Target.Engines[Engine] = true

		Engine:UpdateOverlay()
		Target:UpdateOverlay()

		return true, "Engine linked successfully!"
	end)

	ACF.RegisterClassUnlink("acf_engine", "acf_fueltank", function(Engine, Target)
		if Engine.FuelTanks[Target] or Target.Engines[Engine] then
			Engine.FuelTanks[Target] = nil
			Target.Engines[Engine]	 = nil

			Engine:UpdateOverlay()
			Target:UpdateOverlay()

			return true, "Engine unlinked successfully!"
		end

		return false, "This engine is not linked to this fuel tank."
	end)

	ACF.RegisterClassLink("acf_engine", "acf_gearbox", function(Engine, Target)
		if Engine.Gearboxes[Target] then return false, "This engine is already linked to this gearbox." end

		-- make sure the angle is not excessive
		local InPos = Target:LocalToWorld(Target.In)
		local OutPos = Engine:LocalToWorld(Engine.Out)
		local Direction

		if Engine.IsTrans then
			Direction = -Engine:GetRight()
		else
			Direction = Engine:GetForward()
		end

		if (OutPos - InPos):GetNormalized():Dot(Direction) < 0.7 then
			return false, "Cannot link due to excessive driveshaft angle!"
		end

		local Rope

		if tobool(Engine.Owner:GetInfoNum("ACF_MobilityRopeLinks", 1)) then
			Rope = constraint.CreateKeyframeRope(OutPos, 1, "cable/cable2", nil, Engine, Engine.Out, 0, Target, Target.In, 0)
		end

		local Link = {
			Rope = Rope,
			RopeLen = (OutPos - InPos):Length(),
			ReqTq = 0
		}

		Engine.Gearboxes[Target] = Link
		Target.Engines[Engine]	 = true

		Engine:UpdateOverlay()
		Target:UpdateOverlay()

		return true, "Engine linked successfully!"
	end)

	ACF.RegisterClassUnlink("acf_engine", "acf_gearbox", function(Engine, Target)
		if not Engine.Gearboxes[Target] then
			return false, "This engine is not linked to this gearbox."
		end

		local Rope = Engine.Gearboxes[Target].Rope

		if IsValid(Rope) then Rope:Remove() end

		Engine.Gearboxes[Target] = nil
		Target.Engines[Engine]	 = nil

		Engine:UpdateOverlay()
		Target:UpdateOverlay()

		return true, "Engine unlinked successfully!"
	end)
end
--===============================================================================================--
-- Local Funcs and Vars
--===============================================================================================--

local CheckLegal  = ACF_CheckLegal
local ClassLink   = ACF.GetClassLink
local ClassUnlink = ACF.GetClassUnlink
local UnlinkSound = "physics/metal/metal_box_impact_bullet%s.wav"
local Round       = math.Round
local max         = math.max
local TimerCreate = timer.Create
local TimerExists = timer.Exists
local TimerSimple = timer.Simple
local TimerRemove = timer.Remove
local Gamemode    = GetConVar("acf_gamemode")

local function GetEfficiency(Entity)
	local CompetitiveMult = Gamemode:GetInt() == 2 and ACF.CompFuelRate or 1

	return ACF.Efficiency[Entity.EngineType] * CompetitiveMult
end

local function UpdateEngineData(Entity, Id, EngineData)
	Entity.Id 				= Id
	Entity.Name 			= EngineData.name
	Entity.ShortName 		= Id
	Entity.EntType 			= EngineData.category
	Entity.SoundPath		= EngineData.sound
	Entity.SoundPitch 		= EngineData.pitch or 1
	Entity.Mass 			= EngineData.weight
	Entity.PeakTorque 		= EngineData.torque
	Entity.PeakTorqueHeld 	= EngineData.torque
	Entity.IdleRPM 			= EngineData.idlerpm
	Entity.PeakMinRPM 		= EngineData.peakminrpm
	Entity.PeakMaxRPM 		= EngineData.peakmaxrpm
	Entity.LimitRPM 		= EngineData.limitrpm
	Entity.Inertia 			= EngineData.flywheelmass * 3.1416 ^ 2
	Entity.IsElectric 		= EngineData.iselec
	Entity.FlywheelOverride = EngineData.flywheeloverride
	Entity.IsTrans 			= EngineData.istrans -- driveshaft outputs to the side
	Entity.FuelType 		= EngineData.fuel or "Petrol"
	Entity.EngineType 		= EngineData.enginetype or "GenericPetrol"
	Entity.TorqueScale 		= ACF.TorqueScale[Entity.EngineType]

	--calculate boosted peak kw
	if Entity.EngineType == "Turbine" or Entity.EngineType == "Electric" then
		Entity.peakkw = (Entity.PeakTorque * (1 + Entity.PeakMaxRPM / Entity.LimitRPM)) * Entity.LimitRPM / (4 * 9548.8) --adjust torque to 1 rpm maximum, assuming a linear decrease from a max @ 1 rpm to min @ limiter
		Entity.PeakKwRPM = math.floor(Entity.LimitRPM / 2)
	else
		Entity.peakkw = Entity.PeakTorque * Entity.PeakMaxRPM / 9548.8
		Entity.PeakKwRPM = Entity.PeakMaxRPM
	end

	--calculate base fuel usage
	if Entity.EngineType == "Electric" then
		Entity.FuelUse = ACF.FuelRate / (GetEfficiency(Entity) * 3600) --elecs use current power output, not max
	else
		Entity.FuelUse = ACF.FuelRate * GetEfficiency(Entity) * Entity.peakkw / 3600
	end

	local PhysObj = Entity:GetPhysicsObject()

	if IsValid(PhysObj) then
		PhysObj:SetMass(Entity.Mass)
	end

	Entity:SetNWString("WireName", "ACF " .. Entity.Name)

	Entity:UpdateOverlay(true)
end

local function GetPitchVolume(Engine)
	local RPM = Engine.FlyRPM
	local Pitch = math.Clamp(20 + (RPM * Engine.SoundPitch) * 0.02, 1, 255)
	local Volume = 0.25 + (0.1 + 0.9 * ((RPM / Engine.LimitRPM) ^ 1.5)) * Engine.Throttle * 0.666

	return Pitch, Volume
end

local function GetNextFuelTank(Engine)
	if not next(Engine.FuelTanks) then return end

	local Current = Engine.FuelTank
	local NextKey = (IsValid(Current) and Engine.FuelTanks[Current]) and Current or nil
	local Select = next(Engine.FuelTanks, NextKey) or next(Engine.FuelTanks)
	local Start = Select

	repeat
		if Select.Active and Select.Fuel > 0 then
			return Select
		end

		Select = next(Engine.FuelTanks, Select) or next(Engine.FuelTanks)
	until Select == Start

	return (Select.Active and Select.Fuel > 0) and Select or nil
end

local function CheckDistantFuelTanks(Engine)
	local EnginePos = Engine:GetPos()

	for Tank in pairs(Engine.FuelTanks) do
		if EnginePos:DistToSqr(Tank:GetPos()) > 262144 then
			Engine:EmitSound(UnlinkSound:format(math.random(1, 3)), 500, 100)

			Engine:Unlink(Tank)
		end
	end
end

local function CheckGearboxes(Engine)
	for Ent, Link in pairs(Engine.Gearboxes) do
		local OutPos = Engine:LocalToWorld(Engine.Out)
		local InPos = Ent:LocalToWorld(Ent.In)

		-- make sure it is not stretched too far
		if OutPos:Distance(InPos) > Link.RopeLen * 1.5 then
			Engine:Unlink(Ent)
			continue
		end

		-- make sure the angle is not excessive
		local Direction = Engine.IsTrans and -Engine:GetRight() or Engine:GetForward()

		if (OutPos - InPos):GetNormalized():Dot(Direction) < 0.7 then
			Engine:Unlink(Ent)
		end
	end
end

local function SetActive(Entity, Value)
	if Entity.Active == tobool(Value) then return end

	if not Entity.Active then -- Was off, turn on
		Entity.Active = true

		Entity:CalcMassRatio()

		Entity.LastThink = ACF.CurTime
		Entity.Torque = Entity.PeakTorque
		Entity.FlyRPM = Entity.IdleRPM * 1.5

		local Pitch, Volume = GetPitchVolume(Entity)

		if Entity.SoundPath ~= "" then
			Entity.Sound = CreateSound(Entity, Entity.SoundPath)
			Entity.Sound:PlayEx(Volume, Pitch)
		end

		TimerSimple(engine.TickInterval(), function()
			if not IsValid(Entity) then return end

			Entity:CalcRPM()
		end)

		TimerCreate("ACF Engine Clock " .. Entity:EntIndex(), 3, 0, function()
			if not IsValid(Entity) then return end

			CheckGearboxes(Entity)
			CheckDistantFuelTanks(Entity)

			Entity:CalcMassRatio()
		end)
	else
		Entity.Active = false
		Entity.FlyRPM = 0
		Entity.Torque = 0

		if Entity.Sound then
			Entity.Sound:Stop()
			Entity.Sound = nil
		end

		TimerRemove("ACF Engine Clock " .. Entity:EntIndex())
	end

	Entity:UpdateOverlay()
	Entity:UpdateOutputs()
end

local Inputs = {
	Throttle = function(Entity, Value)
		Entity.Throttle = math.Clamp(Value, 0, 100) / 100
	end,
	Active = function(Entity, Value)
		SetActive(Entity, tobool(Value))
	end
}

--===============================================================================================--

function MakeACF_Engine(Owner, Pos, Angle, Id)
	if not Owner:CheckLimit("_acf_misc") then return end

	local EngineData = ACF.Weapons.Mobility[Id]

	if not EngineData then return end

	local Engine = ents.Create("acf_engine")

	if not IsValid(Engine) then return end

	Engine:SetModel(EngineData.model)
	Engine:SetPlayer(Owner)
	Engine:SetAngles(Angle)
	Engine:SetPos(Pos)
	Engine:Spawn()

	Engine:PhysicsInit(SOLID_VPHYSICS)
	Engine:SetMoveType(MOVETYPE_VPHYSICS)

	Owner:AddCount("_acf_misc", Engine)
	Owner:AddCleanup("acfmenu", Engine)

	UpdateEngineData(Engine, Id, EngineData)

	Engine.Owner = Owner
	Engine.Model = EngineData.model
	Engine.CanUpdate = true
	Engine.Active = false
	Engine.Gearboxes = {}
	Engine.FuelTanks = {}
	Engine.LastThink = 0
	Engine.MassRatio = 1
	Engine.FuelUsage = 0
	Engine.Throttle = 0
	Engine.FlyRPM = 0
	Engine.Out = Engine:WorldToLocal(Engine:GetAttachment(Engine:LookupAttachment("driveshaft")).Pos)

	Engine.Inputs = WireLib.CreateInputs(Engine, { "Active", "Throttle" })
	Engine.Outputs = WireLib.CreateOutputs(Engine, { "RPM", "Torque", "Power", "Fuel Use", "Entity [ENTITY]", "Mass", "Physical Mass" })

	WireLib.TriggerOutput(Engine, "Entity", Engine)

	ACF_Activate(Engine)

	Engine.ACF.LegalMass = Engine.Mass
	Engine.ACF.Model     = Engine.Model

	CheckLegal(Engine)

	return Engine
end

list.Set("ACFCvars", "acf_engine", { "id" })
duplicator.RegisterEntityClass("acf_engine", MakeACF_Engine, "Pos", "Angle", "Id")
ACF.RegisterLinkSource("acf_engine", "FuelTanks")
ACF.RegisterLinkSource("acf_engine", "Gearboxes")

--===============================================================================================--
-- Meta Funcs
--===============================================================================================--

function ENT:Enable()
	local Active

	if self.Inputs.Active.Path then
		Active = tobool(self.Inputs.Active.Value)
	else
		Active = true
	end

	SetActive(self, Active)

	self:UpdateOverlay()
end

function ENT:Disable()
	SetActive(self, false) -- Turn off the engine

	self:UpdateOverlay()
end

function ENT:Update(ArgsTable)
	if self.Active then return false, "Turn off the engine before updating it!" end
	if ArgsTable[1] ~= self.Owner then return false, "You don't own that engine!" end

	local Id = ArgsTable[4] -- Argtable[4] is the engine ID
	local EngineData = ACF.Weapons.Mobility[Id]

	if not EngineData then return false, "Invalid engine type!" end
	if EngineData.model ~= self.Model then return false, "The new engine must have the same model!" end

	local Feedback = ""

	if EngineData.fuel ~= self.FuelType then
		Feedback = " Fuel type changed, fuel tanks unlinked."

		for Tank in pairs(self.FuelTanks) do
			self:Unlink(Tank)
		end
	end

	UpdateEngineData(self, Id, EngineData)

	ACF_Activate(self, true)

	self.ACF.LegalMass = self.Mass

	return true, "Engine updated successfully!" .. Feedback
end

function ENT:UpdateOutputs()
	if not IsValid(self) then return end

	local Power = self.Torque * self.FlyRPM / 9548.8

	WireLib.TriggerOutput(self, "Fuel Use", self.FuelUsage)
	WireLib.TriggerOutput(self, "Torque", math.floor(self.Torque))
	WireLib.TriggerOutput(self, "Power", math.floor(Power))
	WireLib.TriggerOutput(self, "RPM", math.floor(self.FlyRPM))
end

local function Overlay(Ent)
	if Ent.Disabled then
		Ent:SetOverlayText("Disabled: " .. Ent.DisableReason .. "\n" .. Ent.DisableDescription)
	else
		local PowerbandMin = Ent.IsElectric and Ent.IdleRPM or Ent.PeakMinRPM
		local PowerbandMax = Ent.IsElectric and math.floor(Ent.LimitRPM / 2) or Ent.PeakMaxRPM
		local Text

		if Ent.DisableReason then
			Text = "Disabled: " .. Ent.DisableReason
		else
			Text = Ent.Active and "Active" or "Idle"
		end

		Text = Text .. "\n\n" .. Ent.Name .. "\n" ..
			"Power: " .. Round(Ent.peakkw) .. " kW / " .. Round(Ent.peakkw * 1.34) .. " hp\n" ..
			"Torque: " .. Round(Ent.PeakTorque) .. " Nm / " .. Round(Ent.PeakTorque * 0.73) .. " ft-lb\n" ..
			"Powerband: " .. PowerbandMin .. " - " .. PowerbandMax .. " RPM\n" ..
			"Redline: " .. Ent.LimitRPM .. " RPM"

		Ent:SetOverlayText(Text)
	end
end

function ENT:UpdateOverlay(Instant)
	if Instant then
		Overlay(self)
		return
	end

	if not TimerExists("ACF Overlay Buffer" .. self:EntIndex()) then
		TimerCreate("ACF Overlay Buffer" .. self:EntIndex(), 1, 1, function()
			if IsValid(self) then
				Overlay(self)
			end
		end)
	end
end

function ENT:TriggerInput(Input, Value)
	if self.Disabled then return end

	if Inputs[Input] then
		Inputs[Input](self, Value)
	end
end

function ENT:ACF_Activate()
	--Density of steel = 7.8g cm3 so 7.8kg for a 1mx1m plate 1m thick
	local PhysObj = self.ACF.PhysObj
	local Count

	if PhysObj:GetMesh() then
		Count = #PhysObj:GetMesh()
	end

	if IsValid(PhysObj) and Count and Count > 100 then
		if not self.ACF.Area then
			self.ACF.Area = (PhysObj:GetSurfaceArea() * 6.45) * 0.52505066107
		end
	else
		local Size = self:OBBMaxs() - self:OBBMins()

		if not self.ACF.Area then
			self.ACF.Area = ((Size.x * Size.y) + (Size.x * Size.z) + (Size.y * Size.z)) * 6.45
		end
	end

	self.ACF.Ductility = self.ACF.Ductility or 0

	local Area = self.ACF.Area
	local Armour = PhysObj:GetMass() * 1000 / Area / 0.78
	local Health = Area / ACF.Threshold
	local Percent = 1

	if Recalc and self.ACF.Health and self.ACF.MaxHealth then
		Percent = self.ACF.Health / self.ACF.MaxHealth
	end

	self.ACF.Health = Health * Percent * ACF.EngineHPMult[self.EngineType]
	self.ACF.MaxHealth = Health * ACF.EngineHPMult[self.EngineType]
	self.ACF.Armour = Armour * (0.5 + Percent / 2)
	self.ACF.MaxArmour = Armour * ACF.ArmorMod
	self.ACF.Type = nil
	self.ACF.Mass = PhysObj:GetMass()
	self.ACF.Type = "Prop"
end

--This function needs to return HitRes
function ENT:ACF_OnDamage(Entity, Energy, FrArea, Angle, Inflictor, _, Type)
	local Mul = Type == "HEAT" and ACF.HEATMulEngine or 1 --Heat penetrators deal bonus damage to engines
	local Res = ACF.PropDamage(Entity, Energy, FrArea * Mul, Angle, Inflictor)

	--adjusting performance based on damage
	local TorqueMult = math.Clamp(((1 - self.TorqueScale) / 0.5) * ((self.ACF.Health / self.ACF.MaxHealth) - 1) + 1, self.TorqueScale, 1)
	self.PeakTorque = self.PeakTorqueHeld * TorqueMult

	return Res
end

-- specialized calcmassratio for engines
function ENT:CalcMassRatio()
	local PhysMass 	= 0
	local TotalMass = 0
	local Physical, Parented = ACF_GetEnts(self)

	for K in pairs(Physical) do
		local Phys = K:GetPhysicsObject() -- Should always exist, but just in case

		if IsValid(Phys) then
			local Mass = Phys:GetMass()

			TotalMass = TotalMass + Mass
			PhysMass  = PhysMass + Mass
		end
	end

	for K in pairs(Parented) do
		if not Physical[K] then
			local Phys = K:GetPhysicsObject()

			if IsValid(Phys) then
				TotalMass = TotalMass + Phys:GetMass()
			end
		end
	end

	self.MassRatio = PhysMass / TotalMass

	WireLib.TriggerOutput(self, "Mass", Round(TotalMass, 2))
	WireLib.TriggerOutput(self, "Physical Mass", Round(PhysMass, 2))
end

function ENT:GetConsumption(Throttle, RPM)
	if not IsValid(self.FuelTank) then return 0 end

	local Consumption

	if self.FuelType == "Electric" then
		Consumption = self.Torque * RPM * self.FuelUse / 9548.8
	else
		local Load = 0.3 + Throttle * 0.7

		Consumption = Load * self.FuelUse * (RPM / self.PeakKwRPM) / self.FuelTank.FuelDensity
	end

	return Consumption
end

function ENT:CalcRPM()
	if not self.Active then return end

	local DeltaTime = ACF.CurTime - self.LastThink
	local FuelTank 	= GetNextFuelTank(self)

	--calculate fuel usage
	if IsValid(FuelTank) then
		self.FuelTank = FuelTank

		local Consumption = self:GetConsumption(self.Throttle, self.FlyRPM) * DeltaTime

		self.FuelUsage = 60 * Consumption / DeltaTime

		FuelTank.Fuel = max(FuelTank.Fuel - Consumption, 0)
		FuelTank:UpdateMass()
		FuelTank:UpdateOverlay()
		FuelTank:UpdateOutputs()
	elseif Gamemode:GetInt() ~= 0 then -- Sandbox gamemode servers will require no fuel
		SetActive(self, false)

		self.FuelUsage = 0

		return 0
	end

	-- Calculate the current torque from flywheel RPM
	self.Torque = self.Throttle * max(self.PeakTorque * math.min(self.FlyRPM / self.PeakMinRPM, (self.LimitRPM - self.FlyRPM) / (self.LimitRPM - self.PeakMaxRPM), 1), 0)

	local PeakRPM = self.IsElectric and self.FlywheelOverride or self.PeakMaxRPM
	local Drag = self.PeakTorque * (max(self.FlyRPM - self.IdleRPM, 0) / PeakRPM) * (1 - self.Throttle) / self.Inertia

	-- Let's accelerate the flywheel based on that torque
	self.FlyRPM = max(self.FlyRPM + self.Torque / self.Inertia - Drag, 1)
	-- The gearboxes don't think on their own, it's the engine that calls them, to ensure consistent execution order
	local Boxes = 0
	local TotalReqTq = 0

	-- Get the requirements for torque for the gearboxes (Max clutch rating minus any wheels currently spinning faster than the Flywheel)
	for Ent, Link in pairs(self.Gearboxes) do
		if not Ent.Disabled then
			Boxes = Boxes + 1
			Link.ReqTq = Ent:Calc(self.FlyRPM, self.Inertia)
			TotalReqTq = TotalReqTq + Link.ReqTq
		end
	end

	-- This is the presently available torque from the engine
	local TorqueDiff = max(self.FlyRPM - self.IdleRPM, 0) * self.Inertia
	-- Calculate the ratio of total requested torque versus what's available
	local AvailRatio = math.min(TorqueDiff / TotalReqTq / Boxes, 1)

	-- Split the torque fairly between the gearboxes who need it
	for Ent, Link in pairs(self.Gearboxes) do
		if not Ent.Disabled then
			Ent:Act(Link.ReqTq * AvailRatio * self.MassRatio, DeltaTime, self.MassRatio)
		end
	end

	self.FlyRPM = self.FlyRPM - math.min(TorqueDiff, TotalReqTq) / self.Inertia
	self.LastThink = ACF.CurTime

	if self.Sound then
		local Pitch, Volume = GetPitchVolume(self)

		self.Sound:ChangePitch(Pitch, 0)
		self.Sound:ChangeVolume(Volume, 0)
	end

	self:UpdateOutputs()

	TimerSimple(engine.TickInterval(), function()
		if not IsValid(self) then return end

		self:CalcRPM()
	end)
end

function ENT:Link(Target)
	if not IsValid(Target) then return false, "Attempted to link an invalid entity." end
	if self == Target then return false, "Can't link an engine to itself." end

	local Function = ClassLink(self:GetClass(), Target:GetClass())

	if Function then
		return Function(self, Target)
	end

	return false, "Engines can't be linked to '" .. Target:GetClass() .. "'."
end

function ENT:Unlink(Target)
	if not IsValid(Target) then return false, "Attempted to unlink an invalid entity." end
	if self == Target then return false, "Can't unlink an engine from itself." end

	local Function = ClassUnlink(self:GetClass(), Target:GetClass())

	if Function then
		return Function(self, Target)
	end

	return false, "Engines can't be unlinked from '" .. Target:GetClass() .. "'."
end

function ENT:PreEntityCopy()
	if next(self.Gearboxes) then
		local Gearboxes = {}

		for Gearbox in pairs(self.Gearboxes) do
			Gearboxes[#Gearboxes + 1] = Gearbox:EntIndex()
		end

		duplicator.StoreEntityModifier(self, "ACFGearboxes", Gearboxes)
	end

	if next(self.FuelTanks) then
		local Tanks = {}

		for Tank in pairs(self.FuelTanks) do
			Tanks[#Tanks + 1] = Tank:EntIndex()
		end

		duplicator.StoreEntityModifier(self, "ACFFuelTanks", Tanks)
	end

	--Wire dupe info
	self.BaseClass.PreEntityCopy(self)
end

function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
	local EntMods =  Ent.EntityMods

	-- Backwards compatibility
	if EntMods.GearLink then
		local Entities = EntMods.GearLink.entities

		for _, EntID in ipairs(Entities) do
			self:Link(CreatedEntities[EntID])
		end

		EntMods.GearLink = nil
	end

	-- Backwards compatibility
	if EntMods.FuelLink then
		local Entities = EntMods.FuelLink.entities

		for _, EntID in ipairs(Entities) do
			self:Link(CreatedEntities[EntID])
		end

		EntMods.FuelLink = nil
	end

	if EntMods.ACFGearboxes then
		for _, EntID in ipairs(EntMods.ACFGearboxes) do
			self:Link(CreatedEntities[EntID])
		end

		EntMods.ACFGearboxes = nil
	end

	if EntMods.ACFFuelTanks then
		for _, EntID in ipairs(EntMods.ACFFuelTanks) do
			self:Link(CreatedEntities[EntID])
		end

		EntMods.ACFFuelTanks = nil
	end

	--Wire dupe info
	self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
end

function ENT:OnRemove()
	if self.Sound then
		self.Sound:Stop()
	end

	for Gearbox in pairs(self.Gearboxes) do
		self:Unlink(Gearbox)
	end

	for Tank in pairs(self.FuelTanks) do
		self:Unlink(Tank)
	end

	TimerRemove("ACF Engine Clock " .. self:EntIndex())

	WireLib.Remove(self)
end