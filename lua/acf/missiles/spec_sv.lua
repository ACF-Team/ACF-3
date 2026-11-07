local ACF           = ACF
local Missiles      = ACF.Missiles
local Classes       = ACF.Classes
local MissileBase   = "ACF.Missiles.BaseMissile"
local AmmoBase      = "ACF.Ammunition.BaseAmmo"
local GuidanceBase  = "ACF.Missiles.Guidance"
local FuzeBase      = "ACF.Missiles.Fuze"
local NavBase       = "ACF.Missiles.Navigation"
local DefaultGuide  = "ACF.Missiles.Guidance.Dumb"
local DefaultFuze   = "ACF.Missiles.Fuze.Contact"
local DefaultNav    = "ACF.Missiles.Navigation.Chase"

-- Missiles are V2 classes addressed by FQN, or by short id (FQN suffix, or CLASS.ID for groups).
local function GetMissileClass(ID)
	if not isstring(ID) then return end

	local Direct = Classes.GetSubtypeByName(MissileBase, ID)
	if Direct then return Direct end

	for _, Class in ipairs(Classes.GetSubtypesAsList(MissileBase)) do
		if Class.ID == ID or Classes.GetTypeName(Class):match("[^.]+$") == ID then return Class end
	end
end

local function GetNavigationClass(ID)
	return isstring(ID) and Classes.GetSubtypeByName(NavBase, ID) or nil
end

-- True if the ammo type blacklists the missile, or any of the groups it belongs to.
local function IsAmmoBlacklisted(AmmoClass, MissileClass)
	if MissileClass.Blacklist and MissileClass.Blacklist[Classes.GetTypeName(AmmoClass)] then return true end

	local Blacklist = AmmoClass.Blacklist
	if not Blacklist then return false end

	local Class = MissileClass

	while Class do
		if Blacklist[Classes.GetTypeName(Class)] then return true end

		Class = Classes.GetBaseClass(Class)
	end

	return false
end

--- A fresh instance of the same class with the declared fields copied over.
--- Guidance/fuze/navigation keep per-missile state, so every missile gets its own copy of the spec's template.
function Missiles.CloneInstance(Instance)
	local Class = Instance:GetType()
	local Copy  = Class()

	for _, Field in ipairs(Classes.GetTypeFields(Class)) do
		Copy[Field.Name] = Instance[Field.Name]
	end

	return Copy
end

-- Accepts an instance, or { Type = FQN, Data = {...} }, or nil for the default.
-- Allowed is the missile class' allow-list (CLASS.Guidances/CLASS.Fuzes), nil means anything assignable.
local function ResolveSubInstance(Value, BaseFQN, DefaultFQN, Allowed, Label)
	local BaseType = Classes.GetTypeByName(BaseFQN)
	local Class, Instance

	if Value == nil then
		Class = Classes.GetTypeByName(DefaultFQN)
	elseif istable(Value) and Value.GetType then
		Class    = Value:GetType()
		Instance = Value
	elseif istable(Value) then
		Class = Classes.GetTypeByName(Value.Type)
	else
		return nil, ("%s must be an instance or { Type, Data }, got %s"):format(Label, type(Value))
	end

	if not (Class and BaseType and Classes.IsAssignableTo(Class, BaseType)) then
		return nil, ("%s type '%s' is not a %s"):format(Label, tostring(istable(Value) and Value.Type or DefaultFQN), BaseFQN)
	end

	local FQN = Classes.GetTypeName(Class)

	if Allowed and not Allowed[FQN] and FQN ~= DefaultFQN then
		return nil, ("%s '%s' is not allowed on this missile"):format(Label, FQN)
	end

	if Instance then return Missiles.CloneInstance(Instance) end

	return Classes.Serialization.DeserializePartial(Class, istable(Value) and Value.Data or nil)
end

local function NewSpec(MissileClass, Ammo, Weapon, Navigation, Crate)
	return {
		Class      = MissileClass,
		Ammo       = Ammo,
		BulletData = Ammo:ServerConvert(),
		Guidance   = Weapon.Guidance,
		Fuze       = Weapon.Fuze,
		Navigation = Navigation,
		Crate      = Crate,
	}
