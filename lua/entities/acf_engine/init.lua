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

local Damage       = ACF.Damage
local Utilities    = ACF.Utilities
local Clock        = Utilities.Clock
local Sounds       = Utilities.Sounds
local Contraption  = ACF.Contraption
local MaxDistance  = ACF.LinkDistance * ACF.LinkDistance
local UnlinkSound  = "physics/metal/metal_box_impact_bullet%s.wav"
local IsValid      = IsValid
local Clamp        = math.Clamp
local Round        = math.Round
local Remap        = math.Remap
local max          = math.max
local min          = math.min
local TimerCreate  = timer.Create
local TimerSimple  = timer.Simple
local TimerRemove  = timer.Remove
local HookRun      = hook.Run
local TickInterval = engine.TickInterval

local function GetPitchVolume(Engine)
	local RPM = Engine.FlyRPM
	local Pitch = Clamp(20 + (RPM * Engine.SoundPitch) * 0.02, 1, 255)
	local Throttle = Engine.RevLimited and 0 or Engine.Throttle
	local Volume = 0.25 + (0.1 + 0.9 * ((RPM / Engine.LimitRPM) ^ 1.5)) * Throttle * 0.666

	return Pitch, Volume * Engine.SoundVolume
end

local function GetNextFuelTank(Engine)
	local FuelTanks = Engine.FuelTanks
	if not next(FuelTanks) then return end

	local Select = next(FuelTanks, Engine.FuelTank) or next(FuelTanks)
	local Start = Select

	repeat
		if Select:CanConsume() then return Select end

		Select = next(FuelTanks, Select) or next(FuelTanks)
	until Select == Start

	return Select:CanConsume() and Select or nil
end

local function CheckDistantFuelTanks(Engine)
	local EnginePos = Engine:GetPos()

	for Tank in pairs(Engine.FuelTanks) do
		if EnginePos:DistToSqr(Tank:GetPos()) > MaxDistance then
			local Sound = UnlinkSound:format(math.random(1, 3))

			Sounds.SendSound(Engine, Sound, 70, 100, 1)
			Sounds.SendSound(Tank, Sound, 70, 100, 1)

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

local function SetActive(Entity, Value, EntTbl)
	EntTbl = EntTbl or Entity:GetTable()
	if EntTbl.Active == tobool(Value) then return end

	if not EntTbl.Active then -- Was off, turn on
		EntTbl.Active = true

		Entity:CalcMassRatio(EntTbl)

		EntTbl.LastThink = Clock.CurTime
		EntTbl.Torque    = EntTbl.PeakTorque
		EntTbl.FlyRPM    = EntTbl.IdleRPM * 1.5

		Entity:UpdateSound(EntTbl)

		TimerSimple(TickInterval(), function()
			if not IsValid(Entity) then return end

			Entity:CalcRPM(EntTbl)
		end)

		TimerCreate("ACF Engine Clock " .. Entity:EntIndex(), 3, 0, function()
			if not IsValid(Entity) then return end

			CheckGearboxes(Entity)
			CheckDistantFuelTanks(Entity)

			Entity:CalcMassRatio(EntTbl)
		end)
	else
		EntTbl.Active = false
		EntTbl.FlyRPM = 0
		EntTbl.Torque = 0

		Entity:DestroySound()

		TimerRemove("ACF Engine Clock " .. Entity:EntIndex())
	end

	Entity:UpdateOverlay()
	Entity:UpdateOutputs(EntTbl)
end

--===============================================================================================--

