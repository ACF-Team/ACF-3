local ACF = ACF
local Turrets = ACF.Classes.Turrets
local InchToMm = ACF.InchToMm

--[[
	For the purposes of calculations and customization, all turrets are considered to be gear-driven

	https://www.balnex.pl/uploads/file/download/ksiazka-techniczna-lozyska-wiencowe.pdf - Has info on slewing rings and applying power to them, pg 16-17

	https://qcbslewingrings.com/product-category/geared-motors/ - Has more PDFs, including the hydraulic one below
	https://qcbslewingrings.com/wp-content/uploads/2021/01/E1-SPOOLVALVE.pdf - Has info on hydraulic motors
]]

-- Bunched all of the definitions together due to some loading issue

do	-- Turret drives
	local function ClampAngle(A,Amin,Amax)
		local p,y,r

		if A.p < Amin.p then p = Amin.p elseif A.p > Amax.p then p = Amax.p else p = A.p end
		if A.y < Amin.y then y = Amin.y elseif A.y > Amax.y then y = Amax.y else y = A.y end
		if A.r < Amin.r then r = Amin.r elseif A.r > Amax.r then r = Amax.r else r = A.r end

		return Angle(p,y,r)
	end

	Turrets.Register("1-Turret",{
		Name		= "Turrets",
		Description	= "The turret drives themselves.\nThese have a fallback handcrank that is used automatically if no motor is available.",
		Entity		= "acf_turret",
		CreateMenu	= ACF.CreateTurretMenu,
		LimitConVar	= {
			Name	= "_acf_turret",
			Amount	= 20,
			Text	= "Maximum number of ACF turrets a player can create."
		},
		GetMass		= function(Data, Size)
			return math.Round(math.max(Data.Mass * (Size / Data.Size.Base),5) ^ 1.5, 1)
		end,
		GetTeethCount	= function(Data, Size)
			local SizePerc = (Size - Data.Size.Min) / (Data.Size.Max - Data.Size.Min)
			return math.Round((Data.Teeth.Min * (1 - SizePerc)) + (Data.Teeth.Max * SizePerc))
		end,
		GetRingHeight	= function(TurretData,Size)
			local RingHeight = math.max(Size * TurretData.Ratio,4)

			if (TurretData.Type == "Turret-H") and (Size < 12) then
				return 12 -- sticc
			end

			return RingHeight
		end,

		HandGear	= { -- Fallback incase a motor is unavailable
			Teeth	= 12, -- For use in calculating end effective speed of a turret
			Speed	= 220, -- deg/s
			Torque	= 14, -- 0.1m * 140N * sin(90), torque to turn a small handwheel 90 degrees with slightly more than recommended force for a human
			Efficiency	= 0.99, -- Gearbox efficiency, won't be too punishing for handcrank
			Accel	= 5,
			Sound	= "acf_base/fx/turret_handcrank.wav",
		},

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

		CalcSpeed	= function(TurretData, PowerData) -- Called whenever something on the turret changes, returns resistance from mass on the ring (overall, not inertial)
			local Teeth		= TurretData.Teeth
			local GearRatio	= PowerData.Teeth / Teeth
			local TopSpeed	= GearRatio * (PowerData.Speed / 6) -- Converting deg/s to RPM, and adjusting by gear ratio
			local MaxPower	= ((PowerData.Torque / GearRatio) * TopSpeed) / (9550 * PowerData.Efficiency)
			local Diameter	= (TurretData.RingSize * InchToMm) -- Used for some of the formulas from the referenced page, needs to be in mm
			local CoMDistance	= (TurretData.LocalCoM * Vector(1,1,0)):Length() * (InchToMm / 1000) -- (Lateral) Distance of center of mass from center of axis, in meters for calculation
			local OffBaseDistance	= math.max(CoMDistance - math.max(CoMDistance - (Diameter / 2),0),0)

			-- Slewing ring friction moment caused by load (kNm)
			-- 1kg weight (mass * gravity) is about 9.81N
			-- 0.006 = fric coefficient for ball slewing rings
			-- k = 4.4 = coefficient of load accommodation for ball slewing rings
			local Weight	= (TurretData.TotalMass * 9.81) / 1000
			local Mz		= 0 -- Nm resistance to torque

			local Mk,Fa,Fr

			if TurretData.TurretClass == "Turret-H" then
				Mk		= Weight * OffBaseDistance -- Sum of tilting moments (kNm) (off balance load)
				Fa		= Weight * math.Clamp(1 - (CoMDistance * 2),0,1) * TurretData.Tilt -- Sum of axial dynamic forces (kN) (on balance load)
				Fr		= Weight * math.Clamp(1 - (CoMDistance * 2),0,1) * (1 - TurretData.Tilt) * 1.73 -- Sum of radial dynamic forces (kN), 1.73 is the coefficient for prevailing load, which is already determined by CoMDistance and Tilt
				Mz		= 0.006 * 4.4 * (((Mk * 1000) / Diameter) +  (Fa / 4.4) + (Fr / 2)) * (Diameter / 2000)
			else
				local ZDist = TurretData.LocalCoM.z * (InchToMm / 1000)

				OffBaseDistance	= math.max(ZDist - math.max(ZDist - ((TurretData.RingHeight * InchToMm) / 2),0),0)
				Mk		= Weight * OffBaseDistance -- Sum of tilting moments (kNm) (off balance load)
				Fr		= Weight * math.Clamp(1 - (CoMDistance * 2),0,1) -- Sum of radial dynamic forces (kN), included for vertical turret drives
				Mz		= 0.006 * 4.4 * (((Mk * 1000) / Diameter) + (Fr / 2)) * (Diameter / 2000)
			end

			-- 9.55 is 1 rad/s to RPM
			-- Required power to rotate at full speed
			-- With this we can lower maximum attainable speed
			local ReqConstantPower	= (Mz * TopSpeed) / (9.55 * PowerData.Efficiency)

			if (math.max(1,ReqConstantPower) / math.max(MaxPower,1)) > 1 then return {SlewAccel = 0, MaxSlewRate = 0} end -- Too heavy to rotate, so we'll just stop here

			local FinalTopSpeed = TopSpeed * math.min(1,MaxPower / ReqConstantPower) * 6 -- converting back to deg/s

			-- Moment from acceleration of rotating mass (kNm)
			local RotInertia	= 0.01 * TurretData.TotalMass * (CoMDistance ^ 2)
			local LoadInertia	= RotInertia * (1 / ((1 / GearRatio) ^ 2))
			local Accel 	= (3.1415 * FinalTopSpeed) / (30 * PowerData.Accel)
			local Mg 		= LoadInertia * Accel

			-- 9.55 is 1 rad/s to RPM
			local ReqAccelPower	= ((Mg + Mz) * Accel) / (9.55 * PowerData.Efficiency)

			-- Kind of arbitrary, needed it to stop at some point
			if (math.max(1,ReqAccelPower) / math.max(1,Accel)) > 5 then return {SlewAccel = 0, MaxSlewRate = 0} end -- Too heavy to accelerate, so we'll just stop here

			local FinalAccel	= Accel * math.Clamp(MaxPower / ReqAccelPower,0,1) * 6 -- converting back to deg/s^2

			return {SlewAccel = FinalAccel, MaxSlewRate = FinalTopSpeed, MotorMaxSpeed = TopSpeed * 6, MotorGearRatio = GearRatio, EffortScale = math.min(1,1 / (MaxPower / ReqConstantPower))}
		end
	})

	do	-- Horizontal turret component
		Turrets.RegisterItem("Turret-H","1-Turret",{
			Name			= "Horizontal Turret",
			Description		= "The large stable base of a turret.",
			Model			= "models/acf/core/t_ring.mdl",
			ModelSmall		= "models/holograms/hq_cylinder.mdl", -- To be used for diameters < 12u, for RWS or other small turrets
			Mass			= 34, -- At default size, this is the mass of the turret ring. Will scale up/down with diameter difference

			Size = {
				Base		= 60,	-- The default size for the menu
				Min			= 2,	-- To accomodate itty bitty RWS turrets
				Max			= 512,	-- To accomodate ship turrets
				Ratio		= 0.1	-- Height modifier for total size
			},

			Teeth			= {		-- Used to give a final teeth count with size
				Min			= 12,
				Max			= 3072
			},

			Armor			= {
				Min			= 15,
				Max			= 175
			},

			SetupInputs		= function(_,List)
				local Count = #List

				List[Count + 1] = "Bearing (Local degrees from home angle)"
			end,

			SlewFuncs		= {
				GetStab				= function(Turret)
					if (not (Turret.Stabilized and Turret.Active)) or (Turret.Manual == true) then return 0 end
					local AngDiff	= Turret.Rotator:WorldToLocalAngles(Turret.LastRotatorAngle)

					return (AngDiff.yaw * Turret.StabilizeAmount) or 0
				end,

				GetTargetBearing	= function(Turret,StabAmt)
					local Rotator = Turret.Rotator

					if Turret.HasArc then
						if Turret.Manual then
							return Rotator:WorldToLocalAngles(Turret:LocalToWorldAngles(Angle(0, math.Clamp(-Turret.DesiredDeg,Turret.MinDeg,Turret.MaxDeg), 0))).yaw
						else
							local LocalDesiredAngle = ClampAngle(Turret:WorldToLocalAngles(Turret.DesiredAngle) - Angle(0,StabAmt,0),Angle(0,-Turret.MaxDeg,0),Angle(0,-Turret.MinDeg,0))

							return Rotator:WorldToLocalAngles(Turret:LocalToWorldAngles(LocalDesiredAngle)).yaw
						end
					else
						return Turret.Manual and (Rotator:WorldToLocalAngles(Turret:LocalToWorldAngles(Angle(0, -Turret.DesiredDeg, 0))).yaw) or (Rotator:WorldToLocalAngles(Turret.DesiredAngle).yaw - StabAmt)
					end
				end,

				SetRotatorAngle		= function(Turret)
					Turret.Rotator:SetAngles(Turret:LocalToWorldAngles(Angle(0, Turret.CurrentAngle, 0)))
				end
			}
		})
	end

	do	-- Vertical turret component
		Turrets.RegisterItem("Turret-V","1-Turret",{
			Name			= "Vertical Turret",
			Description		= "The smaller part of a turret, usually has the weapon directly attached to it.\nCan be naturally stabilized up to 25% if there is no motor attached, but the mass must be balanced.",
			Model			= "models/acf/core/t_trun.mdl",
			Mass			= 25, -- At default size, this is the mass of the turret ring. Will scale up/down with diameter difference

			Size = {
				Base		= 12,	-- The default size for the menu
				Min			= 4,	-- To accomodate itty bitty RWS turrets
				Max			= 48,	-- To accomodate ship turrets
				Ratio		= 1	-- Height modifier for total size
			},

			Teeth			= {		-- Used to give a final teeth count with size
				Min			= 8,
				Max			= 384
			},

			Armor			= {
				Min			= 5,
				Max			= 305
			},

			SetupInputs		= function(_,List)
				local Count	= #List

				List[Count + 1] = "Elevation (Local degrees from home angle)"
			end,

			SlewFuncs		= {
				GetStab				= function(Turret)
					if (not (Turret.Stabilized and Turret.Active)) or (Turret.Manual == true) then return 0 end
					local AngDiff	= Turret.Rotator:WorldToLocalAngles(Turret.LastRotatorAngle)

					return (AngDiff.pitch * Turret.StabilizeAmount) or 0
				end,

				GetTargetBearing	= function(Turret,StabAmt)
					local Rotator = Turret.Rotator

					if Turret.HasArc then
						if Turret.Manual then
							return Rotator:WorldToLocalAngles(Turret:LocalToWorldAngles(Angle(math.Clamp(-Turret.DesiredDeg,Turret.MinDeg,Turret.MaxDeg), 0, 0))).pitch
						else
							local LocalDesiredAngle = ClampAngle(Turret:WorldToLocalAngles(Turret.DesiredAngle) - Angle(StabAmt,0,0),Angle(-Turret.MaxDeg,0,0),Angle(-Turret.MinDeg,0,0))

							return Rotator:WorldToLocalAngles(Turret:LocalToWorldAngles(LocalDesiredAngle)).pitch
						end
					else
						return Turret.Manual and (Rotator:WorldToLocalAngles(Turret:LocalToWorldAngles(Angle(-Turret.DesiredDeg, 0, 0))).pitch) or (Rotator:WorldToLocalAngles(Turret.DesiredAngle).pitch - StabAmt)
					end
				end,

				SetRotatorAngle		= function(Turret)
					Turret.Rotator:SetAngles(Turret:LocalToWorldAngles(Angle(Turret.CurrentAngle, 0, 0)))
				end
			}
		})
	end
