E2Lib.RegisterExtension("acf", true)
-- [ To Do ] --
-- #prop armor
--get incident armor ?
--hit calcs ?
--conversions ?

--DON'T FORGET TO UPDATE cl_acfdescriptions.lua WHEN ADDING FUNCTIONS

--===============================================================================================--
-- Local Variables and Helper Functions
--===============================================================================================--

local ACF       = ACF
local AmmoTypes = ACF.Classes.AmmoTypes
local Clock     = ACF.Utilities.Clock
local match     = string.match
local floor     = math.floor
local Round     = math.Round
local newE2Table	= E2Lib.newE2Table

local function IsACFEntity(Entity)
	if not validPhysics(Entity) then return false end

	local Match = match(Entity:GetClass(), "^acf_")

	return Match and true or false
end

local function RestrictInfo(Player, Entity)
	if not ACF.RestrictInfo then return false end

	return not isOwner(Player, Entity)
end

local function GetReloadTime(Entity)
	local Unloading = Entity.State == "Unloading"
	local NewLoad = Entity.State ~= "Loaded" and Entity.CurrentShot == 0

	return (Unloading or NewLoad) and Entity.MagReload or Entity.ReloadTime or 0
end

local function GetLinkedWheels(Target)
	local Queued  = { [Target] = true }
	local Checked = {}
	local Linked  = {}
	local Current, Class, Sources

	while next(Queued) do
		Current = next(Queued)
		Class   = Current:GetClass()
		Sources = ACF.GetAllLinkSources(Class)

		Queued[Current] = nil
		Checked[Current] = true

		for Name, Action in pairs(Sources) do
			for Entity in pairs(Action(Current)) do
				if not (Checked[Entity] or Queued[Entity]) then
					if Name == "Wheels" then
						Checked[Entity] = true
						Linked[Entity] = true
					else
						Queued[Entity] = true
					end
				end
			end
		end
	end

	return Linked
end

--===============================================================================================--
-- General Functions
--===============================================================================================--

__e2setcost(2)

--returns current ACF drag divisor
e2function number acfDragDiv()
	return ACF.DragDiv
end

-- Returns 1 if functions returning sensitive info are restricted to owned props
e2function number acfInfoRestricted()
	return ACF.RestrictInfo and 1 or 0
end

__e2setcost(5)

-- Returns the full name of an ACF entity
e2function string entity:acfName()
	if not IsACFEntity(this) then return "" end
	if RestrictInfo(self, this) then return "" end

	return this.Name or ""
end

-- Returns the short name of an ACF entity
e2function string entity:acfNameShort()
	if not IsACFEntity(this) then return "" end
	if RestrictInfo(self, this) then return "" end

	return this.ShortName or ""
end

-- Returns the type of ACF entity
e2function string entity:acfType()
	if not IsACFEntity(this) then return "" end
	if RestrictInfo(self, this) then return "" end

	return this.EntType or ""
end

-- Returns the class of ACF entity
e2function string entity:acfClass()
	if not IsACFEntity(this) then return "" end
	if RestrictInfo(self, this) then return "" end

	return this.Class or ""
end

