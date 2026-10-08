local ACF            = ACF
local TimerCreate    = timer.Create

local ENTITY 		 = FindMetaTable("Entity")
local PHYSOBJ		 = FindMetaTable("PhysObj")

local IsEntityValid  = ACF.Optimizations.IsEntityValid
local IsPhysObjValid = ACF.Optimizations.IsPhysObjValid

--===============================================================================================--
-- Local Funcs and Vars
--===============================================================================================--

local Utilities    = ACF.Utilities
local Clock        = Utilities.Clock
local Contraption  = ACF.Contraption

local Round        = math.Round
local Remap        = math.Remap
local max          = math.max
local min          = math.min
local Clamp        = math.Clamp
local TickInterval = engine.TickInterval
local TimerRemove  = timer.Remove

-- Only called when the cached tank is unusable, so a linear scan over the (small) sibling set is fine
local function FindFuelTank(EngineTbl)
	local MinPriority = ACF.FuelPriorityMin
	local Best, BestPriority

	for Tank in pairs(EngineTbl.FuelTanks) do
		local TankTbl  = ENTITY.GetTable(Tank)
		local Priority = TankTbl.FuelPriority

		if (not Best or Priority < BestPriority) and TankTbl.CanConsume(Tank) then
			Best, BestPriority = Tank, Priority

			if Priority <= MinPriority then break end
		end
	end

	return Best
end

-- Checks for any gearbox that has moved too far away or its angle relative to this engine's output shaft is now excessive.
local function CheckGearboxes(Engine)
	for Ent, Link in pairs(Engine.Gearboxes) do
		local OutPos = Engine:LocalToWorld(Engine.Out.Pos)
		local InPos = Ent:LocalToWorld(Ent.In.Pos)

		-- make sure it is not stretched too far
		if OutPos:Distance(InPos) > Link.RopeLen * 1.5 then
			Engine:Unlink(Ent)
			continue
		end

		if ACF.IsDriveshaftAngleExcessive(Ent, Ent.In, Engine, Engine.Out) then
			Engine:Unlink(Ent)
		end
	end
end

-- Handles engine's ON/OFF state.
local function SetActive(Entity, Value, EntTbl)
	EntTbl = EntTbl or Entity:GetTable()

	local ActBool = tobool(Value)

	if EntTbl.Active == ActBool then return end -- Already in the desired state
	if ActBool and EntTbl.Disabled then return end -- Can't activate a disabled engine

	if ActBool then -- Was off, turn on
		EntTbl.Active = true

		Entity:CalcMassRatio(EntTbl)

		EntTbl.LastThink = Clock.CurTime
		EntTbl.Torque    = EntTbl.PeakTorque
		EntTbl.FlyRPM    = EntTbl.IdleRPM * 1.5

		Entity:UpdateSound(EntTbl)

		Entity:NextThink(Clock.CurTime + TickInterval())

		TimerCreate("ACF Engine Clock " .. Entity:EntIndex(), 3, 0, function()
			if not IsEntityValid(Entity) then return end

			CheckGearboxes(Entity)

			Entity:CalcMassRatio(EntTbl)
		end)
	else -- Was on, turn off
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
-- State machine logic sim 
--===============================================================================================--

-- specialized calcmassratio for engines
function ENT:CalcMassRatio(SelfTbl)
	SelfTbl        = SelfTbl or ENTITY.GetTable(self)
	local Con      = ENTITY.CFW_GetContraption(self)
	local PhysMass = 0

	local Physical, _, Detached = Contraption.GetEnts(self)

	-- Duplex pairs iterates over Physical, then Detached - but we can make Detached nil
	-- if DetachedPhysmassRatio == false
	for K in ACF.DuplexPairs(Physical, ACF.DetachedPhysmassRatio and Detached or nil) do
		local Phys = ENTITY.GetPhysicsObject(K) -- Should always exist, but just in case

		if IsPhysObjValid(Phys) then
			local Mass = PHYSOBJ.GetMass(Phys)
			PhysMass   = PhysMass + Mass
		end
	end

	local TotalMass = Con and Con.totalMass or PhysMass

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
	SelfTbl = SelfTbl or ENTITY.GetTable(self)
	FuelTank = FuelTank or SelfTbl.FuelTank
	if not IsEntityValid(FuelTank) then return 0 end

	if FuelTank.IsElectric then
		return Throttle * SelfTbl.FuelUse * SelfTbl.Torque * RPM * 1.05e-4
	else
		local IdleConsumption = SelfTbl.PeakPower * 5e2
		return SelfTbl.FuelUse * (IdleConsumption + Throttle * SelfTbl.Torque * RPM) / FuelTank.FuelDensity
	end
