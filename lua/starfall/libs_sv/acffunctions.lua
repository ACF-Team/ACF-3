-- [ To Do ] --

-- #general

-- #engine

-- #gearbox

-- #gun
--use an input to set reload manually, to remove timer?

-- #ammo

-- #prop armor
--get incident armor ?
--hit calcs ?
--conversions ?

-- #fuel

--===============================================================================================--
-- Local Variables and Helper Functions
--===============================================================================================--

local RestrictInfoConVar = GetConVar("sbox_acf_restrictinfo")
local AllLinkSources = ACF.GetAllLinkSources
local LinkSource = ACF.GetLinkSource
local RoundTypes = ACF.RoundTypes
local CheckType = SF.CheckType
local CheckLuaType = SF.CheckLuaType
local match = string.match
local floor = math.floor
local Round = math.Round

local function ValidPhysics(Entity)
	if not IsValid(Entity) then return false end
	if Entity:IsWorld() then return false end
	if Entity:GetMoveType() ~= MOVETYPE_VPHYSICS then return false end

	return IsValid(Entity:GetPhysicsObject())
end

local function IsACFEntity(Entity)
	if not ValidPhysics(Entity) then return false end

	local Match = match(Entity:GetClass(), "^acf_")

	return Match and true or false
end

local function IsOwner(Player, Entity)
	if not CPPI then return true end

	return Entity:CPPIGetOwner() == Player
end

local function RestrictInfo(Player, Entity)
	if RestrictInfoConVar:GetInt() == 0 then return false end

	return not IsOwner(Player, Entity)
end

local function GetReloadTime(Entity)
	return Entity.OnReload and Entity.MagReload or Entity.ReloadTime or 0
end

local function GetMaxPower(Entity)
	if not Entity.PeakTorque then return 0 end

	local MaxPower

	if Entity.IsElectric then
		if not Entity.LimitRPM then return 0 end

		MaxPower = floor(Entity.PeakTorque * Entity.LimitRPM / 38195.2) --(4*9548.8)
	else
		if not Entity.PeakMaxRPM then return 0 end

		MaxPower = floor(Entity.PeakTorque * Entity.PeakMaxRPM / 9548.8)
	end

	return MaxPower
end

local function GetLinkedWheels(Target)
	local Current, Class, Sources
	local Queued = { [Target] = true }
	local Checked = {}
	local Linked = {}

	while next(Queued) do
		Current = next(Queued)
		Class = Current:GetClass()
		Sources = AllLinkSources(Class)

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