-- Returns 1 if the entity is an ACF engine
e2function number entity:acfIsEngine()
	if not validPhysics(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.IsACFEngine and 1 or 0
end

-- Returns 1 if the entity is an ACF gearbox
e2function number entity:acfIsGearbox()
	if not validPhysics(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.IsACFGearbox and 1 or 0
end

-- Returns 1 if the entity is an ACF gun
e2function number entity:acfIsGun()
	if not validPhysics(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.IsACFWeapon and 1 or 0
end

-- Returns 1 if the entity is an ACF turret
e2function number entity:acfIsGun()
	if not validPhysics(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.IsACFTurret and 1 or 0
end

-- Returns 1 if the entity is an ACF ammo crate
e2function number entity:acfIsAmmo()
	if not validPhysics(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.IsACFAmmoCrate and 1 or 0
end

-- Returns 1 if the entity is an ACF fuel tank
e2function number entity:acfIsFuel()
	if not validPhysics(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.IsACFFuelTank and 1 or 0
end

-- Returns the capacity of an acf ammo crate or fuel tank
e2function number entity:acfCapacity()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.Capacity or 0
end

-- Returns the path of an ACF entity's sound
e2function string entity:acfSoundPath()
	if not IsACFEntity(this) then return "" end
	if RestrictInfo(self, this) then return "" end

	return this.SoundPath or ""
end

-- Returns 1 if an ACF engine, ammo crate, or fuel tank is on
e2function number entity:acfActive()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end
	if this.CanConsume then return this:CanConsume() and 1 or 0 end

	return (this.Active or this.Load) and 1 or 0
end

-- Turns an ACF engine, ammo crate, or fuel tank on or off
e2function void entity:acfActive(number On)
	if not IsACFEntity(this) then return end
	if not isOwner(self, this) then return end

	this:TriggerInput("Active", On)
end

-- Returns the current health of an entity
e2function number entity:acfPropHealth()
	if not validPhysics(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end
	if not ACF.Check(this) then return 0 end

	local Health = this.ACF.Health

	return Health and Round(Health, 2) or 0
end

-- Returns the current armor of an entity
e2function number entity:acfPropArmor()
	if not validPhysics(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end
	if not ACF.Check(this) then return 0 end

	local Armor = this.ACF.Armour

	return Armor and Round(Armor, 2) or 0
end

-- Returns the max health of an entity
e2function number entity:acfPropHealthMax()
	if not validPhysics(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end
	if not ACF.Check(this) then return 0 end

	local MaxHealth = this.ACF.MaxHealth

	return MaxHealth and Round(MaxHealth, 2) or 0
end

-- Returns the max armor of an entity
e2function number entity:acfPropArmorMax()
	if not validPhysics(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end
	if not ACF.Check(this) then return 0 end

	local MaxArmor = this.ACF.MaxArmour

	return MaxArmor and Round(MaxArmor, 2) or 0
end

-- Returns the current health percentage of an entity
e2function number entity:acfPropHealthPercent()
	if not validPhysics(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end
	if not ACF.Check(this) then return 0 end

	local PercHealth = this.ACF.Health / this.ACF.MaxHealth

	return PercHealth and Round(PercHealth, 2) or 0
end

-- Returns the current armor percentage of an entity
e2function number entity:acfPropArmorPercent()
	if not validPhysics(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end
	if not ACF.Check(this) then return 0 end

	local PercArmor = this.ACF.Armour / this.ACF.MaxArmour

	return PercArmor and Round(PercArmor, 2) or 0
end

-- Returns the ductility of an entity
e2function number entity:acfPropDuctility()
	if not validPhysics(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end
	if not ACF.Check(this) then return 0 end

	local Ductility = this.ACF.Ductility

	return Ductility and Ductility * 100 or 0
end

__e2setcost(10)

-- Returns the effective armor given an armor value and hit angle
e2function number acfEffectiveArmor(number Armor, number Angle)
	return Round(Armor / math.abs(math.cos(math.rad(math.min(Angle, 89.999)))), 2)
end

-- Returns the effective armor from a trace hitting a prop
e2function number ranger:acfEffectiveArmor()
	if not (this and validPhysics(this.Entity)) then return 0 end
	if RestrictInfo(self, this.Entity) then return 0 end
	if not ACF.Check(this.Entity) then return 0 end

	local Armor    = this.Entity.ACF.Armour
	local HitAngle = ACF.GetHitAngle(this, this.HitPos - this.StartPos)

	return Round(Armor / math.abs(math.cos(math.rad(HitAngle))), 2)
end

__e2setcost(20)

--returns 1 if hitpos is on a clipped part of prop
e2function number entity:acfHitClip(vector HitPos)
	if not validPhysics(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return ACF.CheckClips(this, HitPos) and 1 or 0
end

-- Returns all the linked entities
e2function array entity:acfLinks()
	if not IsACFEntity(this) then return {} end
	if RestrictInfo(self, this) then return {} end

	local Result = {}
	local Count = 0

	for Entity in pairs(ACF.GetLinkedEntities(this)) do
		Count = Count + 1

		Result[Count] = Entity
	end

	return Result
end

--allows e2 to perform ACF links
e2function number entity:acfLinkTo(entity Target, number Notify)
	if not validPhysics(this) then return 0 end
	if not validPhysics(Target) then return 0 end
	if not (isOwner(self, this) and isOwner(self, Target)) then
		if Notify ~= 0 then
			ACF.SendNotify(self.player, 0, "Must be called on entities you own.")
		end

		return 0
	end

	if not this.Link then
		if Notify ~= 0 then
			ACF.SendNotify(self.player, 0, "This entity is not linkable.")
		end

		return 0
	end

	local Sucess, Message = this:Link(Target)

	if Notify ~= 0 then
		ACF.SendNotify(self.player, Sucess, Message)
	end

	return Sucess and 1 or 0
end

--allows e2 to perform ACF unlinks
e2function number entity:acfUnlinkFrom(entity Target, number Notify)
	if not validPhysics(this) then return 0 end
	if not validPhysics(Target) then return 0 end
	if not (isOwner(self, this) and isOwner(self, Target)) then
		if Notify ~= 0 then
			ACF.SendNotify(self.player, 0, "Must be called on entities you own.")
		end

		return 0
	end

	if not this.Unlink then
		if Notify ~= 0 then
			ACF.SendNotify(self.player, 0, "This entity is not linkable.")
		end

		return 0
	end

	local Sucess, Message = this:Unlink(Target)

	if Notify > 0 then
		ACF.SendNotify(self.player, Sucess, Message)
	end

	return Sucess and 1 or 0
end

--===============================================================================================--
-- Mobility Functions
--===============================================================================================--

__e2setcost(5)

-- Returns 1 if an ACF engine is electric
e2function number entity:acfIsElectric()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.IsElectric and 1 or 0
end

-- Returns the torque in N/m of an ACF engine
e2function number entity:acfMaxTorque()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.PeakTorque or 0
end

-- Returns the power in kW of an ACF engine
e2function number entity:acfMaxPower()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.PeakPower and math.Round(this.PeakPower) or 0
end

e2function number entity:acfMaxTorqueWithFuel()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end
	if not this.PeakTorque then return 0 end

	return this.PeakTorque
end

e2function number entity:acfMaxPowerWithFuel()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.PeakPower and math.Round(this.PeakPower) or 0
end

-- Returns the idle rpm of an ACF engine
e2function number entity:acfIdleRPM()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.IdleRPM or 0
end

-- Returns the powerband min of an ACF engine
e2function number entity:acfPowerbandMin()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end
	if not this.PeakMinRPM then return 0 end

	if this.IsElectric and this.IdleRPM then
		return math.max(this.IdleRPM, this.PeakMinRPM)
	end

	return this.PeakMinRPM
end

-- Returns the powerband max of an ACF engine
e2function number entity:acfPowerbandMax()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	if this.IsElectric and this.LimitRPM then
		return floor(this.LimitRPM * 0.5)
	end

	return this.PeakMaxRPM or 0
end

-- Returns the redline rpm of an ACF engine
e2function number entity:acfRedline()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.LimitRPM or 0
end

-- Returns the current rpm of an ACF engine
e2function number entity:acfRPM()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	local FlyRPM = this.FlyRPM

	return FlyRPM and floor(FlyRPM) or 0
end

-- Returns the current torque of an ACF engine
e2function number entity:acfTorque()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	local Torque = this.Torque

	return Torque and floor(Torque) or 0
end

-- Returns the inertia of an ACF engine's flywheel
e2function number entity:acfFlyInertia()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.Inertia or 0
end

-- Returns the mass of an ACF engine's flywheel
e2function number entity:acfFlyMass()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.FlywheelMass or 0
end

-- Returns the current power of an ACF engine
e2function number entity:acfPower()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end
	if not this.Torque then return 0 end
	if not this.FlyRPM then return 0 end

	return floor(this.Torque * this.FlyRPM / 9548.8)
end

-- Returns 1 if the RPM of an ACF engine is inside the powerband
e2function number entity:acfInPowerband()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end
	if not this.FlyRPM then return 0 end

	local PowerbandMin
	local PowerbandMax

	if this.IsElectric then
		PowerbandMin = this.IdleRPM
		PowerbandMax = floor((this.LimitRPM or 0) * 0.5)
	else
		PowerbandMin = this.PeakMinRPM
		PowerbandMax = this.PeakMaxRPM
	end

	if not PowerbandMin then return 0 end
	if not PowerbandMax then return 0 end
	if this.FlyRPM < PowerbandMin then return 0 end
	if this.FlyRPM > PowerbandMax then return 0 end

	return 1
end

-- Returns the throttle of an ACF engine
e2function number entity:acfThrottle()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	local Throttle = this.Throttle

	return Throttle and Throttle * 100 or 0
end

-- Sets the throttle value for an ACF engine
e2function void entity:acfThrottle(number Throttle)
	if not IsACFEntity(this) then return end
	if not isOwner(self, this) then return end

	this:TriggerInput("Throttle", Throttle)
end

-- Returns the current gear for an ACF gearbox
e2function number entity:acfGear()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.Gear or 0
end

-- Returns the number of gears for an ACF gearbox
e2function number entity:acfNumGears()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.GearCount or 0
end

-- Returns the final ratio for an ACF gearbox
e2function number entity:acfFinalRatio()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.FinalDrive or 0
end

-- Returns the total ratio (current gear * final) for an ACF gearbox
e2function number entity:acfTotalRatio()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.GearRatio or 0
end

-- Returns the max torque for an ACF gearbox
e2function number entity:acfTorqueRating()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.MaxTorque or 0
end

-- Returns whether an ACF gearbox is dual clutch
e2function number entity:acfIsDual()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.DualClutch and 1 or 0
end

-- Returns the time in ms an ACF gearbox takes to change gears
e2function number entity:acfShiftTime()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	local Time = this.SwitchTime

	return Time and Time * 1000 or 0
end

-- Returns 1 if an ACF gearbox is in gear
e2function number entity:acfInGear()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.InGear and 1 or 0
end

-- Returns the ratio for a specified gear of an ACF gearbox
e2function number entity:acfGearRatio(number Gear)
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end
	if not this.Gears then return 0 end

	return this.Gears[floor(Gear)] or 0
end

-- Returns the current torque output for an ACF gearbox
e2function number entity:acfTorqueOut()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return math.min(this.TotalReqTq or 0, this.MaxTorque or 0) / (this.GearRatio or 1)
end

-- Sets the gear ratio of a CVT, set to 0 to use built-in algorithm
e2function void entity:acfCVTRatio(number Ratio)
	if not IsACFEntity(this) then return end
	if not isOwner(self, this) then return end

	this:TriggerInput("CVT Ratio", math.Clamp(Ratio, 0, 1))
end

-- Sets the current gear for an ACF gearbox
e2function void entity:acfShift(number Gear)
	if not IsACFEntity(this) then return end
	if not isOwner(self, this) then return end

	this:TriggerInput("Gear", Gear)
end

-- Cause an ACF gearbox to shift up
e2function void entity:acfShiftUp()
	if not IsACFEntity(this) then return end
	if not isOwner(self, this) then return end

	this:TriggerInput("Gear Up", 1) --doesn't need to be toggled off
end

-- Cause an ACF gearbox to shift down
e2function void entity:acfShiftDown()
	if not IsACFEntity(this) then return end
	if not isOwner(self, this) then return end

	this:TriggerInput("Gear Down", 1) --doesn't need to be toggled off
end

-- Sets the brakes for an ACF gearbox
e2function void entity:acfBrake(number Brake)
	if not IsACFEntity(this) then return end
	if not isOwner(self, this) then return end

	this:TriggerInput("Brake", Brake)
end

-- Sets the left brakes for an ACF gearbox
e2function void entity:acfBrakeLeft(number Brake)
	if not IsACFEntity(this) then return end
	if not isOwner(self, this) then return end

	this:TriggerInput("Left Brake", Brake)
end

-- Sets the right brakes for an ACF gearbox
e2function void entity:acfBrakeRight(number Brake)
	if not IsACFEntity(this) then return end
	if not isOwner(self, this) then return end

	this:TriggerInput("Right Brake", Brake)
end

-- Sets the clutch for an ACF gearbox
e2function void entity:acfClutch(number Clutch)
	if not IsACFEntity(this) then return end
	if not isOwner(self, this) then return end

	this:TriggerInput("Clutch", Clutch)
end

-- Sets the left clutch for an ACF gearbox
e2function void entity:acfClutchLeft(number Clutch)
	if not IsACFEntity(this) then return end
	if not isOwner(self, this) then return end

	this:TriggerInput("Left Clutch", Clutch)
end

-- Sets the right clutch for an ACF gearbox
e2function void entity:acfClutchRight(number Clutch)
	if not IsACFEntity(this) then return end
	if not isOwner(self, this) then return end

	this:TriggerInput("Right Clutch", Clutch)
end

-- Sets the steer ratio for an ACF double differential gearbox
e2function void entity:acfSteerRate(number Rate)
	if not IsACFEntity(this) then return end
	if not isOwner(self, this) then return end

	this:TriggerInput("Steer Rate", Rate)
end

-- Applies gear hold for an automatic ACF gearbox
e2function void entity:acfHoldGear(number Hold)
	if not IsACFEntity(this) then return end
	if not isOwner(self, this) then return end

	this:TriggerInput("Hold Gear", Hold)
end

-- Sets the shift point scaling for an automatic ACF gearbox
e2function void entity:acfShiftPointScale(number Scale)
	if not IsACFEntity(this) then return end
	if not isOwner(self, this) then return end

	this:TriggerInput("Shift Speed Scale", Scale)
end

-- Sets the ACF fuel tank refuel duty status, which supplies fuel to other fuel tanks
e2function void entity:acfRefuelDuty(number On)
	if not IsACFEntity(this) then return end
	if not isOwner(self, this) then return end

	this:TriggerInput("Refuel Duty", On)
end

e2function void entity:acfDisableRevLimiter(number Disabled)
	if not this.IsACFEngine then return end
	if RestrictInfo(self, this) then return end

	this.revLimiterEnabled = not tobool(Disabled)
end

__e2setcost(10)

-- Returns the remaining liters or kilowatt hours of fuel in an ACF fuel tank or engine
e2function number entity:acfFuel()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end
	if this.Fuel then return Round(this.Fuel, 2) end

	local Fuel = 0
	local Source = ACF.GetLinkSource(this:GetClass(), "FuelTanks")

	if not Source then return 0 end

	for Tank in pairs(Source(this)) do
		Fuel = Fuel + Tank.Fuel
	end

	return Round(Fuel, 2)
end

-- Returns the amount of fuel in an ACF fuel tank or linked to engine as a percentage of capacity
e2function number entity:acfFuelLevel()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end
	if this.Capacity then return Round((this.Fuel or 0) / this.Capacity, 2) end

	local Fuel = 0
	local Capacity = 0
	local Source = ACF.GetLinkSource(this:GetClass(), "FuelTanks")

	if not Source then return 0 end

	for Tank in pairs(Source(this)) do
		Fuel = Fuel + Tank.Fuel
		Capacity = Capacity + Tank.Capacity
	end

	return Round(Fuel / Capacity, 2)
end

-- Returns the current fuel consumption in liters per minute or kilowatts of an engine
e2function number entity:acfFuelUse()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end
	if not this.GetConsumption then return 0 end
	if not this.Throttle then return 0 end
	if not this.FlyRPM then return 0 end

	return this:GetConsumption(this.Throttle, this.FlyRPM) * 60
end

-- Returns the peak fuel consumption in liters per minute or kilowatts of an engine at powerband max, for the current fuel type the engine is using
e2function number entity:acfPeakFuelUse()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end
	if not this.GetConsumption then return 0 end
	if not this.LimitRPM then return 0 end

	return this:GetConsumption(1, this.LimitRPM) * 60
end

__e2setcost(20)

-- returns any wheels linked to this engine/gearbox or child gearboxes
e2function array entity:acfGetLinkedWheels()
	if not IsACFEntity(this) then return {} end
	if RestrictInfo(self, this) then return {} end

	local Wheels = {}
	local Count = 0

	for Wheel in pairs(GetLinkedWheels(this)) do
		Count = Count + 1
		Wheels[Count] = Wheel
	end

	return Wheels
end

--===============================================================================================--
-- Weaponry Functions
--===============================================================================================--

__e2setcost(5)

-- Returns 1 if the ACF gun is ready to fire
e2function number entity:acfReady()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.State == "Loaded" and 1 or 0
end

-- Returns the state of the ACF entity
e2function string entity:acfState()
	if not IsACFEntity(this) then return "" end
	if RestrictInfo(self, this) then return "" end

	return this.State or ""
end

-- Returns time to next shot of an ACF weapon
e2function number entity:acfReloadTime()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end
	if this.State == "Loaded" then return 0 end

	return GetReloadTime(this)
end

-- Returns number between 0 and 1 which represents reloading progress of an ACF weapon. Useful for progress bars
e2function number entity:acfReloadProgress()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end
	if not this.NextFire then return this.State == "Loaded" and 1 or 0 end

	return math.Clamp(1 - (this.NextFire - Clock.CurTime) / GetReloadTime(this), 0, 1)
end

-- Round functions

-- Returns the rounds left in an acf entity
--[[
	If its a weapon:
		If it is just a breech loaded weapon, 1 if its loaded otherwise 0
		If it has a magazine, number of rounds in the magazine currently
	Otherwise its a crate, returning the number of rounds in the crate
]]--
e2function number entity:acfRounds()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.CurrentShot or this.Ammo or 0
end

--Returns the number of rounds in active ammo crates linked to an ACF weapon
e2function number entity:acfAmmoCount()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	local Count = 0
	local Source = ACF.GetLinkSource(this:GetClass(), "Crates")

	if not Source then return 0 end

	for Crate in pairs(Source(this)) do
		if Crate:CanConsume() then
			Count = Count + Crate.Ammo
		end
	end

	return Count
end

--Returns the number of rounds in all ammo crates linked to an ACF weapon
e2function number entity:acfTotalAmmoCount()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	local Count = 0
	local Source = ACF.GetLinkSource(this:GetClass(), "Crates")

	if not Source then return 0 end

	for Crate in pairs(Source(this)) do
		Count = Count + Crate.Ammo
	end

	return Count
end

-- Returns the magazine size for an ACF gun
e2function number entity:acfMagSize()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.MagSize or 0
end

-- Returns the number of rounds left in a magazine for an ACF gun
e2function number entity:acfMagRounds()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.CurrentShot or 0
end

-- returns time it takes for an ACF weapon to reload magazine
e2function number entity:acfMagReloadTime()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.MagReload or 0
end

-- Returns the spread for an ACF gun or flechette ammo
e2function number entity:acfSpread()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	local Spread = (this.GetSpread and this:GetSpread()) or this.Spread or 0

	if this.BulletData and this.BulletData.Type == "FL" then
		return Spread + (this.BulletData.FlechetteSpread or 0)
	end

	return Spread
end

-- Returns 1 if an ACF gun is reloading
e2function number entity:acfIsReloading()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.State == "Loading" and 1 or 0
end

-- Returns the rate of fire of an acf gun
e2function number entity:acfFireRate()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	local Time = this.ReloadTime

	return Time and Round(60 / Time, 2) or 0
end

-- Sets the firing state of an ACF weapon
e2function void entity:acfFire(number Fire)
	if not IsACFEntity(this) then return end
	if not isOwner(self, this) then return end

	this:TriggerInput("Fire", Fire)
end

-- Causes an ACF weapon to unload
e2function void entity:acfUnload()
	if not IsACFEntity(this) then return end
	if not isOwner(self, this) then return end

	this:TriggerInput("Unload", 1)
end

-- Causes an ACF weapon to reload
e2function void entity:acfReload()
	if not IsACFEntity(this) then return end
	if not isOwner(self, this) then return end

	this:TriggerInput("Reload", 1)
end

-- Returns the type of weapon the ammo in an ACF ammo crate loads into
e2function string entity:acfRoundType()
	if not IsACFEntity(this) then return "" end
	if RestrictInfo(self, this) then return "" end

	local BulletData = this.BulletData

	return BulletData and BulletData.Id or ""
end

-- Returns the type of ammo in a crate or gun
e2function string entity:acfAmmoType()
	if not IsACFEntity(this) then return "" end
	if RestrictInfo(self, this) then return "" end

	local BulletData = this.BulletData

	return BulletData and BulletData.Type or ""
end

-- Returns the caliber of an ammo
e2function number entity:acfCaliber()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.Caliber or 0
end

-- Returns the muzzle velocity of the ammo in a crate or gun
e2function number entity:acfMuzzleVel()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	local BulletData = this.BulletData
	local MuzzleVel  = BulletData and BulletData.MuzzleVel

	return MuzzleVel and MuzzleVel * ACF.Scale or 0
end

-- Returns the mass of the projectile in a crate or gun
e2function number entity:acfProjectileMass()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	local BulletData = this.BulletData

	return BulletData and BulletData.ProjMass or 0
end

e2function number entity:acfDragCoef()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	local BulletData = this.BulletData
	local DragCoef   = BulletData and BulletData.DragCoef

	return DragCoef and DragCoef / ACF.DragDiv or 0
end

-- Returns the fin multiplier of the missile/bomb
e2function number entity:acfFinMul()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.FinMultiplier or 0
end

-- Returns the weight of the missile
e2function number entity:acfMissileWeight()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.ForcedMass or 0
end

-- Returns the length of the missile
e2function number entity:acfMissileLength()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return this.Length or 0
end

-- Returns the number of projectiles in a flechette round
e2function number entity:acfFLSpikes()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	local BulletData = this.BulletData

	return BulletData and BulletData.Flechettes or 0
end

-- Returns the mass of a single spike in a FL round in a crate or gun
e2function number entity:acfFLSpikeMass()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	local BulletData = this.BulletData

	return BulletData and BulletData.FlechetteMass or 0
end

-- Returns the radius of the spikes in a flechette round in mm
e2function number entity:acfFLSpikeRadius()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	local BulletData = this.BulletData
	local Radius     = BulletData and BulletData.FlechetteRadius

	return Radius and Round(Radius * 10, 2) or 0
end

__e2setcost(10)

-- Returns the penetration of an ACF round
e2function number entity:acfPenetration()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	local BulletData = this.BulletData
	local AmmoType   = BulletData and AmmoTypes.Get(BulletData.Type)

	if not AmmoType then return 0 end

	local DisplayData = AmmoType:GetDisplayData(BulletData)
	local MaxPen      = DisplayData and DisplayData.MaxPen

	return MaxPen and Round(MaxPen, 2) or 0
end

-- Returns the blast radius of an ACF round
e2function number entity:acfBlastRadius()
	if not IsACFEntity(this) then return 0 end
	if RestrictInfo(self, this) then return 0 end

	local BulletData = this.BulletData
	local AmmoType   = BulletData and AmmoTypes.Get(BulletData.Type)

	if not AmmoType then return 0 end

	local DisplayData = AmmoType:GetDisplayData(BulletData)
	local Radius      = DisplayData and DisplayData.BlastRadius

	return Radius and Round(Radius, 2) or 0
end

--===============================================================================================--
-- Turret Functions
--===============================================================================================--

__e2setcost(5)


-- Getters --

-- Returns the turret's current angle
e2function number entity:acfGetTurretAngle()
	if not this.IsACFTurret then return 0 end
	if RestrictInfo(self, this) then return 0 end

	return math.Round(-this.CurrentAngle,4)
end

-- Returns the turret's linked gyroscope
e2function entity entity:acfGetTurretGyro()
	if not this.IsACFTurret then return end
	if RestrictInfo(self, this) then return end

	return IsValid(this.Gyro) and this.Gyro or nil
end

-- Returns the turret's linked gyroscope
e2function entity entity:acfGetTurretMotor()
	if not this.IsACFTurret then return end
	if RestrictInfo(self, this) then return end

	return IsValid(this.Motor) and this.Motor or nil
end

-- Returns the turret's loaded mass, in kg
e2function number entity:acfGetTurretMass()
	if not this.IsACFTurret then return end
	if RestrictInfo(self, this) then return end

	return math.Round(this.TurretData.TotalMass,2)
end

-- Returns the turret's center of mass, local to the turret
e2function vector entity:acfGetTurretMassCenter()
	if not this.IsACFTurret then return end
	if RestrictInfo(self, this) then return end

	return this:WorldToLocal(this.Rotator:LocalToWorld(this.TurretData.LocalCoM))
end

-- Returns the turret's current slew rate, in degrees/second
e2function number entity:acfGetTurretSlewRate()
	if not this.IsACFTurret then return end
	if RestrictInfo(self, this) then return end

	return math.Round(-this.SlewRate / Clock.DeltaTime,2)
end

-- Returns the turret's top slew rate, in degrees/second
e2function number entity:acfGetTurretMaxSlewRate()
	if not this.IsACFTurret then return end
	if RestrictInfo(self, this) then return end

	return math.Round(this.MaxSlewRate,2)
end

-- Returns the turret's acceleration, in degrees/second ^ 2
e2function number entity:acfGetTurretSlewAccel()
	if not this.IsACFTurret then return end
	if RestrictInfo(self, this) then return end

	return math.Round(this.SlewAccel,4)
end

-- Returns whether or not the turret is stabilized, and the percentage (0-1)
e2function number entity:acfGetTurretStabilized()
	if not this.IsACFTurret then return end
	if RestrictInfo(self, this) then return end

	return this.Stabilized and this.StabilizeAmount or 0
end

-- Returns the turret's data
e2function table entity:acfGetTurretData()
	local ret = newE2Table()
	if not this.IsACFTurret then return ret end
	if RestrictInfo(self, this) then return ret end

	local Data = {
		MaxSlewRate		= math.Round(this.MaxSlewRate,2),
		SlewAccel		= math.Round(this.SlewAccel,4),
		Angle			= -this.CurrentAngle,

		Stabilized		= this.Stabilized,
		StabilizeAmount	= this.StabilizeAmount,

		HasArc			= this.HasArc,
		Minimum			= this.MinDeg,
		Maximum			= this.MaxDeg,

		TotalMass		= this.TurretData.TotalMass,
		LocalMassCenter	= IsValid(this.Rotator) and this:WorldToLocal(this.Rotator:LocalToWorld(this.TurretData.LocalCoM)) or Vector(),

		Motor			= IsValid(this.Motor) and this.Motor or nil,
		Gyro			= IsValid(this.Gyro) and this.Gyro or nil,
	}

	for k,v in pairs(Data) do
		local tid = typeids[k]

		ret.n[k] = v
		ret.ntypes[k] = tid
	end

	ret.size = 12

	return ret
end

-- Setters --

-- Makes the turret go back to home angle
e2function void entity:acfCenterTurret()
	if not this.IsACFTurret then return end
	if not isOwner(self, this) then return end

	this:InputDirection(0)
end

-- Makes the turret attempt to point to the requested degree
e2function void entity:acfAimTurret(number Degree)
	if not this.IsACFTurret then return end
	if not isOwner(self, this) then return end

	this:InputDirection(Degree)
end

-- Makes the turret attempt to point to the angle
e2function void entity:acfAimTurret(angle Angle)
	if not this.IsACFTurret then return end
	if not isOwner(self, this) then return end

	this:InputDirection(Angle)
end

-- Makes the turret attempt to point to the position
e2function void entity:acfAimTurret(vector Position)
	if not this.IsACFTurret then return end
	if not isOwner(self, this) then return end

	this:InputDirection(Position)
end