end

do	-- Turret motors
	Turrets.Register("2-Motor",{
		Name		= "Motors",
		Description	= "Slewing drive motors, to increase operational speeds and get you on target.\nMust be parented to or share the parent with the linked turret drive.\nMust also be close to the linked turret (Within or close to diameter).",
		Entity		= "acf_turret_motor",
		CreateMenu	= ACF.CreateTurretMotorMenu,
		LimitConVar	= {
			Name	= "_acf_turret_motor",
			Amount	= 20,
			Text	= "Maximum number of ACF turret components a player can create."
		},

		GetTorque	= function(Data, CompSize)
			local SizePerc = (CompSize - Data.ScaleLimit.Min) / (Data.ScaleLimit.Max - Data.ScaleLimit.Min)
			return math.Round((Data.Torque.Min * (1 - SizePerc)) + (Data.Torque.Max * SizePerc))
		end,

		CalculateSpeed	= function(self)
			if self.Active == false then return 0 end
			return self.Speed * self.DamageScale
		end,
	})

	do	-- Motor, should be parented to the turret ring, or share the same parent

		-- Electric motor

		Turrets.RegisterItem("Motor-ELC","2-Motor",{
			Name			= "Electric Motor",
			Description		= "A snappy responsive electric motor, can handle most uses cases but quickly falters under higher weights",
			Model			= "models/acf/core/t_drive_e.mdl",
			Sound			= "acf_base/fx/turret_electric.wav",

			Mass			= 60, -- Base mass, will be further modified by settings
			Speed			= 720, -- Base speed, this will/not/change, and is used in calculating the final speed after teeth calculation
			Efficiency		= 0.9,
			Accel			= 2, -- Time in seconds to reach full speed. Electric motors have instant response

			ScaleLimit		= { -- For scaling the motor size
				Min		= 0.5,
				Max		= 6
			},

			Teeth			= { -- Adjustable for speed versus torque
				Base	= 12,

				Min		= 8,
				Max		= 32,
			},

			Torque			= {
				Min		= 20,
				Max		= 400
			}
		})

		-- Hydraulic motor

		Turrets.RegisterItem("Motor-HYD","2-Motor",{
			Name			= "Hydraulic Motor",
			Description		= "A strong but sluggish hydraulic motor, it'll turn the world over but takes a little bit to get to that point.",
			Model			= "models/acf/core/t_drive_h.mdl",
			Sound			= "acf_base/fx/turret_hydraulic.wav",

			Mass			= 80, -- Base mass, will be further modified by settings
			Speed			= 360, -- Base speed, this will/not/change, and is used in calculating the final speed after teeth calculation
			Efficiency		= 0.98,
			Accel			= 8, -- Time in seconds to reach full speed, hydraulic motors have a little spool time

			ScaleLimit		= { -- For scaling the motor size
				Min		= 0.5,
				Max		= 6
			},

			Teeth			= { -- Adjustable for speed versus torque
				Base	= 12,

				Min		= 8,
				Max		= 32,
			},

			Torque			= {
				Min		= 40,
				Max		= 800
			}
		})
	end
