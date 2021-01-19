-- [ To Do ] --

-- #general

-- #engine

-- #gearbox

-- #gun
--use an input to set reload manually, to remove timer? (what?)

-- #ammo

-- #prop armor
--get incident armor ?
--hit calcs ?
--conversions ?

-- #fuel

local ACF               = ACF
local math              = math
local match             = string.match
local AmmoTypes         = ACF.Classes.AmmoTypes
local Engines           = ACF.Classes.Engines
local FuelTanks         = ACF.Classes.FuelTanks
local FuelTypes         = ACF.Classes.FuelTypes
local Gearboxes         = ACF.Classes.Gearboxes
local Weapons           = ACF.Classes.Weapons
local CheckLuaType      = SF.CheckLuaType
local CheckPerms        = SF.Permissions.check
local RegisterPrivilege = SF.Permissions.registerPrivilege

local Ignored = {
	LimitConVar = true,
	BaseClass = true,
	Loaded = true,
	Lookup = true,
	Class = true,
	Count = true,
	Items = true,
}

RegisterPrivilege("acf.createAmmo", "Create ACF Ammo Crate", "Allows the user to create ACF Ammo Crates", { usergroups = { default = 3 } })
RegisterPrivilege("acf.createEngine", "Create ACF Engine", "Allows the user to create ACF Engines", { usergroups = { default = 3 } })
RegisterPrivilege("acf.createFuelTank", "Create ACF Fuel Tank", "Allows the user to create ACF Fuel Tanks", { usergroups = { default = 3 } })
RegisterPrivilege("acf.createGearbox", "Create ACF Gearbox", "Allows the user to create ACF Gearboxes", { usergroups = { default = 3 } })
RegisterPrivilege("acf.createWeapon", "Create ACF Weapon", "Allows the user to create ACF Weapons", { usergroups = { default = 3 } })
RegisterPrivilege("entities.acf", "ACF", "Allows the user to control ACF components", { entities = {} })

local plyCount = SF.LimitObject("acf_components", "acf_components", -1, "The number of ACF components allowed to spawn via Starfall")
local plyBurst = SF.BurstObject("acf_components", "acf_components", 4, 4, "Rate ACF components can be spawned per second.", "Number of ACF components that can be spawned in a short time.")

-- [ Helper Functions ] --

local function IsACFEntity(Entity)
	if not ACF.Check(Entity) then return false end

	local Match = match(Entity:GetClass(), "^acf_")

	return Match and true or false
end

local function GetReloadTime(Entity)
	local Unloading = Entity.State == "Unloading"
	local NewLoad = Entity.State ~= "Loaded" and Entity.CurrentShot == 0

	return (Unloading or NewLoad) and Entity.MagReload or Entity.ReloadTime or 0
end

local function GetMaxPower(Entity)
	if not Entity.PeakTorque then return 0 end

	local MaxPower

	if Entity.IsElectric then
		if not Entity.LimitRPM then return 0 end

		MaxPower = math.floor(Entity.PeakTorque * Entity.LimitRPM / 38195.2) --(4*9548.8)
	else
		if not Entity.PeakMaxRPM then return 0 end

		MaxPower = math.floor(Entity.PeakTorque * Entity.PeakMaxRPM / 9548.8)
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

----------------------------------------
-- ACF Library
-- @name acf
-- @class library
-- @libtbl acf_library
SF.RegisterLibrary("acf")

-- Local to each starfall
return function(instance) -- Called for library declarations

local CheckType = instance.CheckType
local acf_library = instance.Libraries.acf
local owrap, ounwrap = instance.WrapObject, instance.UnwrapObject
local ents_methods, wrap, unwrap = instance.Types.Entity.Methods, instance.Types.Entity.Wrap, instance.Types.Entity.Unwrap
local ang_meta, aunwrap = instance.Types.Angle, instance.Types.Angle.Unwrap
local vec_meta, vunwrap = instance.Types.Vector, instance.Types.Vector.Unwrap

local function RestrictInfo(Entity)
	if not ACF.RestrictInfo then return false end

	return not isOwner(instance, Entity)
end

local function WrapTable(Table, Ignore, Checked)
	local Result = {}

	if not Checked then Checked = {} end
	if not Ignore then Ignore = {} end

	for K, V in pairs(Table) do
		if istable(V) then
			if not (Ignore[K] or Checked[V]) then
				Result[K]  = WrapTable(V, Ignore, Checked)
				Checked[V] = true
			end
		elseif not Ignore[K] then
			Result[K] = owrap(V)
		end
	end

	return Result
end

local function UnwrapTable(Table, Checked)
	local Result = {}

	if not Checked then Checked = {} end

	for K, V in pairs(Table) do
		if istable(V) then
			if not Checked[V] then
				Result[K]  = ounwrap(V) or UnwrapTable(V, Checked)
				Checked[V] = true
			end
		else
			Result[K] = ounwrap(V)
		end
	end

	return Result
end

local function OnRemove(Entity, Player)
	plyCount:free(Player, 1)

	instance.data.props.props[Entity] = nil
end

local function RegisterEntity(Entity)
	local Player = instance.player

	Entity:CallOnRemove("starfall_prop_delete", OnRemove, Player)

	plyCount:free(Player, -1)

	instance.data.props.props[Entity] = true
end

--===============================================================================================--
-- General Functions
--===============================================================================================--

--- Returns true if functions returning sensitive info are restricted to owned props
-- @server
-- @return True if restriced, False if not
function acf_library.infoRestricted()
	return ACF.RestrictInfo
