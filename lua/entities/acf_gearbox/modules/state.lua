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

local function CalcWheel(Entity, Link, Wheel, SelfWorld)
	local EntityTable = ENTITY.GetTable(Entity)

	local WheelPhys   = ENTITY.GetPhysicsObject(Wheel)
	local VelDiff     = PHYSOBJ.LocalToWorldVector(WheelPhys, PHYSOBJ.GetAngleVelocity(WheelPhys))
	VECTOR.Sub(VelDiff, SelfWorld)

	local BaseRPM     = VECTOR.Dot(VelDiff, PHYSOBJ.LocalToWorldVector(WheelPhys, Link.Axis))
	local GearRatio   = EntityTable.GearRatio
	Link.Vel = BaseRPM

	if GearRatio == 0 then return 0 end

	-- Reported BaseRPM is in angle per second and in the wrong direction, so we convert and add the gear ratio
	return BaseRPM * GearRatio / -6
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
	local deg         = math.deg

	function ENT:Calc(InputRPM, InputInertia)
		local SelfTbl = self:GetTable()
		if SelfTbl.Disabled then return 0 end
		if SelfTbl.ACF.Health <= 0 then return 0 end -- Destroyed
		if SelfTbl.LastActive == Clock.CurTime then return SelfTbl.TorqueOutput end

		if SelfTbl.ChangeFinished < Clock.CurTime then
			SelfTbl.InGear = true
		end

		local BoxPhys = self:GetAncestor():GetPhysicsObject()
		local SelfWorld = BoxPhys:LocalToWorldVector(BoxPhys:GetAngleVelocity())
		local Gear = SelfTbl.Gear

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

		local TorqueOutput = 0
		local TotalReqTq = 0
		local LClutch = SelfTbl.LClutch
		local RClutch = SelfTbl.RClutch
		local GearRatio = SelfTbl.GearRatio

		if GearRatio == 0 then return 0 end

		for Ent, Link in pairs(SelfTbl.GearboxOut) do
			local Clutch = Link.Side == 0 and LClutch or RClutch

			Link.ReqTq = 0

			if not Ent.Disabled then
				local Inertia = 0

				if GearRatio ~= 0 then
					Inertia = InputInertia * GearRatio
				end

				Link.ReqTq = abs(Ent:Calc(InputRPM / GearRatio, Inertia) / GearRatio) * Clutch
				TotalReqTq = TotalReqTq + abs(Link.ReqTq)
			end
		end

		local DoubleDiff = SelfTbl.DoubleDiff
		local SteerRate  = SelfTbl.SteerRate

		for Wheel, Link in pairs(SelfTbl.Wheels) do
			Link.ReqTq = 0

			if GearRatio ~= 0 then
				local RPM = CalcWheel(self, Link, Wheel, SelfWorld)
				local Clutch = Link.Side == 0 and LClutch or RClutch
				local OnRPM = ((InputRPM > 0 and RPM < InputRPM) or (InputRPM < 0 and RPM > InputRPM))

				if Clutch > 0 and OnRPM then
					local Multiplier = 1

					if DoubleDiff and SteerRate ~= 0 then
						local Rate = SteerRate * 2

						-- this actually controls the RPM of the wheels, so the steering rate is correct
						if Link.Side == 0 then
							Multiplier = min(0, Rate) + 1
						else
							Multiplier = -max(0, Rate) + 1
						end
					end

					if abs(InputRPM * Multiplier) > abs(RPM) then -- removing this check causes the wheels to constantly invert their rotation
						Link.ReqTq = (InputRPM * Multiplier - RPM) * InputInertia * Clutch
						TotalReqTq = TotalReqTq + abs(Link.ReqTq)
					end
				end
			end
		end

		for Effector, Link in pairs(SelfTbl.Effectors) do
			local Clutch = Link.Side == 0 and LClutch or RClutch

			Link.ReqTq = 0

			if not Effector.Disabled then
				local Inertia = 0

				if GearRatio ~= 0 then
					Inertia = InputInertia * GearRatio
				end

				Link.ReqTq = abs(Effector:Calc(InputRPM / GearRatio, Inertia) / GearRatio) * Clutch
				TotalReqTq = TotalReqTq + abs(Link.ReqTq)
			end
		end

		SelfTbl.TotalReqTq = TotalReqTq
		TorqueOutput = min(TotalReqTq, SelfTbl.MaxTorque)
		SelfTbl.TorqueOutput = TorqueOutput

		self:UpdateOverlay()

		return TorqueOutput
	end

	function ENT:Act(Torque, DeltaTime, MassRatio, FlyRPM)
		local SelfTbl = ENTITY.GetTable(self)
		if SelfTbl.Disabled then return end
		if SelfTbl.ACF.Health <= 0 then return end -- Destroyed

		if Torque == 0 then
			SelfTbl.LastActive = Clock.CurTime
			return
		end

		local Loss = Clamp(((1 - 0.4) / 0.5) * ((SelfTbl.ACF.Health / SelfTbl.ACF.MaxHealth) - 1) + 1, 0.4, 1) -- Internal torque loss from damage
		local Slop = SelfTbl.Automatic and 0.9 or 1 -- Internal torque loss from inefficiency
		local ReactTq = 0
		-- Calculate the ratio of total requested torque versus what's available, and then multiply it by the current gear ratio
		local AvailTq = 0
		local GearRatio = SelfTbl.GearRatio

		if Torque ~= 0 and GearRatio ~= 0 then
			AvailTq = min(abs(Torque) / SelfTbl.TotalReqTq, 1) * GearRatio * -(-Torque / abs(Torque)) * Loss * Slop
		end

		for Ent, Link in pairs(SelfTbl.GearboxOut) do
			Link:TransferGearbox(Ent, Link.ReqTq * AvailTq, DeltaTime, MassRatio, FlyRPM)
			--Ent:Act(Link.ReqTq * AvailTq, DeltaTime, MassRatio)
		end

		local Braking = SelfTbl.Braking
		local DriverCrewMod = SelfTbl.DriverCrewMod or 1

		for Ent, Link in pairs(SelfTbl.Wheels) do
			-- If the gearbox is braking, always
			if not Braking or not Link.IsBraking then
				-- Applied here, not to AvailTq, so gearbox-to-gearbox transfer stays unaffected
				local WheelTorque = Link.ReqTq * AvailTq * DriverCrewMod
				ReactTq = ReactTq + WheelTorque

				Link:TransferWheel(Ent, WheelTorque, DeltaTime)
				--ActWheel(Link, Ent, WheelTorque, DeltaTime)
			end
		end

		if ReactTq ~= 0 then
			local BoxPhys = ENTITY.GetPhysicsObject(ENTITY.GetAncestor(self))

			if IsPhysObjValid(BoxPhys) then
				local RightDir = ENTITY.GetRight(self)
				VECTOR.Mul(RightDir, Clamp(2 * deg(ReactTq * MassRatio) * DeltaTime, -500000, 500000))
				PHYSOBJ.ApplyTorqueCenter(BoxPhys, RightDir)
			end
		end

		for Effector, Link in pairs(SelfTbl.Effectors) do
			Link:TransferEffector(Effector, Link.ReqTq * AvailTq * DriverCrewMod, DeltaTime, MassRatio, FlyRPM)
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
