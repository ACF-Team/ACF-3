local ACF      = ACF
local Classes  = ACF.Classes
local InchToMm = ACF.InchToMm

--[[
	For the purposes of calculations and customization, all turrets are considered to be gear-driven

	https://www.balnex.pl/uploads/file/download/ksiazka-techniczna-lozyska-wiencowe.pdf - Has info on slewing rings and applying power to them, pg 16-17

	https://qcbslewingrings.com/product-category/geared-motors/ - Has more PDFs, including the hydraulic one below
	https://qcbslewingrings.com/wp-content/uploads/2021/01/E1-SPOOLVALVE.pdf - Has info on hydraulic motors
]]

-- Performance optimizations
local ENTITY = FindMetaTable("Entity")
local ANGLE  = FindMetaTable("Angle")
local CachedTurretAngle  = Angle(0, 0, 0)

local math_min = math.min
local math_max = math.max

local function ClampAngleInPlace(A, minp, miny, minr, maxp, maxy, maxr)
	local p, y, r = ANGLE.Unpack(A)

	p = math_min(math_max(p, minp), maxp)
	y = math_min(math_max(y, miny), maxy)
	r = math_min(math_max(r, minr), maxr)

	ANGLE.SetUnpacked(A, p, y, r)

	return A
end

local function WillUseSmallModel(Size) return Size <= 12.5 end

Classes.DefineClass("ACF.Turrets.Component", function() end)