SF.AddHook("postload", function()
	local vec_metatable = SF.Vectors.Metatable
	local ents_metatable = SF.Entities.Metatable
	local ents_methods = SF.Entities.Methods
	local wrap, unwrap = SF.Entities.Wrap, SF.Entities.Unwrap

	--===============================================================================================--
	-- General Functions
	--===============================================================================================--

	-- Returns true if functions returning sensitive info are restricted to owned props
	function ents_methods:acfInfoRestricted()
		return RestrictInfoConVar:GetInt() ~= 0
	end

	-- Returns the full name of an ACF entity
	function ents_methods:acfName()
		local This = unwrap(self)

		if not IsACFEntity(This) then return "" end
		if RestrictInfo(self, This) then return "" end

		return This.Name or ""
	end

	-- Returns the short name of an ACF entity
	function ents_methods:acfNameShort()
		local This = unwrap(self)

		if not IsACFEntity(This) then return "" end
		if RestrictInfo(SF.instance.player, This) then return "" end

		return This.ShortName or ""
	end

	-- Returns the type of ACF entity
	function ents_methods:acfType()
		local This = unwrap(self)

		if not IsACFEntity(This) then return "" end
		if RestrictInfo(SF.instance.player, This) then return "" end

		return This.EntType or ""
	end

	-- Returns true if the entity is an ACF engine
	function ents_methods:acfIsEngine()
		local This = unwrap(self)

		if not ValidPhysics(This) then return false end
		if RestrictInfo(SF.instance.player, This) then return false end

		return This:GetClass() == "acf_engine"
	end

	-- Returns true if the entity is an ACF gearbox
	function ents_methods:acfIsGearbox()
		local This = unwrap(self)

		if not ValidPhysics(This) then return false end
		if RestrictInfo(SF.instance.player, This) then return false end

		return This:GetClass() == "acf_gearbox"
	end

	-- Returns true if the entity is an ACF gun
	function ents_methods:acfIsGun()
		local This = unwrap(self)

		if not ValidPhysics(This) then return false end
		if RestrictInfo(SF.instance.player, This) then return false end

		return This:GetClass() == "acf_gun"
	end

	-- Returns true if the entity is an ACF ammo crate
	function ents_methods:acfIsAmmo()
		local This = unwrap(self)

		if not ValidPhysics(This) then return false end
		if RestrictInfo(SF.instance.player, This) then return false end

		return This:GetClass() == "acf_ammo"
	end

	-- Returns true if the entity is an ACF fuel tank
	function ents_methods:acfIsFuel()
		local This = unwrap(self)

		if not ValidPhysics(This) then return false end
		if RestrictInfo(SF.instance.player, This) then return false end

		return This:GetClass() == "acf_fueltank"
	end

	-- Returns the capacity of an acf ammo crate or fuel tank
	function ents_methods:acfCapacity()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end

		return This.Capacity or 0
	end

	-- Returns the path of an ACF entity's sound
	function ents_methods:acfSoundPath()
		local This = unwrap(self)

		if not IsACFEntity(This) then return "" end
		if RestrictInfo(SF.instance.player, This) then return "" end

		return This.SoundPath or ""
	end

	-- Returns true if the acf engine, fuel tank, or ammo crate is active
	function ents_methods:acfGetActive()
		local This = unwrap(self)

		if not IsACFEntity(This) then return false end
		if RestrictInfo(SF.instance.player, This) then return false end

		return (This.Active or This.Load) and true or false
	end

	-- Turns an ACF engine, ammo crate, or fuel tank on or off
	function ents_methods:acfSetActive(On)
		CheckLuaType(On, TYPE_BOOL)

		local This = unwrap(self)

		if not IsACFEntity(This) then return end
		if not IsOwner(SF.instance.player, This) then return end

		This:TriggerInput("Active", On and 1 or 0)
	end

	-- Returns the current health of an entity
	function ents_methods:acfPropHealth()
		local This = unwrap(self)

		if not ValidPhysics(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not ACF_Check(This) then return 0 end
		if not This.ACF.Health then return 0 end

		return Round(This.ACF.Health, 2)
	end

	-- Returns the current armor of an entity
	function ents_methods:acfPropArmor()
		local This = unwrap(self)

		if not ValidPhysics(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not ACF_Check(This) then return 0 end
		if not This.ACF.Armour then return 0 end

		return Round(This.ACF.Armour, 2)
	end

	-- Returns the max health of an entity
	function ents_methods:acfPropHealthMax()
		local This = unwrap(self)

		if not ValidPhysics(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not ACF_Check(This) then return 0 end
		if not This.ACF.MaxHealth then return 0 end

		return Round(This.ACF.MaxHealth, 2)
	end

	-- Returns the max armor of an entity
	function ents_methods:acfPropArmorMax()
		local This = unwrap(self)

		if not ValidPhysics(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not ACF_Check(This) then return 0 end
		if not This.ACF.MaxArmour then return 0 end

		return Round(This.ACF.MaxArmour, 2)
	end

	-- Returns the ductility of an entity
	function ents_methods:acfPropDuctility()
		local This = unwrap(self)

		if not ValidPhysics(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not ACF_Check(This) then return 0 end
		if not This.ACF.Ductility then return 0 end

		return This.ACF.Ductility * 100
	end

	--returns true if hitpos is on a clipped part of prop
	function ents_methods:acfHitClip(HitPos)
		CheckType(HitPos, vec_metatable)

		local This = unwrap(self)

		if not ValidPhysics(This) then return false end
		if RestrictInfo(SF.instance.player, This) then return false end

		return ACF_CheckClips(This, HitPos)
	end

	-- Returns the ACF links associated with the entity
	function ents_methods:acfLinks()
		local This = unwrap(self)

		if not IsACFEntity(This) then return {} end
		if RestrictInfo(SF.instance.player, This) then return {} end

		local Sources = AllLinkSources(This:GetClass())
		local Result = {}
		local Count = 0

		for _, Function in pairs(Sources) do
			for Entity in pairs(Function(This)) do
				Count = Count + 1
				Result[Count] = wrap(Entity)
			end
		end

		return Result
	end

	--perform ACF links
	function ents_methods:acfLinkTo(Target, Notify)
		CheckType(Target, ents_metatable)
		CheckLuaType(Notify, TYPE_BOOL)

		local This = unwrap(self)
		local TargetEnt = unwrap(Target)

		if not validPhysics(This) then return false end
		if not validPhysics(TargetEnt) then return false end
		if not (IsOwner(SF.instance.player, This) and IsOwner(SF.instance.player, TargetEnt)) then
			if Notify then
				ACF_SendNotify(SF.instance.player, 0, "Must be called on entities you own.")
			end

			return false
		end

		if not This.Link then
			if Notify then
				ACF_SendNotify(SF.instance.player, 0, "This entity is not linkable.")
			end

			return false
		end

		local Sucess, Message = This:Link(TargetEnt)

		if Notify then
			ACF_SendNotify(SF.instance.player, Sucess, Message)
		end

		return Sucess
	end

	--perform ACF unlinks
	function ents_methods:acfUnlinkFrom(Target, Notify)
		CheckType(Target, ents_metatable)
		CheckLuaType(Notify, TYPE_BOOL)

		local This = unwrap(self)
		local TargetEnt = unwrap(Target)

		if not validPhysics(This) then return false end
		if not validPhysics(TargetEnt) then return false end
		if not (IsOwner(SF.instance.player, This) and IsOwner(SF.instance.player, TargetEnt)) then
			if Notify then
				ACF_SendNotify(SF.instance.player, 0, "Must be called on entities you own.")
			end

			return false
		end

		if not This.Unlink then
			if Notify then
				ACF_SendNotify(SF.instance.player, 0, "This entity is not linkable.")
			end

			return false
		end

		local Sucess, Message = This:Unlink(TargetEnt)

		if Notify then
			ACF_SendNotify(SF.instance.player, Sucess, Message)
		end

		return Sucess
	end

	--===============================================================================================--
	-- Mobility Functions
	--===============================================================================================--

	-- Returns true if an ACF entity is electric
	function ents_methods:acfIsElectric()
		local This = unwrap(self)

		if not IsACFEntity(This) then return false end
		if RestrictInfo(SF.instance.player, This) then return false end

		return This.IsElectric or false
	end

	-- Returns the torque in N/m of an ACF engine
	function ents_methods:acfMaxTorque()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end

		return This.PeakTorque or 0
	end

	-- Returns the power in kW of an ACF engine
	function ents_methods:acfMaxPower()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end

		return GetMaxPower(This)
	end

	function ents_methods:acfMaxTorqueWithFuel()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not This.PeakTorque then return 0 end

		return This.PeakTorque * ACF.TorqueBoost
	end

	function ents_methods:acfMaxPowerWithFuel()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end

		return GetMaxPower(This) * ACF.TorqueBoost
	end

	-- Returns the idle rpm of an ACF engine
	function ents_methods:acfIdleRPM()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end

		return This.IdleRPM or 0
	end

	-- Returns the powerband min of an ACF engine
	function ents_methods:acfPowerbandMin()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not This.PeakMinRPM then return 0 end

		if This.IsElectric and This.IdleRPM then
			return math.max(This.IdleRPM, This.PeakMinRPM)
		end

		return This.PeakMinRPM
	end

	-- Returns the powerband max of an ACF engine
	function ents_methods:acfPowerbandMax()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end

		if This.IsElectric and This.LimitRPM then
			return floor(This.LimitRPM * 0.5)
		end

		return This.PeakMaxRPM or 0
	end

	-- Returns the redline rpm of an ACF engine
	function ents_methods:acfRedline()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end

		return This.LimitRPM or 0
	end

	-- Returns the current rpm of an ACF engine
	function ents_methods:acfRPM()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not This.FlyRPM then return 0 end

		return floor(This.FlyRPM)
	end

	-- Returns the current torque of an ACF engine
	function ents_methods:acfTorque()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not This.Torque then return 0 end

		return floor(This.Torque)
	end

	-- Returns the inertia of an ACF engine's flywheel
	function ents_methods:acfFlyInertia()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end

		return This.Inertia or 0
	end

	-- Returns the mass of an ACF engine's flywheel
	function ents_methods:acfFlyMass()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not This.Inertia then return 0 end

		return (This.Inertia / 3.1416) * (This.Inertia / 3.1416)
	end

	--- Returns the current power of an ACF engine
	function ents_methods:acfPower()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not This.Torque then return 0 end
		if not This.FlyRPM then return 0 end

		return floor(This.Torque * This.FlyRPM / 9548.8)
	end

	-- Returns true if the RPM of an ACF engine is inside the powerband
	function ents_methods:acfInPowerband()
		local This = unwrap(self)

		if not IsACFEntity(This) then return false end
		if RestrictInfo(SF.instance.player, This) then return false end
		if not This.FlyRPM then return false end

		local PowerbandMin
		local PowerbandMax

		if This.IsElectric then
			PowerbandMin = This.IdleRPM
			PowerbandMax = floor((This.LimitRPM or 0) * 0.5)
		else
			PowerbandMin = This.PeakMinRPM
			PowerbandMax = This.PeakMaxRPM
		end

		if not PowerbandMin then return false end
		if not PowerbandMax then return false end
		if This.FlyRPM < PowerbandMin then return false end
		if This.FlyRPM > PowerbandMax then return false end

		return true
	end

	function ents_methods:acfGetThrottle()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not This.Throttle then return 0 end

		return This.Throttle * 100
	end

	-- Sets the throttle value for an ACF engine
	function ents_methods:acfSetThrottle(Throttle)
		CheckLuaType(Throttle, TYPE_NUMBER)

		local This = unwrap(self)

		if not IsACFEntity(This) then return false end
		if RestrictInfo(SF.instance.player, This) then return false end

		This:TriggerInput("Throttle", Throttle)
	end

	-- Returns the current gear for an ACF gearbox
	function ents_methods:acfGear()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end

		return This.Gear or 0
	end

	-- Returns the number of gears for an ACF gearbox
	function ents_methods:acfNumGears()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end

		return This.Gears or 0
	end

	-- Returns the final ratio for an ACF gearbox
	function ents_methods:acfFinalRatio()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not This.GearTable then return 0 end

		return This.GearTable.Final or 0
	end

	-- Returns the total ratio (current gear * final) for an ACF gearbox
	function ents_methods:acfTotalRatio()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end

		return This.GearRatio or 0
	end

	-- Returns the max torque for an ACF gearbox
	function ents_methods:acfTorqueRating()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end

		return This.MaxTorque or 0
	end

	-- Returns whether an ACF gearbox is dual clutch
	function ents_methods:acfIsDual()
		local This = unwrap(self)

		if not IsACFEntity(This) then return false end
		if RestrictInfo(SF.instance.player, This) then return false end

		return This.Dual or false
	end

	-- Returns the time in ms an ACF gearbox takes to change gears
	function ents_methods:acfShiftTime()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not This.SwitchTime then return 0 end

		return This.SwitchTime * 1000
	end

	-- Returns true if an ACF gearbox is in gear
	function ents_methods:acfInGear()
		local This = unwrap(self)

		if not IsACFEntity(This) then return false end
		if RestrictInfo(SF.instance.player, This) then return false end

		return This.InGear or false
	end

	-- Returns the ratio for a specified gear of an ACF gearbox
	function ents_methods:acfGearRatio(Gear)
		CheckLuaType(Gear, TYPE_NUMBER)

		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not This.GearTable then return 0 end
		if not This.Gears then return 0 end

		local GearNum = math.Clamp(floor(Gear), 1, This.Gears)

		return This.GearTable[GearNum] or 0
	end

	-- Returns the current torque output for an ACF gearbox
	function ents_methods:acfTorqueOut()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end

		return math.min(This.TotalReqTq or 0, This.MaxTorque or 0) / (This.GearRatio or 1)
	end

	-- Sets the gear ratio of a CVT, set to 0 to use built-in algorithm
	function ents_methods:acfCVTRatio(Ratio)
		CheckLuaType(Ratio, TYPE_NUMBER)

		local This = unwrap(self)

		if not IsACFEntity(This) then return end
		if not IsOwner(SF.instance.player, This) then return end
		if not This.CVT then return end

		This:TriggerInput("CVT Ratio", math.Clamp(Ratio, 0, 1))
	end

	-- Sets the current gear for an ACF gearbox
	function ents_methods:acfShift(Gear)
		CheckLuaType(Gear, TYPE_NUMBER)

		local This = unwrap(self)

		if not IsACFEntity(This) then return end
		if not IsOwner(SF.instance.player, This) then return end

		This:TriggerInput("Gear", Gear)
	end

	-- Cause an ACF gearbox to shift up
	function ents_methods:acfShiftUp()
		local This = unwrap(self)

		if not IsACFEntity(This) then return end
		if not IsOwner(SF.instance.player, This) then return end

		This:TriggerInput("Gear Up", 1)
	end

	-- Cause an ACF gearbox to shift down
	function ents_methods:acfShiftDown()
		local This = unwrap(self)

		if not IsACFEntity(This) then return end
		if not IsOwner(SF.instance.player, This) then return end

		This:TriggerInput("Gear Down", 1)
	end

	-- Sets the brakes for an ACF gearbox
	function ents_methods:acfBrake(Brake)
		CheckLuaType(Brake, TYPE_NUMBER)

		local This = unwrap(self)

		if not IsACFEntity(This) then return end
		if not IsOwner(SF.instance.player, This) then return end

		This:TriggerInput("Brake", Brake)
	end

	-- Sets the left brakes for an ACF gearbox
	function ents_methods:acfBrakeLeft(Brake)
		CheckLuaType(Brake, TYPE_NUMBER)

		local This = unwrap(self)

		if not IsACFEntity(This) then return end
		if not IsOwner(SF.instance.player, This) then return end
		if not This.Dual then return end

		This:TriggerInput("Left Brake", Brake)
	end

	-- Sets the right brakes for an ACF gearbox
	function ents_methods:acfBrakeRight (Brake)
		CheckLuaType(Brake, TYPE_NUMBER)

		local This = unwrap(self)

		if not IsACFEntity(This) then return end
		if not IsOwner(SF.instance.player, This) then return end
		if not This.Dual then return end

		This:TriggerInput("Right Brake", Brake)
	end

	-- Sets the clutch for an ACF gearbox
	function ents_methods:acfClutch(Clutch)
		CheckLuaType(Clutch, TYPE_NUMBER)

		local This = unwrap(self)

		if not IsACFEntity(This) then return end
		if not IsOwner(SF.instance.player, This) then return end

		This:TriggerInput("Clutch", Clutch)
	end

	-- Sets the left clutch for an ACF gearbox
	function ents_methods:acfClutchLeft(Clutch)
		CheckLuaType(Clutch, TYPE_NUMBER)

		local This = unwrap(self)

		if not IsACFEntity(This) then return end
		if not IsOwner(SF.instance.player, This) then return end
		if not This.Dual then return end

		This:TriggerInput("Left Clutch", Clutch)
	end

	-- Sets the right clutch for an ACF gearbox
	function ents_methods:acfClutchRight(Clutch)
		CheckLuaType(Clutch, TYPE_NUMBER)

		local This = unwrap(self)

		if not IsACFEntity(This) then return end
		if not IsOwner(SF.instance.player, This) then return end
		if not This.Dual then return end

		This:TriggerInput("Right Clutch", Clutch)
	end

	-- Sets the steer ratio for an ACF gearbox
	function ents_methods:acfSteerRate(Rate)
		CheckLuaType(Rate, TYPE_NUMBER)

		local This = unwrap(self)

		if not IsACFEntity(This) then return end
		if not IsOwner(SF.instance.player, This) then return end
		if not This.DoubleDiff then return end

		This:TriggerInput("Steer Rate", Rate)
	end

	-- Applies gear hold for an automatic ACF gearbox
	function ents_methods:acfHoldGear(Hold)
		CheckLuaType(Hold, TYPE_BOOL)

		local This = unwrap(self)

		if not IsACFEntity(This) then return end
		if not IsOwner(SF.instance.player, This) then return end
		if not This.Auto then return end

		This:TriggerInput("Hold Gear", Hold)
	end

	-- Sets the shift point scaling for an automatic ACF gearbox
	function ents_methods:acfShiftPointScale(Scale)
		CheckLuaType(Scale, TYPE_NUMBER)

		local This = unwrap(self)

		if not IsACFEntity(This) then return end
		if not IsOwner(SF.instance.player, This) then return end
		if not This.Auto then return end

		This:TriggerInput("Shift Speed Scale", Scale)
	end

	-- Returns true if the current engine requires fuel to run
	function ents_methods:acfFuelRequired()
		local This = unwrap(self)

		if not IsACFEntity(This) then return false end
		if RestrictInfo(SF.instance.player, This) then return false end

		return This.RequiresFuel or false
	end

	-- Sets the ACF fuel tank refuel duty status, which supplies fuel to other fuel tanks
	function ents_methods:acfRefuelDuty (On)
		CheckLuaType(On, TYPE_BOOL)

		local This = unwrap(self)

		if not IsACFEntity(This) then return end
		if not IsOwner(SF.instance.player, This) then return end

		This:TriggerInput("Refuel Duty", On)
	end

	-- Returns the remaining liters or kilowatt hours of fuel in an ACF fuel tank or engine
	function ents_methods:acfFuel ()
		local This = unwrap(self)

		if not IsACFEntity(This) then return false end
		if RestrictInfo(SF.instance.player, This) then return false end
		if This.Fuel then return Round(This.Fuel, 2) end

		local Fuel = 0
		local Source = LinkSource(This:GetClass(), "FuelTanks")

		if not Source then return 0 end

		for Tank in pairs(Source(This)) do
			Fuel = Fuel + Tank.Fuel
		end

		return Round(Fuel, 2)
	end

	-- Returns the amount of fuel in an ACF fuel tank or linked to engine as a percentage of capacity
	function ents_methods:acfFuelLevel()
		local This = unwrap(self)

		if not IsACFEntity(This) then return false end
		if RestrictInfo(SF.instance.player, This) then return false end
		if This.Capacity then return Round((This.Fuel or 0) / This.Capacity, 2) end

		local Fuel = 0
		local Capacity = 0
		local Source = LinkSource(This:GetClass(), "FuelTanks")

		if not Source then return 0 end

		for Tank in pairs(Source(This)) do
			Fuel = Fuel + Tank.Fuel
			Capacity = Capacity + Tank.Capacity
		end

		return Round(Fuel / Capacity, 2)
	end

	-- Returns the current fuel consumption in liters per minute or kilowatts of an engine
	function ents_methods:acfFuelUse()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not This.GetConsumption then return 0 end
		if not This.Throttle then return 0 end
		if not This.FlyRPM then return 0 end

		return This:GetConsumption(This.Throttle, This.FlyRPM) * 60
	end

	-- Returns the peak fuel consumption in liters per minute or kilowatts of an engine at powerband max, for the current fuel type the engine is using
	function ents_methods:acfPeakFuelUse()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not This.GetConsumption then return 0 end
		if not This.LimitRPM then return 0 end

		return This:GetConsumption(1, This.LimitRPM) * 60
	end

	-- returns any wheels linked to this mobility setup
	function ents_methods:acfGetLinkedWheels()
		local This = unwrap(self)

		if not IsACFEntity(This) then return {} end
		if RestrictInfo(SF.instance.player, This) then return {} end

		local Wheels = {}
		local Count = 0

		for Wheel in pairs(GetLinkedWheels(This)) do
			Count = Count + 1
			Wheels[Count] = wrap(Wheel)
		end

		return Wheels
	end

	--===============================================================================================--
	-- Weaponry Functions
	--===============================================================================================--

	-- Returns true if the ACF gun is ready to fire
	function ents_methods:acfReady()
		local This = unwrap(self)

		if not IsACFEntity(This) then return false end
		if RestrictInfo(SF.instance.player, This) then return false end
		if not This.State then return false end

		return This.State == "Loaded"
	end

	-- Returns the state of the ACF entity
	function ents_methods:acfState()
		local This = unwrap(self)

		if not IsACFEntity(This) then return "" end
		if RestrictInfo(SF.instance.player, This) then return "" end

		return This.State or ""
	end

	-- Returns time to next shot of an ACF weapon
	function ents_methods:acfReloadTime()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if This.State and This.State == "Loaded" then return 0 end

		return GetReloadTime(This)
	end

	-- Returns number between 0 and 1 which represents reloading progress of an ACF weapon. Useful for progress bars
	function ents_methods:acfReloadProgress()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not This.NextFire then return 0 end

		return math.Clamp(1 - (This.NextFire - CurTime()) / GetReloadTime(This), 0, 1)
	end

	-- Returns time it takes for an ACF weapon to reload magazine
	function ents_methods:acfMagReloadTime()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end

		return This.MagReload or 0
	end

	-- Returns the magazine size for an ACF gun
	function ents_methods:acfMagSize()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end

		return This.MagSize or 0
	end

	-- Returns the spread for an ACF gun or flechette ammo
	function ents_methods:acfSpread()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end

		local Spread = (This.GetSpread and This:GetSpread()) or This.Spread or 0

		if This.BulletData and This.BulletData.Type == "FL" then
			return Spread + (This.BulletData.FlechetteSpread or 0)
		end

		return Spread
	end

	-- Returns true if an ACF gun is reloading
	function ents_methods:acfIsReloading()
		local This = unwrap(self)

		if not IsACFEntity(This) then return false end
		if RestrictInfo(SF.instance.player, This) then return false end
		if not This.State then return false end

		return This.State == "Reloading"
	end

	-- Returns the rate of fire of an acf gun
	function ents_methods:acfFireRate()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not This.ReloadTime then return 0 end

		return Round(60 / This.ReloadTime, 2)
	end

	-- Returns the number of rounds left in a magazine for an ACF gun
	function ents_methods:acfMagRounds()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end

		return This.CurrentShot or 0
	end

	-- Sets the firing state of an ACF weapon
	function ents_methods:acfFire(Fire)
		CheckLuaType(Fire, TYPE_BOOL)

		local This = unwrap(self)

		if not IsACFEntity(This) then return end
		if not IsOwner(SF.instance.player, This) then return end

		This:TriggerInput("Fire", Fire)
	end

	-- Causes an ACF weapon to unload
	function ents_methods:acfUnload()
		local This = unwrap(self)

		if not IsACFEntity(This) then return end
		if not IsOwner(SF.instance.player, This) then return end

		This:TriggerInput("Unload", true)
	end

	-- Causes an ACF weapon to reload
	function ents_methods:acfReload()
		local This = unwrap(self)

		if not IsACFEntity(This) then return end
		if not IsOwner(SF.instance.player, This) then return end

		This:TriggerInput("Reload", true)
	end

	-- Returns the rounds left in an acf ammo crate
	function ents_methods:acfRounds()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end

		return This.Ammo or 0
	end

	-- Returns the type of weapon the ammo in an ACF ammo crate loads into
	function ents_methods:acfRoundType()
		local This = unwrap(self)

		if not IsACFEntity(This) then return "" end
		if RestrictInfo(SF.instance.player, This) then return "" end

		return This.RoundId or ""
	end

	-- Returns the type of ammo in a crate or gun
	function ents_methods:acfAmmoType()
		local This = unwrap(self)

		if not IsACFEntity(This) then return "" end
		if RestrictInfo(SF.instance.player, This) then return "" end
		if not This.BulletData then return "" end

		return This.BulletData.Type or ""
	end

	-- [ Ammo Functions ] --

	-- Returns the caliber of an ammo or gun
	function ents_methods:acfCaliber()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not This.Caliber then return 0 end

		return This.Caliber * 10
	end

	-- Returns the muzzle velocity of the ammo in a crate or gun
	function ents_methods:acfMuzzleVel()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not This.BulletData then return 0 end
		if not This.BulletData.MuzzleVel then return 0 end

		return Round(This.BulletData.MuzzleVel * ACF.Scale, 2)
	end

	-- Returns the mass of the projectile in a crate or gun
	function ents_methods:acfProjectileMass()
local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not This.BulletData then return 0 end
		if not This.BulletData.ProjMass then return 0 end

		return Round(This.BulletData.ProjMass, 2)
	end

	-- Returns the drag coef of the ammo in a crate or gun
	function ents_methods:acfDragCoef()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not This.BulletData then return 0 end
		if not This.BulletData.DragCoef then return 0 end

		return Round(This.BulletData.DragCoef / ACF.DragDiv, 2)
	end

	-- Returns the number of projectiles in a flechette round
	function ents_methods:acfFLSpikes()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not This.BulletData then return 0 end

	return This.BulletData.Flechettes or 0
	end

	-- Returns the mass of a single spike in a FL round in a crate or gun
	function ents_methods:acfFLSpikeMass()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not This.BulletData then return 0 end
		if not This.BulletData.FlechetteMass then return 0 end

		return Round(This.BulletData.FlechetteMass, 2)
	end

	-- Returns the radius of the spikes in a flechette round in mm
	function ents_methods:acfFLSpikeRadius()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not This.BulletData then return 0 end
		if not This.BulletData.FlechetteRadius then return 0 end

		return Round(This.BulletData.FlechetteRadius * 10, 2)
	end

	-- Returns the penetration of an ACF round
	function ents_methods:acfPenetration()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not This.BulletData then return 0 end
		if not This.BulletData.Type then return 0 end

		local BulletData = This.BulletData
		local RoundData = RoundTypes[BulletData.Type]

		if not RoundData then return 0 end

		local DisplayData = RoundData.getDisplayData(BulletData)

		if not DisplayData.MaxPen then return 0 end

		return Round(DisplayData.MaxPen, 2)
	end

	-- Returns the blast radius of an ACF round
	function ents_methods:acfBlastRadius()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end
		if not This.BulletData then return 0 end
		if not This.BulletData.Type then return 0 end

		local BulletData = This.BulletData
		local RoundData = RoundTypes[BulletData.Type]

		if not RoundData then return 0 end

		local DisplayData = RoundData.getDisplayData(BulletData)

		if not DisplayData.BlastRadius then return 0 end

		return Round(DisplayData.BlastRadius, 2)
	end

	--Returns the number of rounds in active ammo crates linked to an ACF weapon
	function ents_methods:acfAmmoCount()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end

		local Count = 0
		local Source = LinkSource(This:GetClass(), "Crates")

		if not Source then return 0 end

		for Crate in pairs(Source(This)) do
			if Crate.Load then
				Count = Count + Crate.Ammo
			end
		end

		return Count
	end

	--Returns the number of rounds in all ammo crates linked to an ACF weapon
	function ents_methods:acfTotalAmmoCount ()
		local This = unwrap(self)

		if not IsACFEntity(This) then return 0 end
		if RestrictInfo(SF.instance.player, This) then return 0 end

		local Count = 0
		local Source = LinkSource(This:GetClass(), "Crates")

		if not Source then return 0 end

		for Crate in pairs(Source(This)) do
			Count = Count + Crate.Ammo
		end

		return Count
	end
end)