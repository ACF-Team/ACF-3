-- Local variables ---------------------------------
local ACF         	 = ACF

local Utilities   	 = ACF.Utilities
local Clock       	 = Utilities.Clock
local Clamp       	 = math.Clamp
local abs         	 = math.abs
local min         	 = math.min
local max         	 = math.max

local ENTITY         = FindMetaTable("Entity")
local VECTOR         = FindMetaTable("Vector")
local PHYSOBJ        = FindMetaTable("PhysObj")

local IsEntityValid  = ACF.Optimizations.IsEntityValid
local IsPhysObjValid = ACF.Optimizations.IsPhysObjValid

local ENT_ApplyBrakes

-- Get the chassis' angular velocity 
local function GetChassisAngularVelocity(Entity)
	local Parent = ENTITY.GetParent(Entity)
	local Phys   = IsEntityValid(Parent) and ENTITY.GetPhysicsObject(Parent)

	-- Returns the chassis' angular velocity in world space (deg/s).
	if IsPhysObjValid(Phys) then return PHYSOBJ.GetAngleVelocity(Phys) end

	-- In case our gearbox is not parented, we return the gearbox's angular velocity instead.
	Phys = ENTITY.GetPhysicsObject(Entity)
	if IsPhysObjValid(Phys) then return PHYSOBJ.GetAngleVelocity(Phys) end

	-- Fallback to 0, although i think this should error, but ehh whatever you say my GTA III character... :3
	return vector_origin
end

-- Get the wheel's RPM relative to our chassis' angular velocity
local function CalcWheel(Entity, Link, Wheel, ChassisAngVel)
	local EntityTable = ENTITY.GetTable(Entity)

	local GearRatio = EntityTable.GearRatio

	local WheelPhys    = ENTITY.GetPhysicsObject(Wheel)
	local WheelAngVel  = PHYSOBJ.GetAngleVelocity(WheelPhys)
	local WheelVelDiff = PHYSOBJ.LocalToWorldVector(WheelPhys, WheelAngVel)
	VECTOR.Sub(WheelVelDiff, ChassisAngVel)

	local AxisW = PHYSOBJ.LocalToWorldVector(WheelPhys, Link.Axis)

	-- Angular velocity of the wheel relative to the chassis on the drive axis
	local RelAngVel = VECTOR.Dot(WheelVelDiff, AxisW)
	Link.Vel        = RelAngVel

	if GearRatio == 0 then return 0 end

	-- We get degrees per second and is also inverted, so we have to convert to RPM (deg/s -> RPM (1 RPM = 6 deg/s))
	return RelAngVel * GearRatio / -6
end