end

--- Returns current ACF drag divisor
-- @server
-- @return The current drag divisor
function acf_library.dragDivisor()
	return ACF.DragDiv
end

--- Returns the effective armor given an armor value and hit angle
-- @server
-- @return The effective armor
function acf_library.effectiveArmor(armor, angle)
	CheckLuaType(armor, TYPE_NUMBER)
	CheckLuaType(angle, TYPE_NUMBER)

	return math.Round(armor / math.abs(math.cos(math.rad(math.min(angle, 89.999)))), 1)
end

--- Creates an ACF ammo crate using the information from the data table argument
-- @server
function acf_library.createAmmo(pos, ang, data)
	CheckPerms(instance, nil, "acf.createAmmo")

	local Player = instance.player

	if not hook.Run("CanTool", Player, { Hit = true, Entity = game.GetWorld() }, "acf_menu") then
		SF.Throw("No permission to spawn ACF components", 2)
	end

	CheckType(pos, vec_meta)
	CheckType(ang, ang_meta)
	CheckLuaType(data, TYPE_TABLE)

	local Position = SF.clampPos(vunwrap(pos))
	local Angles   = aunwrap(ang)
	local Data     = UnwrapTable(data)
	local Undo     = not instance.data.props.undo

	local Success, Entity = ACF.CreateEntity("acf_ammo", Player, Position, Angles, Data, Undo)

	if not Success then SF.Throw("Unable to create ACF Ammo Crate", 2) end

	plyBurst:use(Player, 1)
	plyCount:checkuse(Player, 1)

	RegisterEntity(Entity)

	return owrap(Entity)
end

--- Creates an ACF engine using the information from the data table argument
-- @server
function acf_library.createEngine(pos, ang, data)
	CheckPerms(instance, nil, "acf.createEngine")

	local Player = instance.player

	if not hook.Run("CanTool", Player, { Hit = true, Entity = game.GetWorld() }, "acf_menu") then
		SF.Throw("No permission to spawn ACF components", 2)
	end

	CheckType(pos, vec_meta)
	CheckType(ang, ang_meta)
	CheckLuaType(data, TYPE_TABLE)

	local Position = SF.clampPos(vunwrap(pos))
	local Angles   = aunwrap(ang)
	local Data     = UnwrapTable(data)
	local Undo     = not instance.data.props.undo

	local Success, Entity = ACF.CreateEntity("acf_engine", Player, Position, Angles, Data, Undo)

	if not Success then SF.Throw("Unable to create ACF Engine", 2) end

	plyBurst:use(Player, 1)
	plyCount:checkuse(Player, 1)

	RegisterEntity(Entity)

	return owrap(Entity)
end

--- Creates an ACF fuel tank using the information from the data table argument
-- @server
function acf_library.createFuelTank(pos, ang, data)
	CheckPerms(instance, nil, "acf.createFuelTank")

	local Player = instance.player

	if not hook.Run("CanTool", Player, { Hit = true, Entity = game.GetWorld() }, "acf_menu") then
		SF.Throw("No permission to spawn ACF components", 2)
	end

	CheckType(pos, vec_meta)
	CheckType(ang, ang_meta)
	CheckLuaType(data, TYPE_TABLE)

	local Position = SF.clampPos(vunwrap(pos))
	local Angles   = aunwrap(ang)
	local Data     = UnwrapTable(data)
	local Undo     = not instance.data.props.undo

	local Success, Entity = ACF.CreateEntity("acf_fueltank", Player, Position, Angles, Data, Undo)

	if not Success then SF.Throw("Unable to create ACF Fuel Tank", 2) end

	plyBurst:use(Player, 1)
	plyCount:checkuse(Player, 1)

	RegisterEntity(Entity)

	return owrap(Entity)
end

--- Creates an ACF gearbox using the information from the data table argument
-- @server
function acf_library.createGearbox(pos, ang, data)
	CheckPerms(instance, nil, "acf.createGearbox")

	local Player = instance.player

	if not hook.Run("CanTool", Player, { Hit = true, Entity = game.GetWorld() }, "acf_menu") then
		SF.Throw("No permission to spawn ACF components", 2)
	end

	CheckType(pos, vec_meta)
	CheckType(ang, ang_meta)
	CheckLuaType(data, TYPE_TABLE)

	local Position = SF.clampPos(vunwrap(pos))
	local Angles   = aunwrap(ang)
	local Data     = UnwrapTable(data)
	local Undo     = not instance.data.props.undo

	local Success, Entity = ACF.CreateEntity("acf_gearbox", Player, Position, Angles, Data, Undo)

	if not Success then SF.Throw("Unable to create ACF Gearbox", 2) end

	plyBurst:use(Player, 1)
	plyCount:checkuse(Player, 1)

	RegisterEntity(Entity)

	return owrap(Entity)
end

--- Creates an ACF weapon using the information from the data table argument
-- @server
function acf_library.createWeapon(pos, ang, data)
	CheckPerms(instance, nil, "acf.createWeapon")

	local Player = instance.player

	if not hook.Run("CanTool", Player, { Hit = true, Entity = game.GetWorld() }, "acf_menu") then
		SF.Throw("No permission to spawn ACF components", 2)
	end

	CheckType(pos, vec_meta)
	CheckType(ang, ang_meta)
	CheckLuaType(data, TYPE_TABLE)

	local Position = SF.clampPos(vunwrap(pos))
	local Angles   = aunwrap(ang)
	local Data     = UnwrapTable(data)
	local Undo     = not instance.data.props.undo

	local Success, Entity = ACF.CreateEntity("acf_gun", Player, Position, Angles, Data, Undo)

	if not Success then SF.Throw("Unable to create ACF Weapon", 2) end

	plyBurst:use(Player, 1)
	plyCount:checkuse(Player, 1)

	RegisterEntity(Entity)

	return owrap(Entity)