do	-- Turret drives
	Classes.DefineClass("ACF.Turrets.Drive", "ACF.Turrets.Component", function()
		CLASS.Name        = "Turrets"
		CLASS.ID          = "1-Turret"
		CLASS.SpawnModel  = "models/acf/core/t_ring.mdl"
		CLASS.Description = "#acf.descs.turrets"
		CLASS.Entity      = "acf_turret"

		CLASS.WillUseSmallModel = WillUseSmallModel

		CLASS.GetMass = function(Data, Size)
			return math.Round(math.max(Data.Mass * (Size / Data.Size.Base), 5) ^ 1.5, 1)
		end

		CLASS.GetMaxMass = function(Data, Size)
			local SizePerc = (Size - Data.Size.Min) / (Data.Size.Max - Data.Size.Min)
			return math.Round(((Data.MassLimit.Min * (1 - SizePerc)) + (Data.MassLimit.Max * SizePerc)) ^ 2, 1)
		end

		CLASS.GetTeethCount = function(Data, Size)
			local SizePerc = (Size - Data.Size.Min) / (Data.Size.Max - Data.Size.Min)
			return math.Round((Data.Teeth.Min * (1 - SizePerc)) + (Data.Teeth.Max * SizePerc))
		end

		CLASS.GetRingHeight = function(TurretData, Size)
			local RingHeight = math.max(Size * TurretData.Ratio, 4)

			if (TurretData.Type == "Turret-H") and WillUseSmallModel(Size) then
				return 12 -- sticc
			end

			return RingHeight
		end

		CLASS.HandGear = { -- Fallback incase a motor is unavailable
			Teeth      = 12, -- For use in calculating end effective speed of a turret
			Speed      = 420, -- deg/s
			Torque     = 10, -- 0.1m * 100N * sin(90), torque to turn a small handwheel 90 degrees
			Efficiency = 0.99, -- Gearbox efficiency, won't be too punishing for handcrank
			Accel      = 4,
			Sound      = "acf_base/fx/turret_handcrank.wav",
		}

		--[[
			TurretData should include:
				- TotalMass	: All of the mass (kg) on the turret
				- LocalCoM	: Local vector (gmu) of center of mass
				- RingSize	: Diameter of ring (gmu)
				- RingHeight: Height of ring (gmu)
				- Teeth		: Number of teeth of the turret ring
				- Tilt		: 1 - On axis, 0 - Off axis, scales between

			PowerData should include: (look at HandGear above for example, that can be directly fed to this function)
				- Teeth		: Number of teeth of gear on input source
				- Speed		: Maximum speed of input source (deg/s)
				- Torque	: Maximum torque of input source (Nm)
				- Efficiency: Efficiency of the gearbox
				- Accel		: Time, in seconds, to reach Speed
		]]

		CLASS.CalcSpeed = function(TurretData, PowerData) -- Called whenever something on the turret changes, returns resistance from mass on the ring (overall, not inertial)
			local Teeth     = TurretData.Teeth
			local GearRatio = PowerData.Teeth / Teeth
			local TopSpeed  = GearRatio * (PowerData.Speed / 6) -- Converting deg/s to RPM, and adjusting by gear ratio
			local MaxPower  = ((PowerData.Torque / GearRatio) * TopSpeed) / (9550 * PowerData.Efficiency)
			local Diameter  = (TurretData.RingSize * InchToMm) -- Used for some of the formulas from the referenced page, needs to be in mm
			local CoMDistance     = (TurretData.LocalCoM * Vector(1, 1, 0)):Length() * (InchToMm / 1000) -- (Lateral) Distance of center of mass from center of axis, in meters for calculation
			local OffBaseDistance = math.max(CoMDistance - math.max(CoMDistance - (Diameter / 2), 0), 0)
			local OverweightMod   = 1

			if TurretData.TotalMass > TurretData.MaxMass then
				OverweightMod = math.max(0, 1 - (((TurretData.TotalMass - TurretData.MaxMass) / TurretData.MaxMass) / 2))
			end

			-- Slewing ring friction moment caused by load (kNm)
			-- 1kg weight (mass * gravity) is about 9.81N
			-- 0.006 = fric coefficient for ball slewing rings
			-- 0.004 = fric coefficient for crossed ball slewing rings
			-- k = 4.4 = coefficient of load accommodation for ball slewing rings
			local Weight = (TurretData.TotalMass * 9.81) / 1000
			local Mz     = 0 -- Nm resistance to torque

			local Mk, Fa, Fr

			if TurretData.TurretClass == "Turret-H" then
				Mk = Weight * OffBaseDistance -- Sum of tilting moments (kNm) (off balance load)
				Fa = Weight * math.Clamp(1 - (CoMDistance * 2), 0, 1) * TurretData.Tilt -- Sum of axial dynamic forces (kN) (on balance load)
				Fr = Weight * math.Clamp(1 - (CoMDistance * 2), 0, 1) * (1 - TurretData.Tilt) * 1.73 -- Sum of radial dynamic forces (kN), 1.73 is the coefficient for prevailing load, which is already determined by CoMDistance and Tilt
				Mz = 0.004 * 4.4 * (((Mk * 1000) / Diameter) +  (Fa / 4.4) + (Fr / 2)) * (Diameter / 2000)
			else
				local ZDist = TurretData.LocalCoM.z * (InchToMm / 1000)

				OffBaseDistance = math.max(ZDist - math.max(ZDist - ((TurretData.RingHeight * InchToMm) / 2), 0), 0)
				Mk = Weight * OffBaseDistance -- Sum of tilting moments (kNm) (off balance load)
				Fr = Weight * math.Clamp(1 - (CoMDistance * 2), 0, 1) -- Sum of radial dynamic forces (kN), included for vertical turret drives
				Mz = 0.004 * 4.4 * (((Mk * 1000) / Diameter) + (Fr / 2)) * (Diameter / 2000)
			end

			-- 9.55 is 1 rad/s to RPM
			-- Required power to rotate at full speed
			-- With this we can lower maximum attainable speed
			local ReqConstantPower = (Mz * TopSpeed) / (9.55 * PowerData.Efficiency * OverweightMod)

			if (math.max(1, ReqConstantPower) / math.max(MaxPower, 1)) > 1 then return {SlewAccel = 0, MaxSlewRate = 0} end -- Too heavy to rotate, so we'll just stop here

			local FinalTopSpeed = TopSpeed * math.min(1, MaxPower / ReqConstantPower) * 6 -- converting back to deg/s

			-- Moment from acceleration of rotating mass (kNm)
			local RotInertia  = 0.01 * TurretData.TotalMass * (CoMDistance ^ 2)
			local LoadInertia = RotInertia * (1 / ((1 / GearRatio) ^ 2))
			local Accel       = (math.pi * FinalTopSpeed) / (30 * PowerData.Accel)
			local Mg          = LoadInertia * Accel

			-- 9.55 is 1 rad/s to RPM
			local ReqAccelPower = ((Mg + Mz) * Accel) / (9.55 * PowerData.Efficiency)

			-- Kind of arbitrary, needed it to stop at some point
			if (math.max(1, ReqAccelPower) / math.max(1, Accel)) > 5 then return {SlewAccel = 0, MaxSlewRate = 0} end -- Too heavy to accelerate, so we'll just stop here

			local FinalAccel = Accel * math.Clamp(MaxPower / ReqAccelPower, 0, 1) * 6 -- converting back to deg/s^2

			return {SlewAccel = FinalAccel, MaxSlewRate = FinalTopSpeed, MotorMaxSpeed = TopSpeed * 6, MotorGearRatio = GearRatio, EffortScale = math.min(1, 1 / (MaxPower / ReqConstantPower))}
		end
	end)

	do	-- Horizontal turret component
		Classes.DefineClass("ACF.Turrets.Drive.Horizontal", "ACF.Turrets.Drive", function()
			CLASS.Name        = "Horizontal Turret"
			CLASS.ID          = "Turret-H"
			CLASS.Description  = "#acf.descs.turrets.horizontal"
			CLASS.Model       = "models/acf/core/t_ring.mdl"
			CLASS.ModelSmall  = "models/holograms/cylinder.mdl" -- To be used for diameters <= 12.5u, for RWS or other small turrets
			CLASS.Mass        = 30 -- At default size, this is the mass of the turret ring. Will scale up/down with diameter difference

			CLASS.Size = {
				Base  = 60,	-- The default size for the menu
				Min   = 2,	-- To accomodate itty bitty RWS turrets
				Max   = 512,	-- To accomodate ship turrets
				Ratio = 0.1	-- Height modifier for total size
			}

			CLASS.Teeth = {		-- Used to give a final teeth count with size
				Min = 12,
				Max = 2304
			}

			CLASS.Armor = {
				Min = 2.5,
				Max = 80
			}

			CLASS.MassLimit = {
				Min = 16,
				Max = 1024
			}

			CLASS.SetupInputs = function(_, List)
				local Count = #List

				List[Count + 1] = "Bearing (Local degrees from home angle)"
			end

			CLASS.SlewFuncs = {
				GetStab = function(Turret)
					local TurretTbl = ENTITY.GetTable(Turret)

					if (not (TurretTbl.Stabilized and TurretTbl.Active)) or (TurretTbl.Manual == true) then return 0 end
					local AngDiff = ENTITY.WorldToLocalAngles(TurretTbl.Rotator, TurretTbl.LastRotatorAngle)
					local _, Yaw  = ANGLE.Unpack(AngDiff)
					return (Yaw * TurretTbl.StabilizeAmount) or 0
				end,

				GetTargetBearing = function(Turret, StabAmt)
					local TurretTbl = ENTITY.GetTable(Turret)
					local Rotator = TurretTbl.Rotator

					if TurretTbl.HasArc then
						if TurretTbl.Manual then
							ANGLE.SetUnpacked(CachedTurretAngle, 0, -math.Clamp(TurretTbl.DesiredDeg, TurretTbl.MinDeg, TurretTbl.MaxDeg), 0)
							local _, Yaw = ANGLE.Unpack(ENTITY.WorldToLocalAngles(Rotator, ENTITY.LocalToWorldAngles(Turret, CachedTurretAngle)))
							return Yaw
						else
							local AngDiff = ENTITY.WorldToLocalAngles(Rotator, TurretTbl.LastRotatorAngle)
							local LocalDesiredAngle = ENTITY.WorldToLocalAngles(Turret, TurretTbl.DesiredAngle)
							local ADPitch, ADYaw, ADRoll = ANGLE.Unpack(AngDiff)
							ANGLE.SetUnpacked(CachedTurretAngle, -ADPitch, StabAmt - ADYaw, -ADRoll)
							ANGLE.Sub(LocalDesiredAngle, CachedTurretAngle)
							LocalDesiredAngle = ClampAngleInPlace(LocalDesiredAngle, 0, -TurretTbl.MaxDeg, 0, 0, -TurretTbl.MinDeg, 0)

							local _, Yaw = ANGLE.Unpack(ENTITY.WorldToLocalAngles(Rotator, ENTITY.LocalToWorldAngles(Turret, LocalDesiredAngle)))
							return Yaw
						end
					else
						local AngDiff = ENTITY.WorldToLocalAngles(Rotator, TurretTbl.LastRotatorAngle)
						local AngleRet
						if TurretTbl.Manual then
							AngleRet = ENTITY.WorldToLocalAngles(Rotator, ENTITY.LocalToWorldAngles(Turret, Angle(0, -TurretTbl.DesiredDeg, 0)))
							local _, Yaw = ANGLE.Unpack(AngleRet)
							return Yaw
						else
							ANGLE.SetUnpacked(CachedTurretAngle, ANGLE.Unpack(TurretTbl.DesiredAngle))
							ANGLE.Add(CachedTurretAngle, AngDiff)
							AngleRet = ENTITY.WorldToLocalAngles(Rotator, CachedTurretAngle)
							local _, Yaw = ANGLE.Unpack(AngleRet)
							Yaw = Yaw - StabAmt
							return Yaw
						end
					end
				end,

				GetWorldTarget = function(Turret)
					local SelfTbl = ENTITY.GetTable(Turret)
					if SelfTbl.Manual then
						ANGLE.SetUnpacked(CachedTurretAngle, 0, SelfTbl.DesiredDeg, 0)
						return ENTITY.LocalToWorldAngles(Turret, CachedTurretAngle)
					else
						return ENTITY.LocalToWorldAngles(Turret, ENTITY.WorldToLocalAngles(Turret, SelfTbl.DesiredAngle))
					end
				end,

				SetRotatorAngle = function(Turret, Rotator)
					ANGLE.SetUnpacked(CachedTurretAngle, 0, Turret.CurrentAngle, 0)
					ENTITY.SetAngles(Rotator, ENTITY.LocalToWorldAngles(Turret, CachedTurretAngle))
				end
			}
		end)
	end

	do	-- Vertical turret component
		Classes.DefineClass("ACF.Turrets.Drive.Vertical", "ACF.Turrets.Drive", function()
			CLASS.Name        = "Vertical Turret"
			CLASS.ID          = "Turret-V"
			CLASS.Description  = "#acf.descs.turrets.vertical"
			CLASS.Model       = "models/acf/core/t_trun.mdl"
			CLASS.Mass        = 24 -- At default size, this is the mass of the turret ring. Will scale up/down with diameter difference

			CLASS.Preview = {
				FOV = 105,
			}

			CLASS.Size = {
				Base  = 12,	-- The default size for the menu
				Min   = 4,	-- To accomodate itty bitty RWS turrets
				Max   = 48,	-- To accomodate ship turrets
				Ratio = 1	-- Height modifier for total size
			}

			CLASS.Teeth = {		-- Used to give a final teeth count with size
				Min = 8,
				Max = 768
			}

			CLASS.Armor = {
				Min = 5,
				Max = 30
			}

			CLASS.MassLimit = {
				Min = 16,
				Max = 256
			}

			CLASS.SetupInputs = function(_, List)
				local Count = #List

				List[Count + 1] = "Elevation (Local degrees from home angle)"
			end

			CLASS.SlewFuncs = {
				GetStab = function(Turret)
					local TurretTbl = ENTITY.GetTable(Turret)

					if (not (TurretTbl.Stabilized and TurretTbl.Active)) or (TurretTbl.Manual == true) then return 0 end
					local AngDiff = ENTITY.WorldToLocalAngles(TurretTbl.Rotator, TurretTbl.LastRotatorAngle)
					local Pitch   = ANGLE.Unpack(AngDiff)
					return (Pitch * TurretTbl.StabilizeAmount) or 0
				end,

				GetTargetBearing = function(Turret, StabAmt)
					local TurretTbl = ENTITY.GetTable(Turret)
					local Rotator = TurretTbl.Rotator

					if TurretTbl.HasArc then
						if TurretTbl.Manual then
							ANGLE.SetUnpacked(CachedTurretAngle, -math.Clamp(TurretTbl.DesiredDeg, TurretTbl.MinDeg, TurretTbl.MaxDeg), 0, 0)
							local Pitch = ANGLE.Unpack(ENTITY.WorldToLocalAngles(Rotator, ENTITY.LocalToWorldAngles(Turret, CachedTurretAngle)))
							return Pitch
						else
							local LocalDesiredAngle = ENTITY.WorldToLocalAngles(Turret, TurretTbl.DesiredAngle)
							ANGLE.SetUnpacked(CachedTurretAngle, StabAmt, 0, 0)
							ANGLE.Sub(LocalDesiredAngle, CachedTurretAngle)
							local LocalDesiredAngle = ClampAngleInPlace(LocalDesiredAngle, -TurretTbl.MaxDeg, 0, 0, -TurretTbl.MinDeg, 0, 0)

							local Pitch = ANGLE.Unpack(ENTITY.WorldToLocalAngles(Rotator, ENTITY.LocalToWorldAngles(Turret, LocalDesiredAngle)))
							return Pitch
						end
					elseif TurretTbl.Manual then
						ANGLE.SetUnpacked(CachedTurretAngle, -TurretTbl.DesiredDeg, 0, 0)
						local Pitch = ANGLE.Unpack(ENTITY.WorldToLocalAngles(Rotator, ENTITY.LocalToWorldAngles(Turret, CachedTurretAngle)))
						return Pitch
					else
						local Pitch = ANGLE.Unpack(ENTITY.WorldToLocalAngles(Rotator, TurretTbl.DesiredAngle))
						return Pitch - StabAmt
					end
				end,

				GetWorldTarget = function(Turret)
					local SelfTbl = ENTITY.GetTable(Turret)
					if SelfTbl.Manual then
						ANGLE.SetUnpacked(CachedTurretAngle, SelfTbl.DesiredDeg, 0, 0)
						return ENTITY.LocalToWorldAngles(Turret, CachedTurretAngle)
					else
						return ENTITY.LocalToWorldAngles(Turret, ENTITY.WorldToLocalAngles(Turret, SelfTbl.DesiredAngle))
					end
				end,

				SetRotatorAngle = function(Turret, Rotator)
					ANGLE.SetUnpacked(CachedTurretAngle, Turret.CurrentAngle, 0, 0)
					ENTITY.SetAngles(Rotator, ENTITY.LocalToWorldAngles(Turret, CachedTurretAngle))
				end
			}
		end)
	end