do -- Spawn and Update functions
	local Classes     = ACF.Classes
	local WireIO      = Utilities.WireIO
	local Engines     = Classes.Engines
	local EngineTypes = Classes.EngineTypes
	local Entities    = Classes.Entities

	local Inputs = {
		"Active (If set to a non-zero value, it'll attempt to start the engine.)",
		"Throttle (On a range from 0 to 100, defines how much power will be given to the engine.)"
	}
	local Outputs = {
		"RPM (Current rotations per minute of the engine.)",
		"Torque (Current torque, in nM, output by the engine.)",
		"Power (Current power, in kW, output by the engine.)",
		"Fuel Use (Amount of fuel, in liters per minute, being consumed by the engine.)",
		"Mass (Total mass detected on the vehicle by the engine.)",
		"Physical Mass (Physical mass detected on the vehicle by the engine.)",
		"Entity (The engine itself.) [ENTITY]",
	}

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
		local Mass = Engine.Mass

		Entity.ACF = Entity.ACF or {}

		Contraption.SetModel(Entity, Engine.Model)

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
		Entity.SoundVolume      = Engine.SoundVolume or 1
		Entity.TorqueCurve      = Engine.TorqueCurve
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
		Entity.Efficiency       = Type.Efficiency
		Entity.TorqueScale      = Type.TorqueScale
		Entity.HealthMult       = Type.HealthMult
		Entity.HitBoxes         = ACF.GetHitboxes(Engine.Model)
		Entity.Out              = Entity:WorldToLocal(Entity:GetAttachment(Entity:LookupAttachment("driveshaft")).Pos)

		WireIO.SetupInputs(Entity, Inputs, Data, Class, Engine, Type)
		WireIO.SetupOutputs(Entity, Outputs, Data, Class, Engine, Type)

		Entity:SetNWString("WireName", "ACF " .. Entity.Name)

		--calculate base fuel usage
		if Type.CalculateFuelUsage then
			Entity.FuelUse = Type.CalculateFuelUsage(Entity)
		else
			Entity.FuelUse = ACF.FuelRate * Entity.Efficiency * 3e-8
		end

		ACF.Activate(Entity, true)

		Contraption.SetMass(Entity, Mass)
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

		Entity.Owner         = Player -- MUST be stored on ent for PP
		Entity.Active        = false
		Entity.Gearboxes     = {}
		Entity.FuelTanks     = {}
		Entity.LastThink     = 0
		Entity.MassRatio     = 1
		Entity.FuelUsage     = 0
		Entity.Throttle      = 0
		Entity.FlyRPM        = 0
		Entity.SoundPath     = Engine.Sound
		Entity.LastPitch     = 0
		Entity.LastTorque    = 0
		Entity.LastFuelUsage = 0
		Entity.LastPower     = 0
		Entity.LastRPM       = 0
		Entity.LastTotalMass = 0
		Entity.LastPhysMass  = 0
		Entity.DataStore     = Entities.GetArguments("acf_engine")
		Entity.revLimiterEnabled = true

		UpdateEngine(Entity, Data, Class, Engine, Type)

		WireLib.TriggerOutput(Entity, "Entity", Entity)

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

	SetActive(self, Active, self:GetTable())

	self:UpdateOverlay()
end

function ENT:Disable()
	SetActive(self, false, self:GetTable()) -- Turn off the engine

	self:UpdateOverlay()
end

function ENT:UpdateOutputs(SelfTbl)
	if not IsValid(self) then return end

	SelfTbl = SelfTbl or self:GetTable()
	local FuelUsage = Round(SelfTbl.FuelUsage)
	local Torque    = SelfTbl.Torque
	local FlyRPM    = SelfTbl.FlyRPM
	local Power     = Round(Torque * FlyRPM / 9548.8)

	Torque = Round(Torque)
	FlyRPM = Round(FlyRPM)

	if SelfTbl.LastFuelUsage ~= FuelUsage then
		SelfTbl.LastFuelUsage = FuelUsage
		WireLib.TriggerOutput(self, "Fuel Use", FuelUsage)
	end
	if SelfTbl.LastTorque ~= Torque then
		SelfTbl.LastTorque = Torque
		WireLib.TriggerOutput(self, "Torque", Torque)
	end
	if SelfTbl.LastPower ~= Power then
		SelfTbl.LastPower = Power
		WireLib.TriggerOutput(self, "Power", Power)
	end
	if SelfTbl.LastRPM ~= FlyRPM then
		SelfTbl.LastRPM = FlyRPM
		WireLib.TriggerOutput(self, "RPM", FlyRPM)
	end
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
	Entity.Throttle = Clamp(Value, 0, 100) * 0.01
end)

ACF.AddInputAction("acf_engine", "Active", function(Entity, Value)
	SetActive(Entity, tobool(Value), Entity:GetTable())
end)

