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

	-- Sets an input for an entity, if it exists and the value has changed since last time.
	local function TriggerSafe(SelfTbl, Entity, Name, Value)
		if not IsValid(Entity) then return end
		if not SelfTbl.LastInputs[Entity] then SelfTbl.LastInputs[Entity] = {} end
		if SelfTbl.LastInputs[Entity][Name] ~= Value then
			SelfTbl.LastInputs[Entity][Name] = Value
			Entity:TriggerInput(Name, Value)
		end
	end

	local function SetAll(SelfTbl, TblName, Name, Value)
		for Entity in pairs(SelfTbl[TblName]) do TriggerSafe(SelfTbl, Entity, Name, Value) end
	end

	-- Sets a property on all end effectors
	local function SetBoth(SelfTbl, Name, Value)
		for Gearbox in pairs(SelfTbl.GearboxEnds) do TriggerSafe(SelfTbl, Gearbox, Name, Value) end
	end

	-- Sets a optionally signed property on left end effectors
	local function SetLeft(SelfTbl, Name, Value, NotSided)
		for Gearbox, Side in pairs(SelfTbl.LeftGearboxes) do TriggerSafe(SelfTbl, Gearbox, (NotSided and "" or Side .. " ") .. Name, Value) end
	end

	-- Sets a optionally signed property on right end effectors
	local function SetRight(SelfTbl, Name, Value, NotSided)
		for Gearbox, Side in pairs(SelfTbl.RightGearboxes) do TriggerSafe(SelfTbl, Gearbox, (NotSided and "" or Side .. " ") .. Name, Value) end
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
		local ForwardGears = {}
		local ReverseGears = {}
		for Index, Ratio in ipairs(MainGearbox.Gears) do
			if Ratio > 0 then table.insert(ForwardGears, Index) else table.insert(ReverseGears, Index) end
		end
		table.sort(ForwardGears, function(A, B) return MainGearbox.Gears[A] < MainGearbox.Gears[B] end)
		table.sort(ReverseGears, function(A, B) return MainGearbox.Gears[A] > MainGearbox.Gears[B] end)
		self.ForwardGears, self.ReverseGears = ForwardGears, ReverseGears
		if MainGearbox.Automatic then self.ForwardGears = {1} self.ReverseGears = {2} end

		self.FuelCapacity = 0
		for Fuel in pairs(self.Fuels) do self.FuelCapacity = self.FuelCapacity + Fuel.Capacity end

		-- Determine the Left/Right wheels assuming the vehicle is built north
		local LeftWheels, RightWheels = {}, {}
		local avg, count = 0, 0
		for Wheel in pairs(self.Wheels) do
			avg, count = avg + Wheel:GetPos().x, count + 1
		end
		avg = avg / count

		for Wheel in pairs(self.Wheels) do
			if Wheel:GetPos().x < avg then LeftWheels[Wheel] = true else RightWheels[Wheel] = true end
		end
		self.LeftWheels, self.RightWheels = LeftWheels, RightWheels

		-- Determine the Left/Right gearboxes from the Left/Right wheels
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

		self.CanSteer = #self.SteerPlatesSorted > 0 -- Steer if there are any steer plates

		self.CanNeutral = not self.CanSteer -- Can't neutral steer if you can steer

		-- Can't neutral steer if a gearbox is connected to both sides
		for Gearbox in pairs(self.LeftGearboxes) do if self.RightGearboxes[Gearbox] then self.CanNeutral = false break end end
		for Gearbox in pairs(self.RightGearboxes) do if self.LeftGearboxes[Gearbox] then self.CanNeutral = false break end end

		for Wheel in pairs(self.Wheels) do self.SteerAngles[Wheel] = 0 end

		-- if self.Gearbox.DoubleDiff then self.CanNeutral = true end

		self.LastInputs = {}
		self.LastGear = 0
		self.LastTrueGear = 0
	end

	--- Handles driving, gearing, clutches, latches and brakes
	function ENT:ProcessDrivetrain(SelfTbl)
		-- Log speed even if drivetrain is invalid
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
		local ShouldNeutral = self.CanNeutral and not self:GetForceCarSteering()
		local ShouldSteer = self.CanSteer or self:GetForceCarSteering()

		-- Throttle the engines
		SetAll(SelfTbl, "Engines", "Throttle", IsMoving and 100 or self:GetThrottleIdle() or 0)

		local MinSpeed, MaxSpeed = self:GetSpeedLow(), self:GetSpeedTop()
		local MinBrake, MaxBrake = self:GetBrakeStrength(), self:GetBrakeStrengthTop()
		local BrakeStrength = MinBrake
		if MinSpeed ~= MaxSpeed then -- User intends to use speed based braking
			BrakeStrength = math.Remap(Speed, MinSpeed, MaxSpeed, MinBrake, MaxBrake)
		end

		if IsBraking or (self:GetBrakeEngagement() == 1 and not IsMoving) then -- Braking
			SetLeft(SelfTbl, "Brake", BrakeStrength) SetRight(SelfTbl, "Brake", BrakeStrength)
			SetLeft(SelfTbl, "Clutch", CLUTCH_BLOCK) SetRight(SelfTbl, "Clutch", CLUTCH_BLOCK)
			SetLatches(SelfTbl, true)
			return
		end

		if not ShouldSteer then
			-- Tank steering
			SetLatches(SelfTbl, false)
			if IsNeutral and ShouldNeutral then
				-- Neutral steering, gears follow A/D
				SetLeft(SelfTbl, "Brake", 0) SetRight(SelfTbl, "Brake", 0)
				SetLeft(SelfTbl, "Clutch", CLUTCH_FLOW) SetRight(SelfTbl, "Clutch", CLUTCH_FLOW)
				SetLeft(SelfTbl, "Gear", A and 2 or 1, true) SetRight(SelfTbl, "Gear", D and 2 or 1, true)
			else
				-- Normal driving, gears follow W/S
				local TransferGear = (W and 1) or (S and 2) or (A and 1) or (D and 1) or 0
				if ShouldNeutral then SetBoth(SelfTbl, "Gear", TransferGear) end

				SetLeft(SelfTbl,  "Brake",  A and BrakeStrength or 0)
				SetRight(SelfTbl, "Brake",  D and BrakeStrength or 0)
				SetLeft(SelfTbl,  "Clutch", A and CLUTCH_BLOCK or CLUTCH_FLOW)
				SetRight(SelfTbl, "Clutch", D and CLUTCH_BLOCK or CLUTCH_FLOW)
			end
		else
			-- Car steering
			SetLeft(SelfTbl, "Brake", 0) SetRight(SelfTbl, "Brake", 0)
			SetLeft(SelfTbl, "Clutch", CLUTCH_FLOW) SetRight(SelfTbl, "Clutch", CLUTCH_FLOW)
			SetLatches(SelfTbl, false) -- Revert braking if not braking

			local TransferGear = (W and 1) or (S and 2) or (A and 1) or (D and 1) or 0
			SetBoth(SelfTbl, "Gear", TransferGear)

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

		local Gear = SelfTbl.LastGear

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
		local ShouldNeutral = self.CanNeutral and not self:GetForceCarSteering()
		local TrueGear = 0
		if S and not ShouldNeutral then
			Gear = math.Clamp(Gear, 0, #self.ReverseGears)
			TrueGear = self.ReverseGears[Gear] or 0
		else
			Gear = math.Clamp(Gear, 0, #self.ForwardGears)
			TrueGear = self.ForwardGears[Gear] or 0
		end

		if TrueGear ~= SelfTbl.LastTrueGear then
			Gearbox:TriggerInput("Gear", TrueGear)
		end
		SelfTbl.LastGear = Gear
		SelfTbl.LastTrueGear = TrueGear
	end

	function ENT:AnalyzeSteerPlates(SteerPlate)
		if not IsValid(SteerPlate) then return end
		table.insert(self.SteerPlatesSorted, SteerPlate)
		table.sort(self.SteerPlatesSorted, function(A, B)
			return A:GetPos().y > B:GetPos().y
		end)
	end
end