end

do	-- Turret gyroscopes
	Turrets.Register("3-Gyro",{
		Name		= "Gyroscopes",
		Description	= "Components that are used to stabilize turret drives.",
		Entity		= "acf_turret_gyro",
		CreateMenu	= ACF.CreateTurretGyroMenu,
		LimitConVar	= {
			Name	= "_acf_turret_gyro",
			Amount	= 20,
			Text	= "Maximum number of ACF turret gyros a player can create."
		},
	})

	do	-- Gyro
		--[[
			Ideally takes some amount of space (big collection of computers but put into one bigger computer model)
			Single-axis should be parented to or share the same parent as the linked turret drive (Can be linked to either turret drive, but only one)
			Dual-axis should be parented to or share the same parent as the horizontal turret drive (MUST be linked to a vertical AND horizontal turret drive, can not mix types)
		]]

		Turrets.RegisterItem("1-Gyro","3-Gyro",{
			Name			= "Single Axis Turret Gyro",
			Description		= "A component that will stabilize one turret drive.\nMust be parented to or share the parent with the linked turret drive.\nMust have a motor linked to the turret drive.",
			Model			= "models/bull/various/gyroscope.mdl",

			Mass			= 75,
			IsDual			= false,
		})

		Turrets.RegisterItem("2-Gyro","3-Gyro",{
			Name			= "Dual Axis Turret Gyro",
			Description		= "A component that will stabilize one vertical and horizontal turret drive.\nMust be parented to or share the parent with the horizontal turret drive.\nEach turret drive must have a motor linked.",
			Model			= "models/acf/core/t_gyro.mdl",

			Mass			= 150,
			IsDual			= true,
		})
	end