function ENT:ACF_Activate(Recalc)
	local PhysObj = self.ACF.PhysObj
	local Mass    = PhysObj:GetMass()
	local Area    = PhysObj:GetSurfaceArea() * 6.45
	local Armour  = Mass * 1000 / Area / 0.78 * ACF.ArmorMod -- Density of steel = 7.8g cm3 so 7.8kg for a 1mx1m plate 1m thick
	local Health  = Area / ACF.Threshold
	local Percent = 1

	if Recalc and self.ACF.Health and self.ACF.MaxHealth then
		Percent = self.ACF.Health / self.ACF.MaxHealth
	end

	self.ACF.Area      = Area
	self.ACF.Health    = Health * Percent * self.HealthMult
	self.ACF.MaxHealth = Health * self.HealthMult
	self.ACF.Armour    = Armour * (0.5 + Percent * 0.5)
	self.ACF.MaxArmour = Armour
	self.ACF.Type      = "Prop"
end

--This function needs to return HitRes
function ENT:ACF_OnDamage(DmgResult, DmgInfo)
	local HitRes = Damage.doPropDamage(self, DmgResult, DmgInfo)

	-- Adjusting performance based on damage
	local TorqueMult = Clamp(((1 - self.TorqueScale) / 0.5) * ((self.ACF.Health / self.ACF.MaxHealth) - 1) + 1, self.TorqueScale, 1)

	self.PeakTorque = self.PeakTorqueHeld * TorqueMult

	return HitRes
end

function ENT:UpdateSound(SelfTbl)
	SelfTbl = SelfTbl or self:GetTable()
	local Path = SelfTbl.SoundPath

	if Path ~= SelfTbl.LastSound then
		self:DestroySound()

		SelfTbl.LastSound = Path
	end

	if Path == "" then return end
	if not SelfTbl.Active then return end

	local Pitch, Volume = GetPitchVolume(SelfTbl)

	if math.abs(Pitch - SelfTbl.LastPitch) < 1 then return end -- Don't bother updating if the pitch difference is too small to notice

	SelfTbl.LastPitch = Pitch

	if SelfTbl.Sound then
		Sounds.SendAdjustableSound(self, false, Pitch, Volume)
	else
		Sounds.CreateAdjustableSound(self, Path, Pitch, Volume)
		SelfTbl.Sound = true
	end
end

function ENT:DestroySound()
	Sounds.SendAdjustableSound(self, true)

	self.LastSound  = nil
	self.LastPitch  = 0
	self.Sound      = nil
end

-- specialized calcmassratio for engines
function ENT:CalcMassRatio(SelfTbl)
	SelfTbl = SelfTbl or self:GetTable()
	local PhysMass 	= 0
	local TotalMass = 0
	local Physical, Parented = Contraption.GetEnts(self)

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

	SelfTbl.MassRatio = PhysMass / TotalMass
	TotalMass = Round(TotalMass, 2)
	PhysMass = Round(PhysMass, 2)

	if SelfTbl.LastTotalMass ~= TotalMass then
		SelfTbl.LastTotalMass = TotalMass
		WireLib.TriggerOutput(self, "Mass", Round(TotalMass, 2))
	end
	if SelfTbl.LastPhysMass ~= PhysMass then
		SelfTbl.LastPhysMass = PhysMass
		WireLib.TriggerOutput(self, "Physical Mass", Round(PhysMass, 2))
	end
end

function ENT:GetConsumption(Throttle, RPM, FuelTank, SelfTbl)
	SelfTbl = SelfTbl or self:GetTable()
	FuelTank = FuelTank or SelfTbl.FuelTank
	if not IsValid(FuelTank) then return 0 end

	if SelfTbl.FuelType == "Electric" then
		return Throttle * SelfTbl.FuelUse * SelfTbl.Torque * RPM * 1.05e-4
	else
		local IdleConsumption = SelfTbl.PeakPower * 5e2
		return SelfTbl.FuelUse * (IdleConsumption + Throttle * SelfTbl.Torque * RPM) / FuelTank.FuelDensity
	end
end