end

--- Returns a list of every registered ACF ammo type
-- @server
function acf_library.listAllAmmoTypes()
	local Result = {}
	local Count  = 0

	for ID in pairs(AmmoTypes) do
		Count = Count + 1

		Result[Count] = ID
	end

	return Result
end

--- Returns a list of every registered ACF engine class
-- @server
function acf_library.listAllEngineClasses()
	local Result = {}
	local Count  = 0

	for _, Class in pairs(Engines) do
		Count = Count + 1

		Result[Count] = Class.ID
	end

	return Result
end

--- Returns a list of every registered ACF engine
-- @server
function acf_library.listAllEngines()
	local Result = {}
	local Count  = 0

	for _, Class in pairs(Engines) do
		for _, Engine in ipairs(Class.Items) do
			Count = Count + 1

			Result[Count] = Engine.ID
		end
	end

	return Result
end

--- Returns a list of every registered ACF fuel tank class
-- @server
function acf_library.listAllFuelTankClasses()
	local Result = {}
	local Count  = 0

	for _, Class in pairs(FuelTanks) do
		Count = Count + 1

		Result[Count] = Class.ID
	end

	return Result
end

--- Returns a list of every registered ACF fuel tank
-- @server
function acf_library.listAllFuelTanks()
	local Result = {}
	local Count  = 0

	for _, Class in pairs(FuelTanks) do
		for _, Tank in ipairs(Class.Items) do
			Count = Count + 1

			Result[Count] = Tank.ID
		end
	end

	return Result
end

--- Returns a list of every registered ACF fuel type
-- @server
function acf_library.listAllFuelTypes()
	local Result = {}
	local Count  = 0

	for ID in pairs(FuelTypes) do
		Count = Count + 1

		Result[Count] = ID
	end

	return Result
end

--- Returns a list of every registered ACF gearbox class
-- @server
function acf_library.listAllGearboxClasses()
	local Result = {}
	local Count  = 0

	for _, Class in pairs(Gearboxes) do
		Count = Count + 1

		Result[Count] = Class.ID
	end

	return Result
end

--- Returns a list of every registered ACF gearbox
-- @server
function acf_library.listAllGearboxes()
	local Result = {}
	local Count  = 0

	for _, Class in pairs(Gearboxes) do
		for _, Gearbox in ipairs(Class.Items) do
			Count = Count + 1

			Result[Count] = Gearbox.ID
		end
	end

	return Result
end

--- Returns a list of every registered ACF weapon class
-- @server
function acf_library.listAllWeaponClasses()
	local Result = {}
	local Count  = 0

	for _, Class in pairs(Weapons) do
		Count = Count + 1

		Result[Count] = Class.ID
	end

	return Result
end

--- Returns a list of every registered ACF weapon
-- @server
function acf_library.listAllWeapons()
	local Result = {}
	local Count  = 0

	for _, Class in pairs(Weapons) do
		for _, Weapon in ipairs(Class.Items) do
			Count = Count + 1

			Result[Count] = Weapon.ID
		end
	end

	return Result
end

--- Returns the specifications of an ACF ammo type
-- @param id The ID of the engine class you want to get the information from
-- @server
function acf_library.getAmmoTypeSpecs(id)
	CheckLuaType(id, TYPE_STRING)

	local Ammo = AmmoTypes[id]

	if not Ammo then SF.Throw("Invalid ammo type ID, not found.", 2) end

	return WrapTable(Ammo, Ignored)
end

--- Returns the specifications of an ACF engine class
-- @param id The ID of the engine class you want to get the information from
-- @server
function acf_library.getEngineClassSpecs(id)
	CheckLuaType(id, TYPE_STRING)

	local Class = Engines[id]

	if not Class then SF.Throw("Invalid engine class ID, not found.", 2) end

	return WrapTable(Class, Ignored)
end

--- Returns the specifications of an ACF engine class
-- @param id The ID of the engine class you want to get the information from
-- @server
function acf_library.getEngineClassSpecs(id)
	CheckLuaType(id, TYPE_STRING)

	local Class = Engines[id]

	if not Class then SF.Throw("Invalid engine class ID, not found.", 2) end

	return WrapTable(Class, Ignored)
end

--- Returns the specifications of an ACF engine
-- @param id The ID of the engine you want to get the information from
-- @server
function acf_library.getEngineSpecs(id)
	CheckLuaType(id, TYPE_STRING)

	local Class = ACF.GetClassGroup(Engines, id)

	if not Class then SF.Throw("Invalid engine ID, not found.", 2) end

	return WrapTable(Class.Lookup[id], Ignored)
end

--- Returns the specifications of an ACF fuel tank class
-- @param id The ID of the fuel tank class you want to get the information from
-- @server
function acf_library.getFuelTankClassSpecs(id)
	CheckLuaType(id, TYPE_STRING)

	local Class = FuelTanks[id]

	if not Class then SF.Throw("Invalid fuel tank class ID, not found.", 2) end

	return WrapTable(Class, Ignored)
end

