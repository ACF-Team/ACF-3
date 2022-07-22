AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local ACF = ACF

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

local Clock       = ACF.Utilities.Clock
local MaxDistance = ACF.LinkDistance * ACF.LinkDistance
local UnlinkSound = "physics/metal/metal_box_impact_bullet%s.wav"
local Round       = math.Round
local max         = math.max
local min         = math.min
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
	local Throttle = Engine.RevLimited and 0 or Engine.Throttle
	local Volume = 0.25 + (0.1 + 0.9 * ((RPM / Engine.LimitRPM) ^ 1.5)) * Throttle * 0.666

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
		if EnginePos:DistToSqr(Tank:GetPos()) > MaxDistance then
			local Sound = UnlinkSound:format(math.random(1, 3))

			Engine:EmitSound(Sound, 70, 100, ACF.Volume)
			Tank:EmitSound(Sound, 70, 100, ACF.Volume)

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

		Entity.LastThink = Clock.CurTime
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
	local Classes     = ACF.Classes
	local Engines     = Classes.Engines
	local EngineTypes = Classes.EngineTypes
	local Entities    = Classes.Entities

	local function VerifyData(Data)
		if not Data.Engine then
			Data.Engine = Data.Id or "5.7-V8"
		end

		local Class = Classes.GetGroup(Engines, Data.Engine)

		if not Class then
			Class = Engines.Get("V8")

			Data.Engine = "5.7-V8"
		end

		local Engine = Engines.GetItem(Class.ID, Data.Engine)

		do -- External verifications
			if Class.VerifyData then
				Class.VerifyData(Data, Class, Engine)
			end

			HookRun("ACF_VerifyData", "acf_engine", Data, Class, Engine)
		end
	end

	local function UpdateEngine(Entity, Data, Class, Engine, Type)
		Entity.ACF = Entity.ACF or {}
		Entity.ACF.Model = Engine.Model

		Entity:SetModel(Engine.Model)

		Entity:PhysicsInit(SOLID_VPHYSICS)
		Entity:SetMoveType(MOVETYPE_VPHYSICS)

		-- Storing all the relevant information on the entity for duping
		for _, V in ipairs(Entity.DataStore) do
			Entity[V] = Data[V]
		end

		Entity.Name             = Engine.Name
		Entity.ShortName        = Engine.ID
		Entity.EntType          = Class.Name
		Entity.ClassData        = Class
		Entity.DefaultSound     = Engine.Sound
		Entity.SoundPitch       = Engine.Pitch or 1
		Entity.TorqueCurve      = Engine.TorqueCurve
		Entity.CurveFactor      = Engine.CurveFactor
		Entity.PeakTorque       = Engine.Torque
		Entity.PeakPower		= Engine.PeakPower
		Entity.PeakPowerRPM		= Engine.PeakPowerRPM
		Entity.PeakTorqueHeld   = Engine.Torque
		Entity.IdleRPM          = Engine.RPM.Idle
		Entity.PeakMinRPM       = Engine.RPM.PeakMin
		Entity.PeakMaxRPM       = Engine.RPM.PeakMax
		Entity.LimitRPM         = Engine.RPM.Limit
		Entity.RevLimited       = false
		Entity.FlywheelOverride = Engine.RPM.Override
		Entity.FlywheelMass     = Engine.FlywheelMass
		Entity.Inertia          = Engine.FlywheelMass * math.pi ^ 2
		Entity.IsElectric       = Engine.IsElectric
		Entity.IsTrans          = Engine.IsTrans -- driveshaft outputs to the side
		Entity.FuelTypes        = Engine.Fuel or { Petrol = true }
		Entity.FuelType         = next(Engine.Fuel)
		Entity.EngineType       = Type.ID
		Entity.Efficiency       = Type.Efficiency * GetEfficiencyMult()
		Entity.TorqueScale      = Type.TorqueScale
		Entity.HealthMult       = Type.HealthMult
		Entity.HitBoxes         = ACF.GetHitboxes(Engine.Model)
		Entity.Out              = Entity:WorldToLocal(Entity:GetAttachment(Entity:LookupAttachment("driveshaft")).Pos)

		Entity:SetNWString("WireName", "ACF " .. Entity.Name)

		--calculate base fuel usage
		if Type.CalculateFuelUsage then
			Entity.FuelUse = Type.CalculateFuelUsage(Entity)
		else
			Entity.FuelUse = ACF.FuelRate * Entity.Efficiency * 3e-8
		end

		ACF.Activate(Entity, true)

		Entity.ACF.LegalMass	= Engine.Mass
		Entity.ACF.Model		= Engine.Model

		local Phys = Entity:GetPhysicsObject()
		if IsValid(Phys) then Phys:SetMass(Engine.Mass) end
	end

	function MakeACF_Engine(Player, Pos, Angle, Data)
		VerifyData(Data)

		local Class  = Classes.GetGroup(Engines, Data.Engine)
		local Engine = Engines.GetItem(Class.ID, Data.Engine)
		local Type   = EngineTypes.Get(Engine.Type)
		local Limit  = Class.LimitConVar.Name

		if not Player:CheckLimit(Limit) then return false end

		local CanSpawn = HookRun("ACF_PreEntitySpawn", "acf_engine", Player, Data, Class, Engine)

		if CanSpawn == false then return false end

		local Entity = ents.Create("acf_engine")

		if not IsValid(Entity) then return false end

		Entity:SetPlayer(Player)
		Entity:SetAngles(Angle)
		Entity:SetPos(Pos)
		Entity:Spawn()

		Player:AddCleanup("acf_engine", Entity)
		Player:AddCount(Limit, Entity)

		Entity.Owner        = Player -- MUST be stored on ent for PP
		Entity.Active       = false
		Entity.Gearboxes    = {}
		Entity.FuelTanks    = {}
		Entity.LastThink    = 0
		Entity.MassRatio    = 1
		Entity.FuelUsage    = 0
		Entity.Throttle     = 0
		Entity.FlyRPM       = 0
		Entity.SoundPath    = Engine.Sound
		Entity.DataStore    = Entities.GetArguments("acf_engine")
		Entity.Inputs       = WireLib.CreateInputs(Entity, {
			"Active (Turns the engine on if it is not 0)",
			"Throttle (0-100 for how hard the engine should run)"
		})
		Entity.Outputs      = WireLib.CreateOutputs(Entity, {
			"RPM (Current rotations per minute of the engine)",
			"Torque (nM of torque from the engine)",
			"Power (kW of power from the engine)",
			"Fuel Use (Amount of fuel being used)",
			"Entity (The engine itself) [ENTITY]",
			"Mass (Total mass detected on the vehicle by the engine)",
			"Physical Mass (Physical mass detected on the vehicle by the engine)"
		})

		WireLib.TriggerOutput(Entity, "Entity", Entity)

		UpdateEngine(Entity, Data, Class, Engine, Type)

		if Class.OnSpawn then
			Class.OnSpawn(Entity, Data, Class, Engine)
		end

		HookRun("ACF_OnEntitySpawn", "acf_engine", Entity, Data, Class, Engine)

		Entity:UpdateOverlay(true)

		do -- Mass entity mod removal
			local EntMods = Data and Data.EntityMods

			if EntMods and EntMods.mass then
				EntMods.mass = nil
			end
		end

		ACF.CheckLegal(Entity)

		return Entity
	end

	Entities.Register("acf_engine", MakeACF_Engine, "Engine")

	ACF.RegisterLinkSource("acf_engine", "FuelTanks")
	ACF.RegisterLinkSource("acf_engine", "Gearboxes")

	------------------- Updating ---------------------

	function ENT:Update(Data)
		if self.Active then return false, "Turn off the engine before updating it!" end

		VerifyData(Data)

		local Class    = Classes.GetGroup(Engines, Data.Engine)
		local Engine   = Engines.GetItem(Class.ID, Data.Engine)
		local Type     = EngineTypes.Get(Engine.Type)
		local OldClass = self.ClassData
		local Feedback = ""

		local CanUpdate, Reason = HookRun("ACF_PreEntityUpdate", "acf_engine", self, Data, Class, Engine)

		if CanUpdate == false then return CanUpdate, Reason end

		if OldClass.OnLast then
			OldClass.OnLast(self, OldClass)
		end

		HookRun("ACF_OnEntityLast", "acf_engine", self, OldClass)

		ACF.SaveEntity(self)

		UpdateEngine(self, Data, Class, Engine, Type)

		ACF.RestoreEntity(self)

		if Class.OnUpdate then
			Class.OnUpdate(self, Data, Class, Engine)
		end

		HookRun("ACF_OnEntityUpdate", "acf_engine", self, Data, Class, Engine)

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
	local Power, PowerFt = Round(self.PeakPower), Round(self.PeakPower * 1.34)
	local Torque, TorqueFt = Round(self.PeakTorque), Round(self.PeakTorque * 0.73)
	local PowerbandMin = self.PeakMinRPM
	local PowerbandMax = self.PeakMaxRPM
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
function ENT:ACF_OnDamage(Bullet, Trace, Volume)
	local Res = ACF.PropDamage(Bullet, Trace, Volume)

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

	if self.FuelType == "Electric" then
		return Throttle * self.FuelUse * self.Torque * RPM * 1.05e-4
	else
		local IdleConsumption = self.PeakPower * 5e2
		return self.FuelUse * (IdleConsumption + Throttle * self.Torque * RPM) / self.FuelTank.FuelDensity
	end