end

do	-- Turret motors
	Classes.DefineClass("ACF.Turrets.Motor", "ACF.Turrets.Component", function()
		CLASS.Name        = "Motors"
		CLASS.ID          = "2-Motor"
		CLASS.SpawnModel  = "models/acf/core/t_drive_e.mdl"
		CLASS.Description = "#acf.descs.motors"
		CLASS.Entity      = "acf_turret_motor"

		CLASS.GetTorque = function(Data, CompSize)
			local SizePerc = (CompSize - Data.ScaleLimit.Min) / (Data.ScaleLimit.Max - Data.ScaleLimit.Min)
			return math.Round((Data.Torque.Min * (1 - SizePerc)) + (Data.Torque.Max * SizePerc))
		end

		CLASS.CalculateSpeed = function(self)
			local SelfTbl = ENTITY.GetTable(self)
			if SelfTbl.Active == false then return 0 end
			return SelfTbl.Speed * SelfTbl.DamageScale
		end
	end)

	do	-- Motor, should be parented to the turret ring, or share the same parent

		-- Electric motor

		Classes.DefineClass("ACF.Turrets.Motor.Electric", "ACF.Turrets.Motor", function()
			CLASS.Name        = "Electric Motor"
			CLASS.ID          = "Motor-ELC"
			CLASS.Description  = "#acf.descs.motors.electric"
			CLASS.Model       = "models/acf/core/t_drive_e.mdl"
			CLASS.Sound       = "acf_base/fx/turret_electric.wav"

			CLASS.Preview = {
				FOV = 100,
			}

			CLASS.Mass       = 60 -- Base mass, will be further modified by settings
			CLASS.Speed      = 720 -- Base speed, this will/not/change, and is used in calculating the final speed after teeth calculation
			CLASS.Efficiency = 0.9
			CLASS.Accel      = 2 -- Time in seconds to reach full speed. Electric motors have instant response

			CLASS.ScaleLimit = { -- For scaling the motor size
				Min = 0.5,
				Max = 6
			}

			CLASS.Teeth = { -- Adjustable for speed versus torque
				Base = 12,

				Min = 8,
				Max = 48,
			}

			CLASS.Torque = {
				Min = 20,
				Max = 400
			}
		end)

		-- Hydraulic motor

		Classes.DefineClass("ACF.Turrets.Motor.Hydraulic", "ACF.Turrets.Motor", function()
			CLASS.Name        = "Hydraulic Motor"
			CLASS.ID          = "Motor-HYD"
			CLASS.Description  = "#acf.descs.motors.hydraulic"
			CLASS.Model       = "models/acf/core/t_drive_h.mdl"
			CLASS.Sound       = "acf_base/fx/turret_hydraulic.wav"

			CLASS.Preview = {
				FOV = 100,
			}

			CLASS.Mass       = 80 -- Base mass, will be further modified by settings
			CLASS.Speed      = 360 -- Base speed, this will/not/change, and is used in calculating the final speed after teeth calculation
			CLASS.Efficiency = 0.98
			CLASS.Accel      = 8 -- Time in seconds to reach full speed, hydraulic motors have a little spool time

			CLASS.ScaleLimit = { -- For scaling the motor size
				Min = 0.5,
				Max = 6
			}

			CLASS.Teeth = { -- Adjustable for speed versus torque
				Base = 12,

				Min = 8,
				Max = 48,
			}

			CLASS.Torque = {
				Min = 50,
				Max = 1000
			}
		end)
	end