function ENT:CalcRPM(SelfTbl)
	-- Reusing these entity table pointers helps us cut down on __index calls
	-- This helps to massively improve performance throughout the entire drivetrain
	SelfTbl = SelfTbl or self:GetTable()
	if not SelfTbl.Active then return end

	local ClockTime  = Clock.CurTime
	local DeltaTime  = ClockTime - SelfTbl.LastThink
	local FuelTank   = GetNextFuelTank(SelfTbl)
	local IsElectric = SelfTbl.IsElectric
	local LimitRPM   = SelfTbl.LimitRPM
	local FlyRPM     = SelfTbl.FlyRPM

	-- Determine if the rev limiter will engage or disengage
	local RevLimited = false
	if SelfTbl.revLimiterEnabled and not IsElectric then
		if FlyRPM > LimitRPM * 0.99 then
			RevLimited = true
		elseif FlyRPM < LimitRPM * 0.95 then
			RevLimited = false
		end

		SelfTbl.RevLimited = RevLimited
	end
	local Throttle = RevLimited and 0 or SelfTbl.Throttle

	-- Calculate fuel usage
	if IsValid(FuelTank) then
		SelfTbl.FuelTank = FuelTank
		SelfTbl.FuelType = FuelTank.FuelType

		local Consumption = self:GetConsumption(Throttle, FlyRPM, FuelTank, SelfTbl) * DeltaTime

		SelfTbl.FuelUsage = 60 * Consumption / DeltaTime

		FuelTank:Consume(Consumption, FuelTank:GetTable())
	elseif ACF.RequireFuel then -- Stay active if fuel consumption is disabled
		SetActive(self, false, SelfTbl)

		SelfTbl.FuelUsage = 0

		return 0
	end

	-- Calculate the current torque from flywheel RPM
	local IdleRPM    = SelfTbl.IdleRPM
	local PeakRPM    = IsElectric and SelfTbl.FlywheelOverride or SelfTbl.PeakMaxRPM
	local Inertia    = SelfTbl.Inertia
	local PeakTorque = SelfTbl.PeakTorque
	local Drag       = PeakTorque * (max(FlyRPM - IdleRPM, 0) / PeakRPM) * (1 - Throttle) / Inertia

	local Torque = 0

	if Throttle ~= 0 and FlyRPM < LimitRPM then
		local Percent = Remap(FlyRPM, IdleRPM, LimitRPM, 0, 1)
		Torque = Throttle * ACF.GetTorque(SelfTbl.TorqueCurve, Percent) * PeakTorque -- * (FlyRPM < LimitRPM and 1 or 0)
	end

	SelfTbl.Torque = Torque

	-- Let's accelerate the flywheel based on that torque
	FlyRPM = min(max(FlyRPM + Torque / Inertia - Drag, 0), LimitRPM)

	-- The gearboxes don't think on their own, it's the engine that calls them, to ensure consistent execution order
	local Boxes      = 0
	local TotalReqTq = 0

	-- This is the presently available torque from the engine
	local TorqueDiff = max(FlyRPM - IdleRPM, 0) * Inertia

	-- The resulting torque output would be 0 when there's no throttle anyways, so we'll just skip the calculations entirely
	if Throttle ~= 0 then
		local BoxesTbl = SelfTbl.Gearboxes

		-- Get the requirements for torque for the gearboxes (Max clutch rating minus any wheels currently spinning faster than the Flywheel)
		for Ent, Link in pairs(BoxesTbl) do
			if not Ent.Disabled then
				Boxes = Boxes + 1
				Link.ReqTq = Ent:Calc(FlyRPM, Inertia)
				TotalReqTq = TotalReqTq + Link.ReqTq
			end
		end

		-- Calculate the ratio of total requested torque versus what's available
		local AvailRatio = min(TorqueDiff / TotalReqTq / Boxes, 1)

		local MassRatio = SelfTbl.MassRatio

		-- Split the torque fairly between the gearboxes who need it
		for Ent, Link in pairs(BoxesTbl) do
			Ent:Act(Link.ReqTq * AvailRatio * MassRatio, DeltaTime, MassRatio)
		end
	end

	SelfTbl.FlyRPM = FlyRPM - min(TorqueDiff, TotalReqTq) / Inertia
	SelfTbl.LastThink = ClockTime

	self:UpdateSound(SelfTbl)
	self:UpdateOutputs(SelfTbl)

	TimerSimple(TickInterval(), function()
		if not IsValid(self) then return end

		self:CalcRPM(SelfTbl)
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

	self:DestroySound()

	for Gearbox in pairs(self.Gearboxes) do
		self:Unlink(Gearbox)
	end

	for Tank in pairs(self.FuelTanks) do
		self:Unlink(Tank)
	end

	TimerRemove("ACF Engine Clock " .. self:EntIndex())

	WireLib.Remove(self)
end