end

-- I will eventually work on this. Eventually.


do	-- Turret computers
	Turrets.Register("4-Computer",{
		Name		= "Computers",
		Description	= "Computer capable of calculating the optimal angle to hit a target.\nLinks to a weapon to get bullet data, required for ballistics calculations.",
		Entity		= "acf_turret_computer",
		CreateMenu	= ACF.CreateTurretComputerMenu,
		LimitConVar	= {
			Name	= "_acf_turret_computer",
			Amount	= 4,
			Text	= "Maximum number of ACF turret computers a player can create."
		},
	})

	--[[
			Ballistic computers that should be linked to a gun to gather bulletdata, and have a Calculate input
			When Calculate is triggered, Thinking flag is set so only one run can occur at once

			After calculation is done, output Firing Solution [ANGLE] (global), Flight Time [NUMBER]
	]]

	do	-- Computers
		Turrets.RegisterItem("DIR-BalComp","4-Computer",{
			Name			= "Direct Ballistics Computer",
			Description		= "A component that is capable of calculating the angle required to shoot a weapon to hit a spot within view.\nThis is capable of constantly calculating to track a target at a constant velocity, as long as Calculate is true.\nHas a 2s delay between uses.",
			Model			= "models/acf/core/t_computer.mdl",

			Mass			= 100,

			ComputerInfo	= {
				ThinkTime		= 0.04, 	-- Speed of the actual think time
				MaxThinkTime	= 4,		-- Maximum time to spend on a simulation
				DeltaTime		= 0.2,		-- Simulation speed (affects calculations directly, higher numbers mean the simulation runs faster but will be less accurate)
				CalcError		= 0.25,		-- Lee-way in units per 100u of lateral distance
				HighArc			= false,	-- Starts with simulation pointed directly at target if false, otherwise starts pointing up and moves down
				Constant		= true,		-- Will constantly run as long as Calculate is 1
				Bulk			= 8,		-- Number of calculations to perform per tick
				Delay			= 2			-- Time after finishing before another calculation can run
			},
		})

		Turrets.RegisterItem("IND-BalComp","4-Computer",{
			Name			= "Indirect Ballistics Computer",
			Description		= "A component that is capable of calculating the angle required to shoot a weapon to hit a spot out of view.\nHas a 3s delay between uses.",
			Model			= "models/acf/core/t_computer.mdl",

			Mass			= 150,

			ComputerInfo	= {
				ThinkTime		= 0.04,		-- Speed of the actual think time
				MaxThinkTime	= 6,		-- Maximum time to spend on a simulation
				DeltaTime		= 0.06,		-- Simulation speed (affects calculations directly, higher numbers mean the simulation runs faster but will be less accurate)
				CalcError		= 0.05,		-- Lee-way in units per 100u of lateral distance
				HighArc			= true,		-- Starts with simulation pointed directly at target if false, otherwise starts pointing up and moves down
				Constant		= false,
				Bulk			= 10,		-- Number of calculations to perform per tick
				Delay			= 3,		-- Time after finishing before another calculation can run
			},
		})
	end
end