--- Returns the specifications of an ACF fuel tank
-- @param id The ID of the fuel tank you want to get the information from
-- @server
function acf_library.getFuelTankSpecs(id)
	CheckLuaType(id, TYPE_STRING)

	local Class = ACF.GetClassGroup(FuelTanks, id)

	if not Class then SF.Throw("Invalid fuel tank ID, not found.", 2) end

	return WrapTable(Class.Lookup[id], Ignored)
end

--- Returns the specifications of an ACF fuel type
-- @param id The ID of the fuel type you want to get the information from
-- @server
function acf_library.getFuelTypeSpecs(id)
	CheckLuaType(id, TYPE_STRING)

	local Type = FuelTypes[id]

	if not Type then SF.Throw("Invalid fuel type ID, not found.", 2) end

	return WrapTable(Type, Ignored)
end

--- Returns the specifications of an ACF gearbox class
-- @param id The ID of the gearbox class you want to get the information from
-- @server
function acf_library.getGearboxClassSpecs(id)
	CheckLuaType(id, TYPE_STRING)

	local Class = Gearboxes[id]

	if not Class then SF.Throw("Invalid gearbox class ID, not found.", 2) end

	return WrapTable(Class, Ignored)
end

--- Returns the specifications of an ACF gearbox
-- @param id The ID of the gearbox you want to get the information from
-- @server
function acf_library.getGearboxSpecs(id)
	CheckLuaType(id, TYPE_STRING)

	local Class = ACF.GetClassGroup(Gearboxes, id)

	if not Class then SF.Throw("Invalid gearbox ID, not found.", 2) end

	return WrapTable(Class.Lookup[id], Ignored)
end

--- Returns the specifications of an ACF weapon class
-- @param id The ID of the weapon class you want to get the information from
-- @server
function acf_library.getWeaponClassSpecs(id)
	CheckLuaType(id, TYPE_STRING)

	local Class = Weapons[id]

	if not Class then SF.Throw("Invalid weapon class ID, not found.", 2) end

	return WrapTable(Class, Ignored)
end

--- Returns the specifications of an ACF weapon
-- @param id The ID of the weapon you want to get the information from
-- @server
function acf_library.getWeaponSpecs(id)
	CheckLuaType(id, TYPE_STRING)

	local Class = ACF.GetClassGroup(Weapons, id)

	if not Class then SF.Throw("Invalid weapon ID, not found.", 2) end

	return WrapTable(Class.Lookup[id], Ignored)
end

--- Returns true if This entity contains sensitive info and is not accessable to us
-- @server
function ents_methods:acfIsInfoRestricted()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not ACF.Check(This) then SF.Throw("Entity is not valid", 2) end

	return RestrictInfo(This)
end

--- Returns the full name of an ACF entity
-- @server
function ents_methods:acfName()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return "" end

	return This.Name or ""
end

--- Returns the short name of an ACF entity
-- @server
function ents_methods:acfNameShort()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return "" end

	return This.ShortName or ""
end

--- Returns the type of ACF entity
-- @server
function ents_methods:acfType()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return "" end

	return This.EntType or ""
end

--- Returns true if the entity is an ACF engine
-- @server
function ents_methods:acfIsEngine()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return false end

	return This.IsEngine or false
end

--- Returns true if the entity is an ACF gearbox
-- @server
function ents_methods:acfIsGearbox()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return false end

	return This.IsGearbox or false
end

--- Returns true if the entity is an ACF gun
-- @server
function ents_methods:acfIsGun()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return false end

	return This.IsWeapon or false
end

--- Returns true if the entity is an ACF ammo crate
-- @server
function ents_methods:acfIsAmmo()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return false end

	return This.IsAmmoCrate or false
end

--- Returns true if the entity is an ACF fuel tank
-- @server
function ents_methods:acfIsFuel()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return false end

	return This.IsFuelTank or false
end

--- Returns the capacity of an acf ammo crate or fuel tank
-- @server
function ents_methods:acfCapacity()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	return This.Capacity or 0
end

--- Returns the path of an ACF entity's sound
-- @server
function ents_methods:acfSoundPath()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return "" end

	return This.SoundPath or ""
end

--- Returns true if the acf engine, fuel tank, or ammo crate is active
-- @server
function ents_methods:acfGetActive()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return false end
	if This.CanConsume then return This:CanConsume() end

	return (This.Active or This.Load) or false
end

--- Turns an ACF engine, ammo crate, or fuel tank on or off
-- @param on The new active state of the entity
-- @server
function ents_methods:acfSetActive(on)
	CheckType(self, ents_metatable)
	CheckLuaType(on, TYPE_BOOL)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end

	CheckPerms(instance, This, "entities.acf")

	This:TriggerInput("Active", on)
end