end

--- Describes a missile without a crate. Returns the Spec, or nil and an error string.
--- @param Params table { Missile, AmmoType, Ammo?, Guidance?, Fuze?, Navigation? }
function Missiles.CreateSpec(Params)
	if not istable(Params) then return nil, "Params must be a table" end

	local MissileClass = GetMissileClass(Params.Missile)
	if not MissileClass then return nil, ("Unknown missile '%s'"):format(tostring(Params.Missile)) end
	if not MissileClass.Round then return nil, ("Missile '%s' is a group, not a missile"):format(tostring(Params.Missile)) end

	local AmmoClass = isstring(Params.AmmoType) and Classes.GetSubtypeByName(AmmoBase, Params.AmmoType)
	if not AmmoClass then return nil, ("Unknown ammo type '%s'"):format(tostring(Params.AmmoType)) end
	if IsAmmoBlacklisted(AmmoClass, MissileClass) then
		return nil, ("Ammo type '%s' can't be used on '%s'"):format(Params.AmmoType, Classes.GetTypeName(MissileClass))
	end

	local Weapon = MissileClass()
	local Err

	Weapon.Guidance, Err = ResolveSubInstance(Params.Guidance, GuidanceBase, DefaultGuide, MissileClass.Guidances, "Guidance")
	if not Weapon.Guidance then return nil, Err end

	Weapon.Fuze, Err = ResolveSubInstance(Params.Fuze, FuzeBase, DefaultFuze, MissileClass.Fuzes, "Fuze")
	if not Weapon.Fuze then return nil, Err end

	if Weapon.Guidance.VerifyData then Weapon.Guidance:VerifyData(Weapon) end
	if Weapon.Fuze.VerifyData then Weapon.Fuze:VerifyData(Weapon) end

	local ClassNav = GetNavigationClass(MissileClass.Navigation)
	local Navigation
	Navigation, Err = ResolveSubInstance(Params.Navigation, NavBase, ClassNav and Classes.GetTypeName(ClassNav) or DefaultNav, nil, "Navigation")
	if not Navigation then return nil, Err end

	local Ammo  = AmmoClass()
	local Round = MissileClass.Round
	local Input = istable(Params.Ammo) and Params.Ammo or {}

	Ammo.Weapon = Weapon

	for _, Field in ipairs(Classes.GetTypeFields(AmmoClass)) do
		if Field.Menu and Input[Field.Name] ~= nil then
			Ammo[Field.Name] = Input[Field.Name]
		end
	end

	-- Lengths can also come as Projectile/Propellant; with neither, the class' own round lengths are used.
	if not (isnumber(Input.RoundLength) and Input.RoundLength > 0) then
		Ammo.RoundLength = nil
		Ammo.Projectile  = isnumber(Input.Projectile) and Input.Projectile or Round.ProjLength
		Ammo.Propellant  = isnumber(Input.Propellant) and Input.Propellant or Round.PropLength
	end

	return NewSpec(MissileClass, Ammo, Weapon, Navigation)
end

--- Describes the missile an ammo crate currently provides. Returns the Spec, or nil and an error string.
function Missiles.SpecFromCrate(Crate)
	if not IsValid(Crate) then return nil, "Invalid crate" end

	local Ammo   = Crate.RoundData
	local Weapon = Ammo and Ammo.Weapon

	if not (Weapon and Weapon.GetType) then return nil, "Crate has no round data" end

	local MissileClass = Weapon:GetType()

	if not Classes.IsAssignableTo(MissileClass, Classes.GetTypeByName(MissileBase)) then
		return nil, "Crate does not hold missiles"
	end

	if not (Weapon.Guidance and Weapon.Fuze) then return nil, "Crate has no guidance or fuze" end

	local NavClass = GetNavigationClass(MissileClass.Navigation) or Classes.GetTypeByName(DefaultNav)

	return NewSpec(MissileClass, Ammo, Weapon, NavClass(), Crate)
end