do -- Inputs -------------------------------------------
	local function SetCanApplyBrakes(Gearbox)
		local CanApply = Gearbox.LBrake ~= 0 or Gearbox.RBrake ~= 0

		if CanApply ~= Gearbox.Braking then
			Gearbox.Braking = CanApply

			ENT_ApplyBrakes(Gearbox)
		end
	end

	ACF.AddInputAction("acf_gearbox", "Gear", function(Entity, Value)
		if Entity.Automatic then
			Entity:ChangeDrive(Value)
		else
			Entity:ChangeGear(Value)
		end
	end)

	ACF.AddInputAction("acf_gearbox", "Gear Up", function(Entity, Value)
		if not tobool(Value) then return end

		if Entity.Automatic then
			Entity:ChangeDrive(Entity.Drive + 1)
		else
			Entity:ChangeGear(Entity.Gear + 1)
		end
	end)

	ACF.AddInputAction("acf_gearbox", "Gear Down", function(Entity, Value)
		if not tobool(Value) then return end

		if Entity.Automatic then
			Entity:ChangeDrive(Entity.Drive - 1)
		else
			Entity:ChangeGear(Entity.Gear - 1)
		end
	end)

	ACF.AddInputAction("acf_gearbox", "Clutch", function(Entity, Value)
		Entity.LClutch = Clamp(1 - Value, 0, 1)
		Entity.RClutch = Clamp(1 - Value, 0, 1)
	end)

	ACF.AddInputAction("acf_gearbox", "Left Clutch", function(Entity, Value)
		if not Entity.DualClutch then return end

		Entity.LClutch = Clamp(1 - Value, 0, 1)
	end)

	ACF.AddInputAction("acf_gearbox", "Right Clutch", function(Entity, Value)
		if not Entity.DualClutch then return end

		Entity.RClutch = Clamp(1 - Value, 0, 1)
	end)

	ACF.AddInputAction("acf_gearbox", "Brake", function(Entity, Value)
		Entity.LBrake = Clamp(Value, 0, 10000)
		Entity.RBrake = Clamp(Value, 0, 10000)

		SetCanApplyBrakes(Entity)
	end)

	ACF.AddInputAction("acf_gearbox", "Left Brake", function(Entity, Value)
		if not Entity.DualClutch then return end

		Entity.LBrake = Clamp(Value, 0, 10000)

		SetCanApplyBrakes(Entity)
	end)

	ACF.AddInputAction("acf_gearbox", "Right Brake", function(Entity, Value)
		if not Entity.DualClutch then return end

		Entity.RBrake = Clamp(Value, 0, 10000)

		SetCanApplyBrakes(Entity)
	end)

	ACF.AddInputAction("acf_gearbox", "CVT Ratio", function(Entity, Value)
		if not Entity.CVT then return end

		if Entity.GearboxLegacyRatio and Value ~= 0 then Value = 1 / Value end
		Entity.CVTRatio = Value ~= 0 and Clamp(Value, ACF.MinCVTRatio, ACF.MaxCVTRatio) or Value
	end)

	ACF.AddInputAction("acf_gearbox", "Steer Rate", function(Entity, Value)
		if not Entity.DoubleDiff then return end

		Entity.SteerRate = Clamp(Value, -1, 1)
	end)

	ACF.AddInputAction("acf_gearbox", "Hold Gear", function(Entity, Value)
		if not Entity.Automatic then return end

		Entity.Hold = tobool(Value)
	end)

	ACF.AddInputAction("acf_gearbox", "Shift Speed Scale", function(Entity, Value)
		if not Entity.Automatic then return end

		Entity.ShiftScale = Clamp(Value, 0.1, 1.5)
	end)
end ----------------------------------------------------

do -- Gear Shifting ------------------------------------
	local Sounds = Utilities.Sounds

	-- Handles gearing for automatic gearboxes. 0 = Neutral, 1 = Drive, 2 = Reverse
	function ENT:ChangeDrive(Value)
		Value = Clamp(math.floor(Value), 0, 2)

		if self.Drive == Value then return end

		self.Drive = Value

		self:ChangeGear(Value == 2 and self.GearCount or Value)
	end

	function ENT:ChangeGear(Value)
		Value = Clamp(math.floor(Value), self.MinGear, self.GearCount)

		if self.Gear == Value then return end

		self.Gear           = Value
		self.InGear         = false
		self.GearRatio      = self.Gears[Value] * self.FinalDrive
		self.ChangeFinished = Clock.CurTime + self.SwitchTime

		local SoundPath  = self.SoundPath

		if SoundPath ~= "" then
			local Pitch = self.SoundPitch and Clamp(self.SoundPitch * 100, 0, 255) or 100
			local Volume = self.SoundVolume or 0.5

			Sounds.SendSound(self, SoundPath, 70, Pitch, Volume)
		end

		WireLib.TriggerOutput(self, "Current Gear", Value)

		local Ratio = ACF.ConvertGearRatio(self.GearRatio, self.GearboxLegacyRatio)
		WireLib.TriggerOutput(self, "Ratio", Ratio)
	end
end ----------------------------------------------------

