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
		if not Engine.FuelTypes[Target.FuelType] then return false, "Cannot link because fuel type is incompatible." end
		if Target.NoLinks then return false, "This fuel tank doesn't allow linking." end

		Engine.FuelTanks[Target] = true
		Target.Engines[Engine] = true

		Engine:UpdateOverlay()
		Target:UpdateOverlay()

		return true, "Engine linked successfully!"
	end)

	ACF.RegisterClassUnlink("acf_engine", "acf_fueltank", function(Engine, Target)
		if Engine.FuelTanks[Target] or Target.Engines[Engine] then
			if Engine.FuelTank == Target then
				Engine.FuelTank = next(Engine.FuelTanks, Target)
			end

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
local Engines     = ACF.Classes.Engines
local EngineTypes = ACF.Classes.EngineTypes
local UnlinkSound = "physics/metal/metal_box_impact_bullet%s.wav"
local Round       = math.Round
local max         = math.max
local TimerCreate = timer.Create
local TimerSimple = timer.Simple
local TimerRemove = timer.Remove
local HookRun     = hook.Run

-- Fuel consumption is increased on competitive servers
local function GetEfficiencyMult()
	return ACF.Gamemode == 3 and ACF.CompFuelRate or 1
end

local function GetPitchVolume(Engine)
	local RPM = Engine.FlyRPM
	local Pitch = math.Clamp(20 + (RPM * Engine.SoundPitch) * 0.02, 1, 255)
	local Volume = 0.25 + (0.1 + 0.9 * ((RPM / Engine.LimitRPM) ^ 1.5)) * Engine.Throttle * 0.666

	return Pitch, Volume * ACF.Volume
end

local function GetNextFuelTank(Engine)
	if not next(Engine.FuelTanks) then return end

	local Select = next(Engine.FuelTanks, Engine.FuelTank) or next(Engine.FuelTanks)
	local Start = Select

	repeat
		if Select:CanConsume() then return Select end

		Select = next(Engine.FuelTanks, Select) or next(Engine.FuelTanks)
	until Select == Start

	return Select:CanConsume() and Select or nil
end

local function CheckDistantFuelTanks(Engine)
	local EnginePos = Engine:GetPos()

	for Tank in pairs(Engine.FuelTanks) do
		if EnginePos:DistToSqr(Tank:GetPos()) > 262144 then
			Engine:EmitSound(UnlinkSound:format(math.random(1, 3)), 70, 100, ACF.Volume)

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

--===============================================================================================--

do -- Spawn and Update functions
	local function VerifyData(Data)
		if not Data.Engine then
			Data.Engine = Data.Id or "5.7-V8"
		end

		local Class = ACF.GetClassGroup(Engines, Data.Engine)

		if not Class then
			Data.Engine = "5.7-V8"

			Class = ACF.GetClassGroup(Engines, "5.7-V8")
		end

		do -- External verifications
			if Class.VerifyData then
				Class.VerifyData(Data, Class)
			end

			HookRun("ACF_VerifyData", "acf_engine", Data, Class)
		end
	end

	local function UpdateEngine(Entity, Data, Class, EngineData)
		local Type = EngineData.Type or "GenericPetrol"
		local EngineType = EngineTypes[Type] or EngineTypes.GenericPetrol

		Entity:SetModel(EngineData.Model)

		Entity:PhysicsInit(SOLID_VPHYSICS)
		Entity:SetMoveType(MOVETYPE_VPHYSICS)

		-- Storing all the relevant information on the entity for duping
		for _, V in ipairs(Entity.DataStore) do
			Entity[V] = Data[V]
		end

		Entity.Name             = EngineData.Name
		Entity.ShortName        = EngineData.ID
		Entity.EntType          = Class.Name
		Entity.ClassData        = Class
		Entity.DefaultSound     = EngineData.Sound
		Entity.SoundPitch       = EngineData.Pitch or 1
		Entity.PeakTorque       = EngineData.Torque
		Entity.PeakTorqueHeld   = EngineData.Torque
		Entity.IdleRPM          = EngineData.RPM.Idle
		Entity.PeakMinRPM       = EngineData.RPM.PeakMin
		Entity.PeakMaxRPM       = EngineData.RPM.PeakMax
		Entity.LimitRPM         = EngineData.RPM.Limit
		Entity.FlywheelOverride = EngineData.RPM.Override
		Entity.FlywheelMass     = EngineData.FlywheelMass
		Entity.Inertia          = EngineData.FlywheelMass * 3.1416 ^ 2
		Entity.IsElectric       = EngineData.IsElectric
		Entity.IsTrans          = EngineData.IsTrans -- driveshaft outputs to the side
		Entity.FuelTypes        = EngineData.Fuel or { Petrol = true }
		Entity.FuelType         = next(EngineData.Fuel)
		Entity.EngineType       = EngineType.ID
		Entity.Efficiency       = EngineType.Efficiency * GetEfficiencyMult()
		Entity.TorqueScale      = EngineType.TorqueScale
		Entity.HealthMult       = EngineType.HealthMult
		Entity.HitBoxes         = ACF.HitBoxes[EngineData.Model]
		Entity.Out              = Entity:WorldToLocal(Entity:GetAttachment(Entity:LookupAttachment("driveshaft")).Pos)

		Entity:SetNWString("WireName", "ACF " .. Entity.Name)

		--calculate boosted peak kw
		if EngineType.CalculatePeakEnergy then
			local peakkw, PeakKwRPM = EngineType.CalculatePeakEnergy(Entity)

			Entity.peakkw = peakkw
			Entity.PeakKwRPM = PeakKwRPM
		else
			Entity.peakkw = Entity.PeakTorque * Entity.PeakMaxRPM / 9548.8
			Entity.PeakKwRPM = Entity.PeakMaxRPM
		end

		--calculate base fuel usage
		if EngineType.CalculateFuelUsage then
			Entity.FuelUse = EngineType.CalculateFuelUsage(Entity)
		else
			Entity.FuelUse = ACF.FuelRate * Entity.Efficiency * Entity.peakkw / 3600
		end

		ACF.Activate(Entity, true)

		Entity.ACF.LegalMass	= EngineData.Mass
		Entity.ACF.Model		= EngineData.Model

		local Phys = Entity:GetPhysicsObject()
		if IsValid(Phys) then Phys:SetMass(EngineData.Mass) end
	end

	function MakeACF_Engine(Player, Pos, Angle, Data)
		VerifyData(Data)

		local Class = ACF.GetClassGroup(Engines, Data.Engine)
		local EngineData = Class.Lookup[Data.Engine]
		local Limit = Class.LimitConVar.Name

		if not Player:CheckLimit(Limit) then return false end

		local Engine = ents.Create("acf_engine")

		if not IsValid(Engine) then return end

		Engine:SetPlayer(Player)
		Engine:SetAngles(Angle)
		Engine:SetPos(Pos)
		Engine:Spawn()

		Player:AddCleanup("acf_engine", Engine)
		Player:AddCount(Limit, Engine)

		Engine.Owner        = Player -- MUST be stored on ent for PP
		Engine.Active       = false
		Engine.Gearboxes    = {}
		Engine.FuelTanks    = {}
		Engine.LastThink    = 0
		Engine.MassRatio    = 1
		Engine.FuelUsage    = 0
		Engine.Throttle     = 0
		Engine.FlyRPM       = 0
		Engine.SoundPath    = EngineData.Sound
		Engine.Inputs       = WireLib.CreateInputs(Engine, { "Active", "Throttle" })
		Engine.Outputs      = WireLib.CreateOutputs(Engine, { "RPM", "Torque", "Power", "Fuel Use", "Entity [ENTITY]", "Mass", "Physical Mass" })
		Engine.DataStore    = ACF.GetEntityArguments("acf_engine")

		WireLib.TriggerOutput(Engine, "Entity", Engine)

		UpdateEngine(Engine, Data, Class, EngineData)

		if Class.OnSpawn then
			Class.OnSpawn(Engine, Data, Class, EngineData)
		end

		HookRun("ACF_OnEntitySpawn", "acf_engine", Engine, Data, Class, EngineData)

		Engine:UpdateOverlay(true)

		do -- Mass entity mod removal
			local EntMods = Data and Data.EntityMods

			if EntMods and EntMods.mass then
				EntMods.mass = nil
			end
		end

		CheckLegal(Engine)

		return Engine
	end

	ACF.RegisterEntityClass("acf_engine", MakeACF_Engine, "Engine")
	ACF.RegisterLinkSource("acf_engine", "FuelTanks")
	ACF.RegisterLinkSource("acf_engine", "Gearboxes")

	------------------- Updating ---------------------

	function ENT:Update(Data)
		if self.Active then return false, "Turn off the engine before updating it!" end

		VerifyData(Data)

		local Class      = ACF.GetClassGroup(Engines, Data.Engine)
		local EngineData = Class.Lookup[Data.Engine]
		local OldClass   = self.ClassData
		local Feedback   = ""

		if OldClass.OnLast then
			OldClass.OnLast(self, OldClass)
		end

		HookRun("ACF_OnEntityLast", "acf_engine", self, OldClass)

		ACF.SaveEntity(self)

		UpdateEngine(self, Data, Class, EngineData)

		ACF.RestoreEntity(self)

		if Class.OnUpdate then
			Class.OnUpdate(self, Data, Class, EngineData)
		end

		HookRun("ACF_OnEntityUpdate", "acf_engine", self, Data, Class, EngineData)

		if next(self.Gearboxes) then
			local Count, Total = 0, 0

			for Gearbox in pairs(self.Gearboxes) do
				self:Unlink(Gearbox)

				local Result = self:Link(Gearbox)

				if not Result then Count = Count + 1 end

				Total = Total + 1
			end

			if Count == Total then
				Feedback = Feedback .. "\nUnlinked all gearboxes due to excessive driveshaft angle."
			elseif Count > 0 then
				local Text = Feedback .. "\nUnlinked %s out of %s gearboxes due to excessive driveshaft angle."

				Feedback = Text:format(Count, Total)
			end
		end

		if next(self.FuelTanks) then
			local Count, Total = 0, 0

			for Tank in pairs(self.FuelTanks) do
				if not self.FuelTypes[Tank.FuelType] then
					self:Unlink(Tank)

					Count = Count + 1
				end

				Total = Total + 1
			end

			if Count == Total then
				Feedback = Feedback .. "\nUnlinked all fuel tanks due to fuel type change."
			elseif Count > 0 then
				local Text = Feedback .. "\nUnlinked %s out of %s fuel tanks due to fuel type change."

				Feedback = Text:format(Count, Total)
			end
		end

		self:UpdateOverlay(true)

		net.Start("ACF_UpdateEntity")
			net.WriteEntity(self)
		net.Broadcast()

		return true, "Engine updated successfully!" .. Feedback
	end
end

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

function ENT:UpdateOutputs()
	if not IsValid(self) then return end

	local Power = self.Torque * self.FlyRPM / 9548.8

	WireLib.TriggerOutput(self, "Fuel Use", self.FuelUsage)
	WireLib.TriggerOutput(self, "Torque", math.floor(self.Torque))
	WireLib.TriggerOutput(self, "Power", math.floor(Power))
	WireLib.TriggerOutput(self, "RPM", math.floor(self.FlyRPM))
end

local Text = "%s\n\n%s\nPower: %s kW / %s hp\nTorque: %s Nm / %s ft-lb\nPowerband: %s - %s RPM\nRedline: %s RPM"

function ENT:UpdateOverlayText()
	local State, Name = self.Active and "Active" or "Idle", self.Name
	local Power, PowerFt = Round(self.peakkw), Round(self.peakkw * 1.34)
	local Torque, TorqueFt = Round(self.PeakTorque), Round(self.PeakTorque * 0.73)
	local PowerbandMin = self.IsElectric and self.IdleRPM or self.PeakMinRPM
	local PowerbandMax = self.IsElectric and math.floor(self.LimitRPM / 2) or self.PeakMaxRPM
	local Redline = self.LimitRPM

	return Text:format(State, Name, Power, PowerFt, Torque, TorqueFt, PowerbandMin, PowerbandMax, Redline)
end

ACF.AddInputAction("acf_engine", "Throttle", function(Entity, Value)
	Entity.Throttle = math.Clamp(Value, 0, 100) * 0.01
end)

ACF.AddInputAction("acf_engine", "Active", function(Entity, Value)
	SetActive(Entity, tobool(Value))
end)

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

	self.ACF.Health = Health * Percent * self.HealthMult
	self.ACF.MaxHealth = Health * self.HealthMult
	self.ACF.Armour = Armour * (0.5 + Percent / 2)
	self.ACF.MaxArmour = Armour * ACF.ArmorMod
	self.ACF.Type = nil
	self.ACF.Mass = PhysObj:GetMass()
	self.ACF.Type = "Prop"
end

--This function needs to return HitRes
function ENT:ACF_OnDamage(Energy, FrArea, Angle, Inflictor, _, Type)
	local Mul = Type == "HEAT" and ACF.HEATMulEngine or 1 --Heat penetrators deal bonus damage to engines
	local Res = ACF.PropDamage(self, Energy, FrArea * Mul, Angle, Inflictor)

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
		self.FuelType = FuelTank.FuelType

		local Consumption = self:GetConsumption(self.Throttle, self.FlyRPM) * DeltaTime

		self.FuelUsage = 60 * Consumption / DeltaTime

		FuelTank:Consume(Consumption)
	elseif ACF.Gamemode ~= 1 then -- Sandbox gamemode servers will require no fuel
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
	local EntMods = Ent.EntityMods

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
	local Class = self.ClassData

	if Class.OnLast then
		Class.OnLast(self, Class)
	end

	HookRun("ACF_OnEntityLast", "acf_engine", self, Class)

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