--- Returns the current health of an entity
-- @server
function ents_methods:acfPropHealth()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not ACF.Check(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	local Health = This.ACF.Health

	return Health and math.Round(Health, 2) or 0
end

--- Returns the current armor of an entity
-- @server
function ents_methods:acfPropArmor()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not ACF.Check(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	local Armor = This.ACF.Armour

	return Armor and math.Round(Armor, 2) or 0
end

--- Returns the max health of an entity
-- @server
function ents_methods:acfPropHealthMax()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not ACF.Check(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	local MaxHealth = This.ACF.MaxHealth

	return MaxHealth and math.Round(MaxHealth, 2) or 0
end

--- Returns the max armor of an entity
-- @server
function ents_methods:acfPropArmorMax()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not ACF.Check(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	local MaxArmor = This.ACF.MaxArmour

	return MaxArmor and math.Round(MaxArmor, 2) or 0
end

--- Returns the ductility of an entity
-- @server
function ents_methods:acfPropDuctility()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not ACF.Check(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	local Ductility = This.ACF.Ductility

	return Ductility and math.Round(Ductility * 100, 2) or 0
end

--- Returns true if hitpos is on a clipped part of prop
-- @param hitpos The world hit position we want to check
-- @server
-- @return Returns true if hitpos is inside a visclipped part of the entity
function ents_methods:acfHitClip(hitpos)
	CheckType(self, ents_metatable)
	CheckType(hitpos, vec_meta)

	local This = unwrap(self)

	if not ACF.Check(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return false end

	local Position = vunwrap(hitpos)

	return ACF.CheckClips(This, Position)
end

--- Returns the ACF links associated with the entity
-- @server
function ents_methods:acfLinks()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return {} end

	local Result = {}
	local Count  = 0

	for Entity in pairs(ACF.GetLinkedEntities(This)) do
		Count = Count + 1

		Result[Count] = wrap(Entity)
	end

	return Result
end

--- Perform ACF links
-- @param target The entity to get linked to
-- @param notify If set, a notification will be sent to the player
-- @server
-- @return Returns the result of the operation, along with the result message as a second argument
function ents_methods:acfLinkTo(target, notify)
	CheckType(self, ents_metatable)
	CheckType(target, ents_metatable)

	local This = unwrap(self)
	local Target = unwrap(target)

	if not ACF.Check(This) then SF.Throw("Entity is not valid", 2) end
	if not ACF.Check(Target) then SF.Throw("Invalid Link Entity", 2) end
	if RestrictInfo(This) then SF.Throw("You don't have permission to link this entity to something", 2) end
	if RestrictInfo(Target) then SF.Throw("You don't have permission to link something to this entity", 2) end
	if not isfunction(This.Link) then SF.Throw("Entity does not support linking", 2) end

	CheckPerms(instance, This, "entities.acf")
	CheckPerms(instance, Target, "entities.acf")

	local Success, Message = This:Link(Target)

	if notify then
		ACF.SendNotify(instance.player, Success, Message)
	end

	return Success, Message
end

--- Perform ACF unlinks
-- @server
function ents_methods:acfUnlinkFrom(target, notify)
	CheckType(self, ents_metatable)
	CheckType(target, ents_metatable)

	local This = unwrap(self)
	local Target = unwrap(target)

	if not ACF.Check(This) then SF.Throw("Entity is not valid", 2) end
	if not ACF.Check(Target) then SF.Throw("Invalid Link Entity", 2) end
	if RestrictInfo(This) then SF.Throw("You don't have permission to unlink this entity from something", 2) end
	if RestrictInfo(Target) then SF.Throw("You don't have permission to unlink something from this entity", 2) end
	if not isfunction(This.Unlink) then SF.Throw("Entity does not support unlinking", 2) end

	CheckPerms(instance, This, "entities.acf")
	CheckPerms(instance, Target, "entities.acf")

	local Success, Message = This:Unlink(Target)

	if notify then
		ACF.SendNotify(instance.player, Success, Message)
	end

	return Success, Message
end

--===============================================================================================--
-- Mobility Functions
--===============================================================================================--

--- Returns true if an ACF engine is electric
-- @server
function ents_methods:acfIsElectric()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return false end

	return This.IsElectric or false
end

--- Returns the torque in N/m of an ACF engine
-- @server
function ents_methods:acfMaxTorque()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	return This.PeakTorque or 0
end

--- Returns the power in kW of an ACF engine
-- @server
function ents_methods:acfMaxPower()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	return GetMaxPower(This)
end

--- (DEPRECATED) Returns the torque in N/m of an ACF engine. Use Entity:acfMaxTorque()
-- @server
function ents_methods:acfMaxTorqueWithFuel()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	return This.PeakTorque or 0
end

--- (DEPRECATED) Returns the power in kW of an ACF engine. Use Entity:acfMaxPower()
-- @server
function ents_methods:acfMaxPowerWithFuel()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	return GetMaxPower(This)
end

--- Returns the idle rpm of an ACF engine
-- @server
function ents_methods:acfIdleRPM()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	return This.IdleRPM or 0
end

--- Returns the powerband min and max of an ACF Engine
-- @server
function ents_methods:acfPowerband()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0, 0 end

	return This.PeakMinRPM or 0, This.PeakMaxRPM or 0
end

--- Returns the powerband min of an ACF engine
-- @server
function ents_methods:acfPowerbandMin()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	return This.PeakMinRPM or 0
end

--- Returns the powerband max of an ACF engine
-- @server
function ents_methods:acfPowerbandMax()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	return This.PeakMaxRPM or 0
end

--- Returns the redline rpm of an ACF engine
-- @server
function ents_methods:acfRedline()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	return This.LimitRPM or 0
end

--- Returns the current rpm of an ACF engine
-- @server
function ents_methods:acfRPM()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	local RPM = This.FlyRPM

	return RPM and math.floor(RPM) or 0
end

--- Returns the current torque of an ACF engine
-- @server
function ents_methods:acfTorque()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	local Torque = This.Torque

	return Torque and math.floor(Torque) or 0
end

--- Returns the inertia of an ACF engine's flywheel
-- @server
function ents_methods:acfFlyInertia()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	return This.Inertia or 0
end

--- Returns the mass of an ACF engine's flywheel
-- @server
function ents_methods:acfFlyMass()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	return This.FlywheelMass or 0
end

--- Returns the current power of an ACF engine
-- @server
function ents_methods:acfPower()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end
	if not This.Torque then return 0 end
	if not This.FlyRPM then return 0 end

	return math.floor(This.Torque * This.FlyRPM / 9548.8)
end

--- Returns true if the RPM of an ACF engine is inside the powerband
-- @server
function ents_methods:acfInPowerband()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return false end
	if not This.FlyRPM then return false end

	local PowerbandMin, PowerbandMax

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

--- Returns the throttle value
-- @server
function ents_methods:acfGetThrottle()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	local Throttle = This.Throttle

	return Throttle and Throttle * 100 or 0
end

--- Sets the throttle value for an ACF engine
-- @server
function ents_methods:acfSetThrottle(throttle)
	CheckType(self, ents_metatable)
	CheckLuaType(throttle, TYPE_NUMBER)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return end

	CheckPerms(instance, This, "entities.acf")

	This:TriggerInput("Throttle", throttle)
end

--- Returns the current gear for an ACF gearbox
-- @server
function ents_methods:acfGear()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	return This.Gear or 0
end

--- Returns the number of gears for an ACF gearbox
-- @server
function ents_methods:acfNumGears()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	return This.GearCount or 0
end

--- Returns the final ratio for an ACF gearbox
-- @server
function ents_methods:acfFinalRatio()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	return This.FinalDrive or 0
end

--- Returns the total ratio (current gear * final) for an ACF gearbox
-- @server
function ents_methods:acfTotalRatio()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	return This.GearRatio or 0
end

--- Returns the max torque for an ACF gearbox
-- @server
function ents_methods:acfTorqueRating()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	return This.MaxTorque or 0
end

--- Returns whether an ACF gearbox is dual clutch
-- @server
function ents_methods:acfIsDual()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return false end

	return This.DualClutch or false
end

--- Returns the time in ms an ACF gearbox takes to change gears
-- @server
function ents_methods:acfShiftTime()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	local Time = This.SwitchTime

	return Time and Time * 1000 or 0
end

--- Returns true if an ACF gearbox is in gear
-- @server
function ents_methods:acfInGear()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return false end

	return This.InGear or false
end

--- Returns the ratio for a specified gear of an ACF gearbox
-- @server
function ents_methods:acfGearRatio(gear)
	CheckType(self, ents_metatable)
	CheckLuaType(gear, TYPE_NUMBER)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end
	if not This.Gears then return 0 end

	return This.Gears[math.floor(gear)] or 0
end

--- Returns the current torque output for an ACF gearbox
-- @server
function ents_methods:acfTorqueOut()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	return math.min(This.TotalReqTq or 0, This.MaxTorque or 0) / (This.GearRatio or 1)
end

--- Sets the gear ratio of a CVT, set to 0 to use built-in algorithm
-- @server
function ents_methods:acfCVTRatio(ratio)
	CheckType(self, ents_metatable)
	CheckLuaType(ratio, TYPE_NUMBER)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return end
	if not This.CVT then return end

	CheckPerms(instance, This, "entities.acf")

	This:TriggerInput("CVT Ratio", math.Clamp(ratio, 0, 1))
end

--- Sets the current gear for an ACF gearbox
-- @server
function ents_methods:acfShift(gear)
	CheckType(self, ents_metatable)
	CheckLuaType(gear, TYPE_NUMBER)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return end

	CheckPerms(instance, This, "entities.acf")

	This:TriggerInput("Gear", gear)
end

--- Cause an ACF gearbox to shift up
-- @server
function ents_methods:acfShiftUp()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return end

	CheckPerms(instance, This, "entities.acf")

	This:TriggerInput("Gear Up", true) --doesn't need to be toggled off
end

--- Cause an ACF gearbox to shift down
-- @server
function ents_methods:acfShiftDown()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return end

	CheckPerms(instance, This, "entities.acf")

	This:TriggerInput("Gear Down", true) --doesn't need to be toggled off
end

--- Sets the brakes for an ACF gearbox
-- @server
function ents_methods:acfBrake(brake)
	CheckType(self, ents_metatable)
	CheckLuaType(brake, TYPE_NUMBER)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return end

	CheckPerms(instance, This, "entities.acf")

	This:TriggerInput("Brake", brake)
end

--- Sets the left brakes for an ACF gearbox
-- @server
function ents_methods:acfBrakeLeft(brake)
	CheckType(self, ents_metatable)
	CheckLuaType(brake, TYPE_NUMBER)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return end

	CheckPerms(instance, This, "entities.acf")

	This:TriggerInput("Left Brake", brake)
end

--- Sets the right brakes for an ACF gearbox
-- @server
function ents_methods:acfBrakeRight(brake)
	CheckType(self, ents_metatable)
	CheckLuaType(brake, TYPE_NUMBER)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return end

	CheckPerms(instance, This, "entities.acf")

	This:TriggerInput("Right Brake", brake)
end

--- Sets the clutch for an ACF gearbox
-- @server
function ents_methods:acfClutch(clutch)
	CheckType(self, ents_metatable)
	CheckLuaType(clutch, TYPE_NUMBER)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return end

	CheckPerms(instance, This, "entities.acf")

	This:TriggerInput("Clutch", clutch)
end

--- Sets the left clutch for an ACF gearbox
-- @server
function ents_methods:acfClutchLeft(clutch)
	CheckType(self, ents_metatable)
	CheckLuaType(clutch, TYPE_NUMBER)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return end

	CheckPerms(instance, This, "entities.acf")

	This:TriggerInput("Left Clutch", clutch)
end

--- Sets the right clutch for an ACF gearbox
-- @server
function ents_methods:acfClutchRight(clutch)
	CheckType(self, ents_metatable)
	CheckLuaType(clutch, TYPE_NUMBER)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return end

	CheckPerms(instance, This, "entities.acf")

	This:TriggerInput("Right Clutch", clutch)
end

--- Sets the steer ratio for an ACF gearbox
-- @server
function ents_methods:acfSteerRate(rate)
	CheckType(self, ents_metatable)
	CheckLuaType(rate, TYPE_NUMBER)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return end

	CheckPerms(instance, This, "entities.acf")

	This:TriggerInput("Steer Rate", rate)
end

--- Applies gear hold for an automatic ACF gearbox
-- @server
function ents_methods:acfHoldGear(hold)
	CheckType(self, ents_metatable)
	CheckLuaType(hold, TYPE_BOOL)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return end

	CheckPerms(instance, This, "entities.acf")

	This:TriggerInput("Hold Gear", hold)
end

--- Sets the shift point scaling for an automatic ACF gearbox
-- @server
function ents_methods:acfShiftPointScale(scale)
	CheckType(self, ents_metatable)
	CheckLuaType(scale, TYPE_NUMBER)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return end

	CheckPerms(instance, This, "entities.acf")

	This:TriggerInput("Shift Speed Scale", scale)
end

--- Sets the ACF fuel tank refuel duty status, which supplies fuel to other fuel tanks
-- @server
function ents_methods:acfRefuelDuty(on)
	CheckType(self, ents_metatable)
	CheckLuaType(on, TYPE_BOOL)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return end

	CheckPerms(instance, This, "entities.acf")

	This:TriggerInput("Refuel Duty", on)
end

--- Returns the remaining liters or kilowatt hours of fuel in an ACF fuel tank or engine
-- @server
function ents_methods:acfFuel()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end
	if This.Fuel then return math.Round(This.Fuel, 2) end

	local Source = LinkSource(This:GetClass(), "FuelTanks")

	if not Source then return 0 end

	local Fuel = 0

	for Tank in pairs(Source(This)) do
		Fuel = Fuel + Tank.Fuel
	end

	return math.Round(Fuel, 2)
end

--- Returns the amount of fuel in an ACF fuel tank or linked to engine as a percentage of capacity
-- @server
function ents_methods:acfFuelLevel()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end
	if This.Capacity then
		return math.Round(This.Fuel or 0 / This.Capacity, 2)
	end

	local Source = LinkSource(This:GetClass(), "FuelTanks")

	if not Source then return 0 end

	local Capacity = 0
	local Fuel     = 0

	for Tank in pairs(Source(This)) do
		Capacity = Capacity + Tank.Capacity
		Fuel = Fuel + Tank.Fuel
	end

	return math.Round(Fuel / Capacity, 2)
end

--- Returns the current fuel consumption in liters per minute or kilowatts of an engine
-- @server
function ents_methods:acfFuelUse()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end
	if not This.GetConsumption then return 0 end
	if not This.Throttle then return 0 end
	if not This.FlyRPM then return 0 end

	return This:GetConsumption(This.Throttle, This.FlyRPM) * 60
end

--- Returns the peak fuel consumption in liters per minute or kilowatts of an engine at powerband max, for the current fuel type the engine is using
-- @server
function ents_methods:acfPeakFuelUse()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end
	if not This.GetConsumption then return 0 end
	if not This.LimitRPM then return 0 end

	return This:GetConsumption(1, This.LimitRPM) * 60
end

--- returns any wheels linked to This engine/gearbox or child gearboxes
-- @server
function ents_methods:acfGetLinkedWheels()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return {} end

	local Wheels = {}
	local Count = 0

	for Wheel in pairs(GetLinkedWheels(This)) do
		Count = Count + 1
		Wheels[Count] = Wheel
	end

	return Wheels
end

--- Returns true if the ACF gun is ready to fire
-- @server
function ents_methods:acfReady()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return false end

	return This.State == "Loaded"
end

--- Returns a string with the current state of the entity
-- @server
function ents_methods:acfState()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return "" end

	return This.State or ""
end

--- Returns time to next shot of an ACF weapon
-- @server
function ents_methods:acfReloadTime()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end
	if This.State == "Loaded" then return 0 end

	return GetReloadTime(This)
end

--- Returns number between 0 and 1 which represents reloading progress of an ACF weapon. Useful for progress bars
-- @server
function ents_methods:acfReloadProgress()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end
	if not This.NextFire then return This.State == "Loaded" and 1 or 0 end

	return math.Clamp(1 - (This.NextFire - ACF.CurTime) / GetReloadTime(This), 0, 1)
end

--- Returns time it takes for an ACF weapon to reload magazine
-- @server
function ents_methods:acfMagReloadTime()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	return This.MagReload or 0
end

--- Returns the magazine size for an ACF gun
-- @server
function ents_methods:acfMagSize()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	return This.MagSize or 0
end

--- Returns the spread for an ACF gun or flechette ammo
-- @server
function ents_methods:acfSpread()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	local Spread = (This.GetSpread and This:GetSpread()) or This.Spread or 0

	if This.BulletData and This.BulletData.Type == "FL" then -- TODO: Replace this hardcoded bit
		return Spread + (This.BulletData.FlechetteSpread or 0)
	end

	return Spread
end

--- Returns true if an ACF gun is reloading
-- @server
function ents_methods:acfIsReloading()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return false end

	return This.State == "Loading"
end

--- Returns the rate of fire of an acf gun
-- @server
function ents_methods:acfFireRate()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	local Time = This.ReloadTime

	return Time and math.Round(60 / Time, 2) or 0
end

--- Returns the number of rounds left in a magazine for an ACF gun
-- @server
function ents_methods:acfMagRounds()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	return This.CurrentShot or 0
end

--- Sets the firing state of an ACF weapon
-- @server
function ents_methods:acfFire(fire)
	CheckType(self, ents_metatable)
	CheckLuaType(fire, TYPE_BOOL)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return end

	CheckPerms(instance, This, "entities.acf")

	This:TriggerInput("Fire", fire)
end

--- Causes an ACF weapon to unload
-- @server
function ents_methods:acfUnload()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return end

	CheckPerms(instance, This, "entities.acf")

	This:TriggerInput("Unload", true)
end

--- Causes an ACF weapon to reload
-- @server
function ents_methods:acfReload()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return end

	CheckPerms(instance, This, "entities.acf")

	This:TriggerInput("Reload", true)
end

--- Returns the rounds left in an acf ammo crate
-- @server
function ents_methods:acfRounds()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	return This.Ammo or 0
end

--- Returns the type of weapon the ammo in an ACF ammo crate loads into
-- @server
function ents_methods:acfRoundType()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return "" end

	local BulletData = This.BulletData

	return BulletData and BulletData.Id or ""
end

--- Returns the type of ammo in a crate or gun
-- @server
function ents_methods:acfAmmoType()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return "" end

	local BulletData = This.BulletData

	return BulletData and BulletData.Type or ""
end

--- Returns the caliber of an ammo or gun
-- @server
function ents_methods:acfCaliber()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	return This.Caliber or 0
end

--- Returns the muzzle velocity of the ammo in a crate or gun
-- @server
function ents_methods:acfMuzzleVel()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	local BulletData = This.BulletData
	local MuzzleVel  = BulletData and BulletData.MuzzleVel

	return MuzzleVel and MuzzleVel * ACF.Scale or 0
end

--- Returns the mass of the projectile in a crate or gun
-- @server
function ents_methods:acfProjectileMass()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	local BulletData = This.BulletData

	return BulletData and BulletData.ProjMass or 0
end

--- Returns the drag coef of the ammo in a crate or gun
-- @server
function ents_methods:acfDragCoef()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	local BulletData = This.BulletData
	local DragCoef   = BulletData and BulletData.DragCoef

	return DragCoef and DragCoef / ACF.DragDiv or 0
end

--- Returns the fin multiplier of the ammo in a crate or launcher
-- @server
function ents_methods:acfFinMul()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	return This.FinMultiplier or 0
end

-- Returns the weight of the missile in a crate or rack
-- @server
function ents_methods:acfMissileWeight()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	return This.ForcedMass or 0
end

-- Returns the weight of the missile in a crate or rack
-- @server
function ents_methods:acfMissileLength()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	return This.Length or 0
end

--- Returns the number of projectiles in a flechette round
-- @server
function ents_methods:acfFLSpikes()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	local BulletData = This.BulletData

	return BulletData and BulletData.Flechettes or 0
end

--- Returns the mass of a single spike in a FL round in a crate or gun
-- @server
function ents_methods:acfFLSpikeMass()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	local BulletData = This.BulletData

	return BulletData and BulletData.FlechetteMass or 0
end

--- Returns the radius of the spikes in a flechette round in mm
-- @server
function ents_methods:acfFLSpikeRadius()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	local BulletData = This.BulletData
	local Radius     = BulletData and BulletData.FlechetteRadius

	return Radius and math.Round(Radius * 10, 2) or 0
end

--- Returns the penetration of an AP, APHE, or HEAT round
-- @server
function ents_methods:acfPenetration()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	local BulletData = This.BulletData
	local AmmoType   = BulletData and AmmoTypes[BulletData.Type]

	if not AmmoType then return 0 end

	local DisplayData = AmmoType:GetDisplayData(BulletData)
	local MaxPen      = DisplayData and DisplayData.MaxPen

	return MaxPen and Round(MaxPen, 2) or 0
end

--- Returns the blast radius of an HE, APHE, or HEAT round
-- @server
function ents_methods:acfBlastRadius()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	local BulletData = This.BulletData
	local AmmoType   = BulletData and AmmoTypes[BulletData.Type]

	if not AmmoType then return 0 end

	local DisplayData = AmmoType:GetDisplayData(BulletData)
	local Radius      = DisplayData and DisplayData.BlastRadius

	return Radius and Round(Radius, 2) or 0
end

--- Returns the number of rounds in active ammo crates linked to an ACF weapon
-- @server
function ents_methods:acfAmmoCount()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	local Source = LinkSource(This:GetClass(), "Crates")

	if not Source then return 0 end

	local Count = 0

	for Crate in pairs(Source(This)) do
		if Crate:CanConsume() then
			Count = Count + Crate.Ammo
		end
	end

	return Count
end

--- Returns the number of rounds in all ammo crates linked to an ACF weapon
-- @server
function ents_methods:acfTotalAmmoCount()
	CheckType(self, ents_metatable)

	local This = unwrap(self)

	if not IsACFEntity(This) then SF.Throw("Entity is not valid", 2) end
	if RestrictInfo(This) then return 0 end

	local Source = LinkSource(This:GetClass(), "Crates")

	if not Source then return 0 end

	local Count = 0

	for Crate in pairs(Source(This)) do
		Count = Count + Crate.Ammo
	end

	return Count
end

end