end

do	-- Turret gyroscopes
	Classes.DefineClass("ACF.Turrets.Gyro", "ACF.Turrets.Component", function()
		CLASS.Name        = "Gyroscopes"
		CLASS.ID          = "3-Gyro"
		CLASS.SpawnModel  = "models/bull/various/gyroscope.mdl"
		CLASS.Description = "#acf.descs.gyros"
		CLASS.Entity      = "acf_turret_gyro"
	end)

	do	-- Gyro
		--[[
			Ideally takes some amount of space (big collection of computers but put into one bigger computer model)
			Single-axis should be parented to or share the same parent as the linked turret drive (Can be linked to either turret drive, but only one)
			Dual-axis should be parented to or share the same parent as the horizontal turret drive (MUST be linked to a vertical AND horizontal turret drive, can not mix types)
		]]

		Classes.DefineClass("ACF.Turrets.Gyro.Single", "ACF.Turrets.Gyro", function()
			CLASS.Name        = "Single Axis Turret Gyro"
			CLASS.ID          = "1-Gyro"
			CLASS.Description  = "#acf.descs.gyros.single"
			CLASS.Model       = "models/bull/various/gyroscope.mdl"

			CLASS.Preview = {
				FOV = 125,
			}

			CLASS.Mass   = 75
			CLASS.IsDual = false
		end)

		Classes.DefineClass("ACF.Turrets.Gyro.Dual", "ACF.Turrets.Gyro", function()
			CLASS.Name        = "Dual Axis Turret Gyro"
			CLASS.ID          = "2-Gyro"
			CLASS.Description  = "#acf.descs.gyros.dual"
			CLASS.Model       = "models/acf/core/t_gyro.mdl"

			CLASS.Preview = {
				FOV = 90,
			}

			CLASS.Mass   = 150
			CLASS.IsDual = true
		end)
	end