do -- Movement -----------------------------------------
	local function GetRotationalInertia(Link, Wheel)
		local Phys = ENTITY.GetPhysicsObject(Wheel)
		if not Phys then return end

		local Inertia = PHYSOBJ.GetInertia(Phys)
		VECTOR.Mul(Inertia, Link.Axis)
		return VECTOR.Length(Inertia)
	end

	function ENT:Calc(InputRPM, InputInertia)
		local SelfTbl = self:GetTable()
		if SelfTbl.Disabled then return 0 end
		if SelfTbl.ACF.Health <= 0 then return 0 end -- Destroyed

		local Now = Clock.CurTime

		if SelfTbl.LastActive == Now then return SelfTbl.MeasuredRPM end

		if SelfTbl.ChangeFinished < Now then
			SelfTbl.InGear = true
		end

		-- Get the average inertia-weighted RPM from all engines this tick
		if SelfTbl.CalcTick == Now then
			local TotalInertia = SelfTbl.CalcInertia + InputInertia

			if TotalInertia > 0 then
				SelfTbl.CalcRPM = (SelfTbl.CalcRPM * SelfTbl.CalcInertia + InputRPM * InputInertia) / TotalInertia
			end

			SelfTbl.CalcInertia = TotalInertia
			return SelfTbl.MeasuredRPM
		end

		-- First Calc call this tick: seed the averager and compute fresh
		SelfTbl.CalcTick    = Now
		SelfTbl.CalcRPM     = InputRPM
		SelfTbl.CalcInertia = InputInertia

		local BoxPhys = ENTITY.GetPhysicsObject(ENTITY.GetAncestor(self))
		local Gear    = SelfTbl.Gear

		if SelfTbl.CVT and Gear == 1 then
			local Gears = SelfTbl.Gears

			if SelfTbl.CVTRatio > 0 then
				Gears[1] = SelfTbl.CVTRatio
			else
				local MinRPM  = SelfTbl.MinRPM
				Gears[1] = 1 / Clamp((InputRPM - MinRPM) / (SelfTbl.MaxRPM - MinRPM), 0.05, 1)
			end

			local GearRatio = Gears[1] * SelfTbl.FinalDrive
			SelfTbl.GearRatio = GearRatio

			if SelfTbl.LastRatio ~= GearRatio then
				SelfTbl.LastRatio = GearRatio
				local Ratio = ACF.ConvertGearRatio(GearRatio, SelfTbl.GearboxLegacyRatio)
				WireLib.TriggerOutput(self, "Ratio", Ratio)
			end
		end

		if SelfTbl.Automatic and SelfTbl.Drive == 1 and SelfTbl.InGear then
			local PhysVel = BoxPhys:GetVelocity():Length()

			if not SelfTbl.Hold and Gear ~= SelfTbl.MaxGear and PhysVel > (SelfTbl.ShiftPoints[Gear] * SelfTbl.ShiftScale) then
				self:ChangeGear(Gear + 1)
			elseif PhysVel < (SelfTbl.ShiftPoints[Gear - 1] * SelfTbl.ShiftScale) then
				self:ChangeGear(Gear - 1)
			end
		end

		local LClutch = SelfTbl.LClutch
		local RClutch = SelfTbl.RClutch
		local ChassisAV = GetChassisAngularVelocity(self)
		local GearRatio = SelfTbl.GearRatio

		if GearRatio == 0 then
			SelfTbl.TotalRatio        = 0
			SelfTbl.DownstreamInertia = 0
			SelfTbl.Load              = 0
			SelfTbl.MeasuredRPM       = 0
			SelfTbl.LeftRPM           = 0
			SelfTbl.RightRPM          = 0
			return 0
		end

		-- Inputs scaled for downstream (divide RPM, multiply inertia)
		local ScaledRPM     = InputRPM / GearRatio
		local ScaledInertia = InputInertia * GearRatio

		local DoubleDiff = SelfTbl.DoubleDiff
		local SteerRate  = SelfTbl.SteerRate

		-- DoubleDiff steering
		if DoubleDiff then
			local Rate = SteerRate * 2
			SelfTbl.LMult = min(0, Rate) + 1
			SelfTbl.RMult = -max(0, Rate) + 1
		else
			SelfTbl.LMult, SelfTbl.RMult = 1, 1
		end

		local MeasuredRPMSum = 0
		local MeasuredCount = 0
		local DownstreamInertia = 0
		local TotalRatioSum = 0
		-- Per-side RPM tracking, future work for LSD/locked diffs. 
		local LeftRPMSum, LeftCount = 0, 0
		local RightRPMSum, RightCount = 0, 0

		-- Downstream gearboxes
		for Gearbox, _ in pairs(SelfTbl.GearboxOut) do
			local EntTbl = ENTITY.GetTable(Gearbox)

			if not Gearbox.Disabled then
				Gearbox:Calc(ScaledRPM, ScaledInertia) -- measurement pull, just to update gearboxes downstream
			end

			MeasuredRPMSum    = MeasuredRPMSum + (EntTbl.MeasuredRPM or ScaledRPM) * GearRatio
			MeasuredCount     = MeasuredCount + 1
			DownstreamInertia = DownstreamInertia + (EntTbl.DownstreamInertia or 0)
			TotalRatioSum     = TotalRatioSum + abs(GearRatio) * (EntTbl.TotalRatio or 1)
		end

		-- Wheels
		for Wheel, Link in pairs(SelfTbl.Wheels) do
			local WheelRPM = CalcWheel(self, Link, Wheel, ChassisAV)
			local WheelInertia = GetRotationalInertia(Link, Wheel)
			Link.CachedInertia = WheelInertia

			MeasuredRPMSum    = MeasuredRPMSum + WheelRPM
			MeasuredCount     = MeasuredCount + 1
			DownstreamInertia = DownstreamInertia + WheelInertia

			if Link.Side == 0 then
				LeftRPMSum = LeftRPMSum + WheelRPM
				LeftCount  = LeftCount + 1
			else
				RightRPMSum = RightRPMSum + WheelRPM
				RightCount  = RightCount + 1
			end
		end

		-- Effectors
		for Effector in pairs(SelfTbl.Effectors) do
			local EntTbl = ENTITY.GetTable(Effector)

			if not Effector.Disabled then
				Effector:Calc(ScaledRPM, ScaledInertia)
			end

			DownstreamInertia = DownstreamInertia + (EntTbl.DownstreamInertia or 0)
		end

		SelfTbl.MeasuredRPM = MeasuredCount > 0 and (MeasuredRPMSum / MeasuredCount) or InputRPM
		SelfTbl.LeftRPM  = LeftCount  > 0 and (LeftRPMSum  / LeftCount)  or SelfTbl.MeasuredRPM
		SelfTbl.RightRPM = RightCount > 0 and (RightRPMSum / RightCount) or SelfTbl.MeasuredRPM
		SelfTbl.DownstreamInertia = DownstreamInertia
		SelfTbl.TotalRatio = abs(GearRatio) * max(TotalRatioSum, 1)
		SelfTbl.Load = (LClutch + RClutch) * 0.5

		self:UpdateOverlay()

		return SelfTbl.MeasuredRPM
	end

	function ENT:DistributeTorque(Torque, DeltaTime, MassRatio, FlyRPM)
		local SelfTbl = ENTITY.GetTable(self)
		if SelfTbl.Disabled or Torque == 0 then return end

		local GearRatio = SelfTbl.GearRatio
		if GearRatio == 0 then return end

		-- Internal torque loss from damage
		local Health = SelfTbl.ACF.Health
		local MaxHP  = SelfTbl.ACF.MaxHealth
		local Loss   = Clamp(((1 - 0.4) / 0.5) * ((Health / MaxHP) - 1) + 1, 0.4, 1) -- Internal torque loss from damage

		SelfTbl.Loss = Loss

		-- Automatic torque-converter slip penalty
		local Slop = SelfTbl.Automatic and 0.9 or 1.0
		-- Reflect through this stage's own ratio, same direction gearboxes already scale torque.
		-- Capacity ceiling: this gearbox's own rated torque, a gearbox cannot transmit more than it's rated for, even if the engine sends more.
		local StageTorque = Clamp(Torque * GearRatio * Loss * Slop, -SelfTbl.MaxTorque, SelfTbl.MaxTorque)

		local TotalInertia = SelfTbl.DownstreamInertia
		if TotalInertia <= 0 then return end

		local LClutch = SelfTbl.LClutch
		local RClutch = SelfTbl.RClutch
		local LMult = SelfTbl.LMult or 1
		local RMult = SelfTbl.RMult or 1
		local DoubleDiff = SelfTbl.DoubleDiff
		local SteerRate = SelfTbl.SteerRate

		local ReactTq = 0
		local Braking = SelfTbl.Braking
		local DriverCrewMod = SelfTbl.DriverCrewMod or 1

		-- Direction forwarded to effectors so reversible props work
		local Direction = SelfTbl.Drive == 2 and -1 or 1

		-- Transfer torque to our entities
		-- Downstream gearboxes, split by inertia share; aka, a branch with more reflected inertia
		-- (a heavier / more-loaded sub-chain) gets proportionally more of the available torque.
		for Ent, Link in pairs(SelfTbl.GearboxOut) do
			local Clutch = Link.Side == 0 and LClutch or RClutch

			if not Ent.Disabled and Clutch > 0 then
				local EntTbl = ENTITY.GetTable(Ent)
				local Share = (EntTbl.DownstreamInertia or 0) / TotalInertia

				Link:TransferGearbox(Ent, StageTorque * Share * Clutch, DeltaTime, MassRatio, FlyRPM)
			end
		end

		-- Effectors
		for Effector, Link in pairs(SelfTbl.Effectors) do
			local Clutch = Link.Side == 0 and LClutch or RClutch

			if not Effector.Disabled and Clutch > 0 then
				local EntTbl = ENTITY.GetTable(Effector)
				local Share = (EntTbl.DownstreamInertia or 0) / TotalInertia

				Link:TransferEffector(Effector, StageTorque * Share * Clutch * DriverCrewMod, DeltaTime, MassRatio, FlyRPM, Direction)
			end
		end

		-- Wheels
		for Wheel, Link in pairs(SelfTbl.Wheels) do
			local Clutch = Link.Side == 0 and LClutch or RClutch

			-- Check also that the gearbox is not braking
			if SelfTbl.InGear and Clutch > 0 and (not Braking or not Link.IsBraking) then
				local WheelInertia = Link.CachedInertia or GetRotationalInertia(Link, Wheel)
				local Share = WheelInertia / TotalInertia
				local Multiplier = 1

				if DoubleDiff and SteerRate ~= 0 then
					Multiplier = Link.Side == 0 and LMult or RMult
				end

				local WheelTorque = StageTorque * Share * Clutch * Multiplier * DriverCrewMod

				Link:TransferWheel(Wheel, WheelTorque, DeltaTime)
				ReactTq = ReactTq + WheelTorque
			end

			WireLib.TriggerOutput(self, "Output Torque", ReactTq)
			SelfTbl.TorqueOutput = ReactTq -- For the overlay
		end

		-- Chassis reaction torque: Newton's third law makes the body twist opposite to the drive direction when power is applied
		if ReactTq ~= 0 then
			local BoxPhys = ENTITY.GetPhysicsObject(ENTITY.GetAncestor(self))

			if IsPhysObjValid(BoxPhys) then
				local RightDir = ENTITY.GetRight(self)

				VECTOR.Mul(RightDir, ReactTq * MassRatio)
				PHYSOBJ.ApplyTorqueCenter(BoxPhys, RightDir)
			end
		end

		SelfTbl.BrakeTick = Clock.CurTime
		self:ApplyBrakes()
		self:UpdateOverlay()
	end

	function ENT:Act(Torque, DeltaTime, MassRatio, FlyRPM)
		local SelfTbl = ENTITY.GetTable(self)
		if SelfTbl.Disabled then return end
		if SelfTbl.ACF.Health <= 0 then return end -- Destroyed

		if Torque == 0 then
			SelfTbl.LastActive = Clock.CurTime
			return
		end

		local EngineCount = table.Count(SelfTbl.Engines)
		local GearboxCount = table.Count(SelfTbl.GearboxIn)

		-- Single-engine fast path: distribute immediately, no deferred timer
		if EngineCount + GearboxCount <= 1 then
			self:DistributeTorque(Torque, DeltaTime, MassRatio, FlyRPM)
			return
		end

		-- Multiple engines: Accumulates their torque and then distribute
		local Now = Clock.CurTime

		if SelfTbl.ActTick ~= Now then
			SelfTbl.ActTick        = Now
			SelfTbl.AccumTorque    = 0
			SelfTbl.ActDt          = DeltaTime
			SelfTbl.ActMassRatio   = MassRatio
			SelfTbl.ActFlyRPM      = FlyRPM
			SelfTbl.ActDistributed = false
		end

		SelfTbl.AccumTorque = SelfTbl.AccumTorque + Torque

		if not SelfTbl.ActDistributed then
			SelfTbl.ActDistributed = true
			-- Deferred so all engines complete their Act calls before distribution
			timer.Simple(0, function()
				if IsEntityValid(self) then
					self:DistributeTorque(SelfTbl.AccumTorque, SelfTbl.ActDt, SelfTbl.ActMassRatio, SelfTbl.ActFlyRPM)
				end
			end)
		end

		SelfTbl.LastActive = Clock.CurTime
	end