end

function ENT:Think()
	local SelfTbl = ENTITY.GetTable(self)

	if not SelfTbl.Active then return end
	if SelfTbl.Disabled then return end
	if SelfTbl.ACF.Health <= 0 then return end

	self:CalcRPM(SelfTbl)

	-- CalcRPM can turn the engine off or disable it (e.g. no fuel or legality issues)
	if not SelfTbl.Active or SelfTbl.Disabled then return end

	self:NextThink(CurTime() + TickInterval())

	return true
end

-- We're doing an experiment here. It seems that the entity table stores the functions for the entity
-- class as well. So we don't need to do self:Function for every entity (which would invoke the __index function)
-- If true then we should apply this in the rest of the hot paths.
function ENT:CalcRPM(SelfTbl)
	-- Reusing these entity table pointers helps us cut down on __index calls
	-- This helps to massively improve performance throughout the entire drivetrain
	SelfTbl = SelfTbl or ENTITY.GetTable(self)

	local ClockTime  = Clock.CurTime
	local DeltaTime  = ClockTime - SelfTbl.LastThink
	local FuelTank   = SelfTbl.FuelTank
	local IsElectric = SelfTbl.IsElectric
	local LimitRPM   = SelfTbl.LimitRPM
	local FlyRPM     = SelfTbl.FlyRPM

	-- Re-searching in the same tick means a tank drained by another engine never stalls this one
	if not (FuelTank and IsEntityValid(FuelTank) and ENTITY.GetTable(FuelTank).CanConsume(FuelTank)) then
		FuelTank = FindFuelTank(SelfTbl)
		SelfTbl.FuelTank = FuelTank

		if FuelTank then SelfTbl.FuelType = FuelTank.FuelType end
	end

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
	if FuelTank then
		local Consumption = SelfTbl.GetConsumption(self, Throttle, FlyRPM, FuelTank, SelfTbl) * DeltaTime

		SelfTbl.FuelUsage = 60 * Consumption / DeltaTime
		ENTITY.GetTable(FuelTank).Consume(FuelTank, Consumption)
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
			local EntTable = ENTITY.GetTable(Ent)
			if not EntTable.Disabled then
				Boxes = Boxes + 1
				Link.ReqTq = EntTable.Calc(Ent, FlyRPM, Inertia)
				TotalReqTq = TotalReqTq + Link.ReqTq
			end
		end

		-- Calculate the ratio of total requested torque versus what's available
		local AvailRatio = min(TorqueDiff / TotalReqTq / Boxes, 1)

		local MassRatio = SelfTbl.MassRatio

		-- Split the torque fairly between the gearboxes who need it
		for Ent, Link in pairs(BoxesTbl) do
			Link:TransferGearbox(Ent, Link.ReqTq * AvailRatio * MassRatio, DeltaTime, MassRatio, FlyRPM)
			--Ent:Act(Link.ReqTq * AvailRatio * MassRatio, DeltaTime, MassRatio)
		end
	end

	SelfTbl.FlyRPM = FlyRPM - min(TorqueDiff, TotalReqTq) / Inertia
	SelfTbl.LastThink = ClockTime

	SelfTbl.UpdateSound(self, SelfTbl)
	SelfTbl.UpdateOutputs(self, SelfTbl)
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
	ACF.CheckLegal(self) -- MARCH: Check parent chain on enabled
end

function ENT:Disable()
	SetActive(self, false, self:GetTable()) -- Turn off the engine

	self:UpdateOverlay()
end

function ENT:UpdateOutputs(SelfTbl)
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

function ENT:ACF_UpdateOverlayState(State)
	if self.Active then
		State:AddSuccess("Active")
	else
		State:AddWarning("Idle")
	end

	if ACF.RequireFuel and not next(self.FuelTanks) then
		State:AddWarning("No compatible fuel tanks share this engine's parent")
	end

	State:AddKeyValue("Type", self.Name)
	State:AddEnginePower("Power", self.PeakPower)
	State:AddEngineTorque("Torque", self.PeakTorque)
	State:AddKeyValue("Powerband", ("%s - %s RPM"):format(self.PeakMinRPM, self.PeakMaxRPM))
	State:AddKeyValue("Redline", ("%s RPM"):format(self.LimitRPM))
end

ACF.AddInputAction("acf_engine", "Throttle", function(Entity, Value)
	Entity.Throttle = Clamp(Value, 0, 100) * 0.01
end)

ACF.AddInputAction("acf_engine", "Active", function(Entity, Value)
	SetActive(Entity, tobool(Value), Entity:GetTable())
end)