end

function ENT:CalcRPM()
	if not self.Active then return end

	local DeltaTime = Clock.CurTime - self.LastThink
	local FuelTank 	= GetNextFuelTank(self)

	-- Determine if the rev limiter will engage or disengage
	if not self.IsElectric then
		if self.FlyRPM > self.LimitRPM * 0.99 then
			self.RevLimited = true
		elseif self.FlyRPM < self.LimitRPM * 0.95 then
			self.RevLimited = false
		end
	end
	local Throttle = self.RevLimited and 0 or self.Throttle

	--calculate fuel usage
	if IsValid(FuelTank) then
		self.FuelTank = FuelTank
		self.FuelType = FuelTank.FuelType

		local Consumption = self:GetConsumption(Throttle, self.FlyRPM) * DeltaTime

		self.FuelUsage = 60 * Consumption / DeltaTime

		FuelTank:Consume(Consumption)
	elseif ACF.Gamemode ~= 1 then -- Sandbox gamemode servers will require no fuel
		SetActive(self, false)

		self.FuelUsage = 0

		return 0
	end

	-- Calculate the current torque from flywheel RPM
	local Percent = (self.FlyRPM - self.IdleRPM) / self.CurveFactor / self.LimitRPM
	local PeakRPM = self.IsElectric and self.FlywheelOverride or self.PeakMaxRPM
	local Drag    = self.PeakTorque * (max(self.FlyRPM - self.IdleRPM, 0) / PeakRPM) * (1 - Throttle) / self.Inertia

	self.Torque = Throttle * ACF.GetTorque(self.TorqueCurve, Percent) * self.PeakTorque * (self.FlyRPM < self.LimitRPM and 1 or 0)
	-- Let's accelerate the flywheel based on that torque
	self.FlyRPM = min(max(self.FlyRPM + self.Torque / self.Inertia - Drag, 0), self.LimitRPM)

	-- The gearboxes don't think on their own, it's the engine that calls them, to ensure consistent execution order
	local Boxes      = 0
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
	self.LastThink = Clock.CurTime

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