end ----------------------------------------------------

do -- Braking ------------------------------------------
	local function BrakeWheel(Link, Wheel, Brake)
		local Phys      = ENTITY.GetPhysicsObject(Wheel)
		local AntiSpazz = 1

		if not PHYSOBJ.IsMotionEnabled(Phys) then return end -- skipping entirely if its frozen

		if Brake > 100 then
			local Overshot = abs(Link.LastVel - Link.Vel) > abs(Link.LastVel) -- Overshot the brakes last tick?
			local Rate     = Overshot and 0.2 or 0.002 -- If we overshot, cut back agressively, if we didn't, add more brakes slowly

			Link.AntiSpazz = (1 - Rate) * Link.AntiSpazz + (Overshot and 0 or Rate) -- Low pass filter on the antispazz

			AntiSpazz = min(Link.AntiSpazz * 10000 / Brake, 1) -- Anti-spazz relative to brake power
		end

		Link.LastVel = Link.Vel

		-- creates negative copy, then performs in-place multiplication to not create as much garbage
		local AngleVelocity = -Link.Axis
		VECTOR.Mul(AngleVelocity, Link.Vel)
		VECTOR.Mul(AngleVelocity, AntiSpazz)
		VECTOR.Mul(AngleVelocity, Brake)
		VECTOR.Mul(AngleVelocity, 0.01)

		PHYSOBJ.AddAngleVelocity(Phys, AngleVelocity)
	end

	function ENT_ApplyBrakes(self) -- This is just for brakes
		local SelfTbl = ENTITY.GetTable(self)

		if SelfTbl.Disabled then return end -- Illegal brakes man
		if not SelfTbl.Braking then return end -- Kills the whole thing if its not supposed to be running
		if not next(SelfTbl.Wheels) then return end -- No brakes for the non-wheel users
		if SelfTbl.LastBrake == Clock.CurTime then return end -- Don't run this twice in a tick

		local BoxPhys = ENTITY.GetPhysicsObject(ENTITY.GetAncestor(self))
		if not IsPhysObjValid(BoxPhys) then return end -- Fixes an issue I had where deleting a contraption while driving it threw an error

		local SelfWorld = PHYSOBJ.LocalToWorldVector(BoxPhys, PHYSOBJ.GetAngleVelocity(BoxPhys))
		local DeltaTime = Clock.DeltaTime

		for Wheel, Link in pairs(SelfTbl.Wheels) do
			local Brake = Link.Side == 0 and SelfTbl.LBrake or SelfTbl.RBrake

			if Brake > 0 then -- regular ol braking
				Link.IsBraking = true
				CalcWheel(self, Link, Wheel, SelfWorld) -- Updating the link velocity
				BrakeWheel(Link, Wheel, Brake, DeltaTime)
			else
				Link.IsBraking = false
			end
		end

		SelfTbl.LastBrake = Clock.CurTime

		timer.Simple(DeltaTime, function()
			if not IsEntityValid(self) then return end

			ENT_ApplyBrakes(self)
		end)
	end
	ENT.ApplyBrakes = ENT_ApplyBrakes
end ----------------------------------------------------