end

do	-- Turret computers
	Classes.DefineClass("ACF.Turrets.Computer", "ACF.Turrets.Component", function()
		CLASS.Name        = "Computers"
		CLASS.ID          = "4-Computer"
		CLASS.SpawnModel  = "models/acf/core/t_computer.mdl"
		CLASS.Description = "#acf.descs.computers"
		CLASS.Entity      = "acf_turret_computer"
	end)

	--[[
			Ballistic computers that should be linked to a gun to gather bulletdata, and have a Calculate input
			When Calculate is triggered, Thinking flag is set so only one run can occur at once

			After calculation is done, output Firing Solution [ANGLE] (global), Flight Time [NUMBER]
	]]

	do	-- Computers
		Classes.DefineClass("ACF.Turrets.Computer.Direct", "ACF.Turrets.Computer", function()
			CLASS.Name        = "Direct Ballistics Computer"
			CLASS.ID          = "DIR-BalComp"
			CLASS.Description  = "#acf.descs.computers.direct"
			CLASS.Model       = "models/acf/core/t_computer.mdl"

			CLASS.Preview = {
				FOV = 100,
			}

			CLASS.Mass = 100

			CLASS.SetupInputs = function(_, List)
				local Count = #List

				List[Count + 1] = "Calculate Superelevation (One-time calculation to collect super-elevation)"
			end

			CLASS.SetupOutputs = function(_, List)
				local Count = #List

				List[Count + 1] = "Elevation (Super-elevation, set global pitch to this for automatic ranging)"
			end

			CLASS.ComputerInfo = {
				ThinkTime    = 0.03, 	-- Speed of the actual think time
				MaxThinkTime = 6,		-- Maximum time to spend on a simulation
				DeltaTime    = 0.2,		-- Simulation speed (affects calculations directly, higher numbers mean the simulation runs faster but will be less accurate)
				CalcError    = 0.25,		-- Lee-way in units per 100u of lateral distance
				HighArc      = false,	-- Starts with simulation pointed directly at target if false, otherwise starts pointing up and moves down
				Constant     = true,		-- Will constantly run as long as Calculate is 1
				Bulk         = 8,		-- Number of calculations to perform per tick
				Delay        = 0.1		-- Time after finishing before another calculation can run
			}
		end)

		Classes.DefineClass("ACF.Turrets.Computer.Indirect", "ACF.Turrets.Computer", function()
			CLASS.Name        = "Indirect Ballistics Computer"
			CLASS.ID          = "IND-BalComp"
			CLASS.Description  = "#acf.descs.computers.indirect"
			CLASS.Model       = "models/acf/core/t_computer.mdl"

			CLASS.Preview = {
				FOV = 100,
			}

			CLASS.Mass = 150

			CLASS.ComputerInfo = {
				ThinkTime    = 0.03,		-- Speed of the actual think time
				MaxThinkTime = 6,		-- Maximum time to spend on a simulation
				DeltaTime    = 0.06,		-- Simulation speed (affects calculations directly, higher numbers mean the simulation runs faster but will be less accurate)
				CalcError    = 0.05,		-- Lee-way in units per 100u of lateral distance
				HighArc      = true,		-- Starts with simulation pointed directly at target if false, otherwise starts pointing up and moves down
				Constant     = false,
				Bulk         = 10,		-- Number of calculations to perform per tick
				Delay        = 0.1,		-- Time after finishing before another calculation can run
			}
		end)
	end
end
