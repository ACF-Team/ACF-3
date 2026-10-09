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
local abs          = math.abs
local max          = math.max
local Clamp        = math.Clamp
local PI           = math.pi
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
	if ActBool and (EntTbl.Disabled or EntTbl.IsDestroyed) then return end -- Can't activate a disabled engine

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
	if SelfTbl.IsDestroyed then return end

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
	local IdleRPM    = SelfTbl.IdleRPM
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

	-- Throttle Idler code shamefully stolen from Tyunge's engine rework.
	local IdleRatio = (IdleRPM - FlyRPM) / IdleRPM
	SelfTbl.IdleThrottle = Clamp(SelfTbl.IdleThrottle + (IdleRatio * 0.25), 0, 1) -- TODO: Potentially here we would change the engine's ability to idle correctly based on damage.

	local SmoothedIdle = SelfTbl.IdleThrottle - SelfTbl.LastIdleThrottle
	SelfTbl.LastIdleThrottle = SelfTbl.IdleThrottle

	local Throttle = RevLimited and 0 or Clamp(SelfTbl.Throttle + (SelfTbl.IdleThrottle + SmoothedIdle * 5), 0, 1)

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

	local Torque = 0
	local PeakTorque = SelfTbl.PeakTorque
	local FlyInertia = SelfTbl.Inertia

	-- Calculate the current torque from flywheel RPM
	if FlyRPM < LimitRPM then
		local Percent = Remap(FlyRPM, IdleRPM, LimitRPM, 0, 1)
		Torque = Throttle * ACF.GetTorque(SelfTbl.TorqueCurve, Percent) * PeakTorque
	end

	SelfTbl.Torque = Torque

	-- The gearboxes don't think on their own, it's the engine that calls them, to ensure consistent execution order
	local GearboxCount      = 0
	local GearboxLoad       = 0
	local GearboxRPM        = 0
	local GearboxInertia    = 0
	local GearboxTotalRatio = 0

	-- Get the requirements for torque for the gearboxes (Max clutch rating minus any wheels currently spinning faster than the Flywheel)
	local BoxesTbl = SelfTbl.Gearboxes

	for Ent, _ in pairs(BoxesTbl) do
		local EntTbl = ENTITY.GetTable(Ent)

		if not EntTbl.Disabled then
			EntTbl.Calc(Ent, FlyRPM, FlyInertia)

			GearboxCount      = GearboxCount + 1
			GearboxLoad       = GearboxLoad + (EntTbl.Load or 0)
			GearboxTotalRatio = GearboxTotalRatio + (EntTbl.TotalRatio or 0)
			GearboxRPM        = GearboxRPM + (EntTbl.MeasuredRPM or FlyRPM)
			GearboxInertia    = GearboxInertia + (EntTbl.DownstreamInertia or 0)
		end
	end

	if GearboxCount > 0 then
		GearboxRPM = GearboxRPM / GearboxCount
		GearboxTotalRatio = GearboxTotalRatio / GearboxCount
		GearboxLoad = GearboxLoad / GearboxCount
	end

	-- local CompressionBrakeTorque = -(25 * SelfTbl.Displacement.InLiters / (4 * PI)) * SelfTbl.CompressionRatio * (1 - Throttle)
	local CompressionBrakeTorque = -(SelfTbl.Displacement / (4 * PI)) * (FlyRPM * ACF.RPMToRads) * (1 - Throttle)
	local SlipDifference = GearboxRPM - FlyRPM
	local MaxTq = (abs(SlipDifference) * GearboxInertia) / max(GearboxTotalRatio, 0.001)
	local FeedbackTq = Clamp((SlipDifference * GearboxInertia * GearboxLoad) * 0.5, -MaxTq, MaxTq)
	local IncomingInertia = FlyInertia + GearboxInertia * GearboxLoad

	-- This is the marginal net torque generated by the engine
	local EngineTorque = (Torque + FeedbackTq + (CompressionBrakeTorque * max(1 - GearboxLoad, 0.5))) -- Limited compression brake slip

	-- Let's accelerate the flywheel based on that torque
	FlyRPM = max(FlyRPM + EngineTorque / IncomingInertia, 0)
	SelfTbl.FlyRPM = FlyRPM

	local MassRatio = SelfTbl.MassRatio
	local DriveTorque = EngineTorque - FeedbackTq

	-- The resulting torque output would be 0 when there's no gearboxes linked anyways, so we'll just skip the calculations entirely
	if GearboxCount > 0 then
		for Ent, Link in pairs(BoxesTbl) do
			local EntTbl = ENTITY.GetTable(Ent)

			if not EntTbl.Disabled then
				-- Split the torque fairly between the gearboxes who need it
				local Share = (EntTbl.DownstreamInertia or 0) / max(GearboxInertia, 1e-6)
				Link:TransferGearbox(Ent, DriveTorque * Share, DeltaTime, MassRatio, FlyRPM)
			end
		end
	end

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
	if self.IsDestroyed then
		State:AddError("Destroyed")
	elseif self.Disabled then
		State:AddError("Disabled!")
	else
		if self.Active then
			State:AddSuccess("Active")
		else
			State:AddWarning("Idle")
		end
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