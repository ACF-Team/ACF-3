local RecacheBindOutput = ENT.RecacheBindOutput
local GetKeyState = ENT.GetKeyState

-- Drivetrain related
do
	local CLUTCH_FLOW = 0
	local CLUTCH_BLOCK = 1

	--- Finds the components of the drive train
	--- Input is the "main" gearbox of the drivetrain
	--- returns multiple arrays, one for Wheels, engines, fuels, wheel gearboxes and intermediate gearboxes
	--- This should be enough for general use, obviously it can't cover every edge case.
	local function DiscoverDriveTrain(Target)
		local Queued  = { [Target] = true }
		local Checked = {}
		local Current, Class, Sources

		local Wheels, Engines, Fuels, Ends, Intermediates = {}, {}, {}, {}, {}

		while next(Queued) do
			Current = next(Queued)
			Class   = Current:GetClass()
			Sources = ACF.GetAllLinkSources(Class)

			Queued[Current] = nil
			Checked[Current] = true

			if Class == "acf_engine" then
				Engines[Current] = true
			elseif Class == "acf_gearbox" then
				if Sources.Wheels and next(Sources.Wheels(Current)) then Ends[Current] = true else Intermediates[Current] = true end
			elseif Class == "acf_fueltank" then
				Fuels[Current] = true
			elseif Class == "prop_physics" then
				Wheels[Current] = true
			end

			for _, Action in pairs(Sources) do
				for Entity in pairs(Action(Current)) do
					if not (Checked[Entity] or Queued[Entity]) then
						Queued[Entity] = true
					end
				end
			end
		end
		return Wheels, Engines, Fuels, Ends, Intermediates
	end

	--- Finds the "side" of the gearbox that the wheel is connected to. This corresponds to the wire inputs.
	local function GetLROutput(Gearbox, Wheel)
		local lp = Gearbox:GetAttachment(Gearbox:LookupAttachment("driveshaftL")).Pos
		local rp = Gearbox:GetAttachment(Gearbox:LookupAttachment("driveshaftR")).Pos
		local d1 = Wheel:GetPos():Distance(lp or Vector())
		local d2 = Wheel:GetPos():Distance(rp or Vector())
		if d1 < d2 then return "Left" else return "Right" end
	end

	--- Sets the brakes of the left/right transfers
	local function SetBrakes(SelfTbl, L, R)
		if IsValid(SelfTbl.GearboxLeft) then SelfTbl.GearboxLeft:TriggerInput(SelfTbl.GearboxLeftDir .. " Brake", L) end
		if IsValid(SelfTbl.GearboxLeft) then  SelfTbl.GearboxRight:TriggerInput(SelfTbl.GearboxRightDir .. " Brake", R) end
	end

	--- Sets the clutches of the left/right transfers
	local function SetClutches(SelfTbl, L, R)
		if IsValid(SelfTbl.GearboxLeft) then SelfTbl.GearboxLeft:TriggerInput(SelfTbl.GearboxLeftDir .. " Clutch", L) end
		if IsValid(SelfTbl.GearboxLeft) then SelfTbl.GearboxRight:TriggerInput(SelfTbl.GearboxRightDir .. " Clutch", R) end
	end

	--- Sets the gears of the left/right transfers
	local function SetTransfers(SelfTbl, L, R)
		if IsValid(SelfTbl.GearboxLeft) then SelfTbl.GearboxLeft:TriggerInput("Gear", L) end
		if IsValid(SelfTbl.GearboxRight) then SelfTbl.GearboxRight:TriggerInput("Gear", R) end
	end

	--- Creates/Removes weld constraints from the Left/Right Wheels to baseplate or between them.
	local function SetLatches(SelfTbl, Engage)
		if SelfTbl:GetDisableWeldBrake() == 1 then return end
		for Wheel in pairs(SelfTbl.Wheels) do
			local AlreadyHasWeld = SelfTbl.ControllerWelds[Wheel]
			if Engage and not AlreadyHasWeld then
				SelfTbl.ControllerWelds[Wheel] = constraint.Weld(SelfTbl.Baseplate, Wheel, 0, 0, 0, true, true)
			elseif not Engage and AlreadyHasWeld then
				SelfTbl.ControllerWelds[Wheel]:Remove()
				SelfTbl.ControllerWelds[Wheel] = nil
			end
		end
	end

	--- All wheel variant
	local function SetAllBrakes(SelfTbl, Strength)
		for Gearbox in pairs(SelfTbl.GearboxEnds) do
			if IsValid(Gearbox) then Gearbox:TriggerInput("Brake", Strength) end
		end
	end

	--- All wheel variant
	local function SetAllClutches(SelfTbl, Strength)
		for Gearbox in pairs(SelfTbl.GearboxEnds) do
			if IsValid(Gearbox) then Gearbox:TriggerInput("Clutch", Strength) end
		end
	end

	--- All wheel variant
	local function SetAllTransfers(SelfTbl, Gear)
		for Gearbox in pairs(SelfTbl.GearboxEnds) do
			if IsValid(Gearbox) then Gearbox:TriggerInput("Gear", Gear) end
		end
	end

	--- Steer a plate left or right
	local function SetSteerPlate(SelfTbl, BasePlate, SteerPlate, TURN_ANGLE, TURN_RATE)
		local TURN = SelfTbl.SteerAngles[SteerPlate] or 0
		TURN = TURN + math.Clamp(TURN_ANGLE - TURN, -TURN_RATE, TURN_RATE)
		SelfTbl.SteerAngles[SteerPlate] = TURN
		SteerPlate:SetAngles(BasePlate:LocalToWorldAngles(Angle(0, TURN, 0)))
	end

	--- Intentionally Supported drivetrains:
	--- Single Transaxial gearbox with dual clutch -> basic ww2 style
	--- Single Transaxial gearbox with transfers -> basic neutral steer style
	--- Main gearbox with transfers to wheels -> basic wheeled
	function ENT:AnalyzeDrivetrain(MainGearbox)
		-- Need a list of all linked wheels
		if not IsValid(MainGearbox) then return end

		-- Recalculate the drive train components
		self.Wheels, self.Engines, self.Fuels, self.GearboxEnds, self.GearboxIntermediates = DiscoverDriveTrain(MainGearbox)

		self.GearboxEndCount = table.Count(self.GearboxEnds)
		-- PrintTable({Wheels = self.Wheels, Engines = self.Engines, Fuels = self.Fuels, GearboxEnds = self.GearboxEnds, GearboxIntermediates = self.GearboxIntermediates})

		-- Process gears
		local ForwardGearCount = 0
		for _, v in ipairs(MainGearbox.Gears) do
			if v > 0 then ForwardGearCount = ForwardGearCount + 1 else break end
		end
		self.ForwardGearCount, self.TotalGearCount = ForwardGearCount, #MainGearbox.Gears

		self.FuelCapacity = 0
		for Fuel in pairs(self.Fuels) do self.FuelCapacity = self.FuelCapacity + Fuel.Capacity end

		-- Determine the Left/Right wheels assuming the vehicle is built north
		local LeftWheels, RightWheels = {}, {}
		local avg, count = 0, 0
		for Wheel in pairs(self.Wheels) do
			avg = avg + Wheel:GetPos().x
			count = count + 1
		end
		avg = avg / count
		for Wheel in pairs(self.Wheels) do
			if Wheel:GetPos().x < avg then LeftWheels[Wheel] = true else RightWheels[Wheel] = true end
		end
		self.LeftWheels, self.RightWheels = LeftWheels, RightWheels

		-- Determine the Left/Right gearboxes from the Left/Right wheels
		-- Hypothetically there's a drivetrain with more than one gearbox per side but that's out of scope for newcomers.
		local GetWheels = ACF.GetAllLinkSources("acf_gearbox").Wheels
		local LeftGearboxes, RightGearboxes = {}, {} -- LUTs from gearbox to output direction
		for Gearbox in pairs(self.GearboxEnds) do
			for Wheel in pairs(GetWheels(Gearbox)) do
				if LeftWheels[Wheel] then LeftGearboxes[Gearbox] = GetLROutput(Gearbox, Wheel) end
				if RightWheels[Wheel] then RightGearboxes[Gearbox] = GetLROutput(Gearbox, Wheel) end
			end
		end
		self.LeftGearboxes, self.RightGearboxes = LeftGearboxes, RightGearboxes

		self.GearboxLeft, self.GearboxLeftDir = next(LeftGearboxes)
		self.GearboxRight, self.GearboxRightDir = next(RightGearboxes)

		for Wheel in pairs(self.Wheels) do self.SteerAngles[Wheel] = 0 end
	end

	--- Handles driving, gearing, clutches, latches and brakes
	function ENT:ProcessDrivetrain(SelfTbl)
		-- Log speed even if drivetrain is invalid
		-- TODO: should this be map or player scale?
		if not IsValid(SelfTbl.Baseplate) then return end

		local Unit = self:GetSpeedUnit()
		local Conv = Unit == 0 and 0.09144 or 0.05681 -- Converts u/s to km/h or mph (Assumes 1u = 1in)
		local Speed = self.Baseplate:GetVelocity():Length() * Conv
		SelfTbl.Speed = Speed
		RecacheBindOutput(self, SelfTbl, "Speed", Speed)

		if not IsValid(SelfTbl.Gearbox) then return end

		local W, A, S, D = GetKeyState(SelfTbl, IN_FORWARD), GetKeyState(SelfTbl, IN_MOVELEFT), GetKeyState(SelfTbl, IN_BACK), GetKeyState(SelfTbl, IN_MOVERIGHT)
		local IsBraking = GetKeyState(SelfTbl, IN_JUMP)

		if self:GetFlipAD() then A, D = D, A end

		local IsLateral = W or S						-- Forward/backward movement
		local IsTurning = A or D						-- Left/right movement
		local IsMoving = IsLateral or (not self:GetThrottleIgnoresAD() and IsTurning) -- Moving in any direction

		-- Only two transfer setups can reasonably be expected to neutral steer
		local IsNeutral = not IsLateral and IsTurning
		local CanNeutral = SelfTbl.GearboxEndCount == 2
		local ShouldAWD = SelfTbl.GearboxEndCount > 2 or self:GetForceAWD()

		-- Throttle the engines
		local Engines = SelfTbl.Engines
		for Engine in pairs(Engines) do
			if IsValid(Engine) then
				Engine:TriggerInput("Throttle", IsMoving and 100 or self:GetThrottleIdle() or 0)
			end
		end

		local MinSpeed, MaxSpeed = self:GetSpeedLow(), self:GetSpeedTop()
		local MinBrake, MaxBrake = self:GetBrakeStrength(), self:GetBrakeStrengthTop()
		local BrakeStrength = MinBrake
		if MinSpeed ~= MaxSpeed then -- User intends to use speed based braking
			BrakeStrength = math.Remap(Speed, MinSpeed, MaxSpeed, MinBrake, MaxBrake)
		end

		if not ShouldAWD then
			-- Tank steering
			if IsBraking or (self:GetBrakeEngagement() == 1 and not IsMoving) then -- Braking
				SetBrakes(SelfTbl, BrakeStrength, BrakeStrength) SetClutches(SelfTbl, CLUTCH_BLOCK, CLUTCH_BLOCK) SetLatches(SelfTbl, true)
				return
			end

			SetLatches(SelfTbl, false)
			if IsNeutral and CanNeutral then -- Neutral steering, gears follow A/D
				SetBrakes(SelfTbl, 0, 0) SetClutches(SelfTbl, CLUTCH_FLOW, CLUTCH_FLOW)
				SetTransfers(SelfTbl, A and 2 or 1, D and 2 or 1)
			else -- Normal driving, gears follow W/S
				local TransferGear = (W and 1) or (S and 2) or (A and 1) or (D and 1) or 0
				if CanNeutral then SetTransfers(SelfTbl, TransferGear, TransferGear) end

				if A and not D then -- Turn left
					SetBrakes(SelfTbl, BrakeStrength, 0) SetClutches(SelfTbl, CLUTCH_BLOCK, CLUTCH_FLOW)
				elseif D and not A then -- Turn right
					SetBrakes(SelfTbl, 0, BrakeStrength) SetClutches(SelfTbl, CLUTCH_FLOW, CLUTCH_BLOCK)
				else -- No turn
					SetBrakes(SelfTbl, 0, 0) SetClutches(SelfTbl, CLUTCH_FLOW, CLUTCH_FLOW)
				end
			end
		else
			-- Car steering
			if IsBraking or (self:GetBrakeEngagement() == 1 and not IsMoving) then -- Braking
				SetAllBrakes(SelfTbl, BrakeStrength) SetAllClutches(SelfTbl, CLUTCH_BLOCK) SetLatches(SelfTbl, true)
				return
			end

			SetAllBrakes(SelfTbl, 0) SetAllClutches(SelfTbl, CLUTCH_FLOW) SetLatches(SelfTbl, false) -- Revert braking if not braking
			local TransferGear = (W and 1) or (S and 2) or (A and 1) or (D and 1) or 0
			SetAllTransfers(SelfTbl, TransferGear)

			-- Setang steering stuff
			local TURN_ANGLE = A and BrakeStrength or D and -BrakeStrength or 0
			local TURN_RATE = self:GetSteerRate() or 0
			local SteerPercents = {self:GetSteerPercent1(), self:GetSteerPercent2(), self:GetSteerPercent3(), self:GetSteerPercent4()}
			for Index, SteerPlate in ipairs(SelfTbl.SteerPlatesSorted) do
				if IsValid(SteerPlate) then
					SetSteerPlate(SelfTbl, SelfTbl.Baseplate, SteerPlate, TURN_ANGLE * SteerPercents[Index], TURN_RATE)

					local PhysicsObject = SelfTbl.SteerPhysicsObjects[SteerPlate] or SteerPlate:GetPhysicsObject()
					SelfTbl.SteerPhysicsObjects[SteerPlate] = PhysicsObject
					PhysicsObject:EnableMotion(false)
				end
			end
		end
	end

	--- Handles gear shifting
	function ENT:ProcessDrivetrainLowFreq(SelfTbl)
		local Gearbox = SelfTbl.Gearbox
		if not IsValid(Gearbox) then return end

		local _, S = GetKeyState(SelfTbl, IN_FORWARD), GetKeyState(SelfTbl, IN_BACK)

		local Gear = Gearbox.Gear
		local RPM, Count = 0, 0
		for Engine in pairs(SelfTbl.Engines) do
			if IsValid(Engine) then
				RPM = RPM + Engine.FlyRPM
				Count = Count + 1
			end
		end
		if Count > 0 then RPM = RPM / Count end

		local MinRPM, MaxRPM = self:GetShiftMinRPM(), self:GetShiftMaxRPM()
		if MinRPM == MaxRPM then return end -- Probably not set by the user
		if RPM > MinRPM then Gear = Gear + 1
		elseif RPM < MaxRPM then Gear = Gear - 1 end

		-- Clean this up later
		local CanNeutral = SelfTbl.GearboxEndCount == 2
		local Lower, Upper = 1, SelfTbl.ForwardGearCount
		if CanNeutral then
			Lower = 1
			Upper = SelfTbl.ForwardGearCount
		elseif S then
			Lower = SelfTbl.ForwardGearCount + 1
			Upper = SelfTbl.TotalGearCount
		end

		--Lower = (S and SelfTbl.ForwardGearCount + 1) or 1
		--Upper = (S and SelfTbl.TotalGearCount) or SelfTbl.ForwardGearCount

		Gear = math.Clamp(Gear, Lower, Upper)
		if Gear ~= SelfTbl.Gearbox.Gear then
			SelfTbl.Gearbox:TriggerInput("Gear", Gear)
		end
	end

	function ENT:AnalyzeSteerPlates(SteerPlate)
		if not IsValid(SteerPlate) then return end
		table.insert(self.SteerPlatesSorted, SteerPlate)
		table.sort(self.SteerPlatesSorted, function(A, B)
			return A:GetPos().y > B:GetPos().y
		end)
	end
end