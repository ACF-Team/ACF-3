do -- Basic class registration functions
	function ACF.AddSimpleClass(ID, Destiny, Data)
		if not ID then return end
		if not Data then return end
		if not Destiny then return end

		local Class = Destiny[ID]

		if not Class then
			Class = {
				ID = ID,
			}

			Destiny[ID] = Class
		end

		for K, V in pairs(Data) do
			Class[K] = V
		end

		hook.Run("ACF_OnNewSimpleClass", ID, Class)

		return Class
	end

	function ACF.AddClassGroup(ID, Destiny, Data)
		if not ID then return end
		if not Data then return end
		if not Destiny then return end

		local Group = Destiny[ID]

		if not Group then
			Group = {
				ID = ID,
				Lookup = {},
				Items = {},
				Count = 0,
			}

			Destiny[ID] = Group
		end

		for K, V in pairs(Data) do
			Group[K] = V
		end

		hook.Run("ACF_OnNewClassGroup", ID, Group)

		return Group
	end

	local Groups = {}

	local function GetDestinyData(Destiny)
		local Data = Groups[Destiny]

		if not Data then
			Data = {}

			Groups[Destiny] = Data
		end

		return Data
	end

	function ACF.AddGroupedClass(ID, GroupID, Destiny, Data)
		if not ID then return end
		if not Data then return end
		if not GroupID then return end
		if not Destiny then return end
		if not Destiny[GroupID] then return end

		local Group = Destiny[GroupID]
		local Class = Group.Lookup[ID]

		if not Class then
			Class = {
				ID = ID,
				Class = Group,
				ClassID = GroupID,
			}

			Group.Count = Group.Count + 1
			Group.Lookup[ID] = Class
			Group.Items[Group.Count] = Class

			local DestinyData = GetDestinyData(Destiny)
			DestinyData[ID] = Group
		end

		for K, V in pairs(Data) do
			Class[K] = V
		end

		hook.Run("ACF_OnNewGroupedClass", ID, Group, Class)

		return Class
	end

	function ACF.GetClassGroup(Destiny, Class)
		if not Destiny then return end
		if not Class then return end

		local Data = Groups[Destiny]

		return Data and Data[Class]
	end
end

local AddSimpleClass  = ACF.AddSimpleClass
local AddClassGroup   = ACF.AddClassGroup
local AddGroupedClass = ACF.AddGroupedClass

local function AddSboxLimit(Data)
	if CLIENT then return end
	if ConVarExists("sbox_max" .. Data.Name) then return end

	CreateConVar("sbox_max" .. Data.Name,
				Data.Amount,
				FCVAR_ARCHIVE + FCVAR_NOTIFY,
				Data.Text or "")
end

do -- Class registration function
	local Classes = {}
	local Queued = {}

	local function CreateInstance(Class)
		local New = {}

		setmetatable(New, { __index = table.Copy(Class) })

		if New.OnCalled then
			New:OnCalled()
		end

		return New
	end

	local function QueueBaseClass(ID, Base)
		if not Queued[Base] then
			Queued[Base] = { [ID] = true }
		else
			Queued[Base][ID] = true
		end
	end

	local function AttachMetaTable(Class, Base)
		local OldMeta = getmetatable(Class) or {}

		if Base then
			local BaseClass = Classes[Base]

			if BaseClass then
				Class.BaseClass = BaseClass
				OldMeta.__index = BaseClass
			else
				QueueBaseClass(Class.ID, Base)
			end
		end

		OldMeta.__call = function()
			return CreateInstance(Class)
		end

		setmetatable(Class, OldMeta)

		timer.Simple(0, function()
			if Class.OnLoaded then
				Class:OnLoaded()
			end

			hook.Run("ACF_OnClassLoaded", Class.ID, Class)

			Class.Loaded = true
		end)
	end

	function ACF.RegisterClass(ID, Base, Destiny)
		if not Classes[ID] then
			Classes[ID] = {}
		end

		local Class = Classes[ID]
		Class.ID = ID

		AttachMetaTable(Class, Base)

		if Queued[ID] then
			for K in pairs(Queued[ID]) do
				AttachMetaTable(Classes[K], ID)
			end

			Queued[ID] = nil
		end

		if Destiny then
			Destiny[ID] = Class
		end

		return Class
	end
end

do -- Weapon registration functions
	ACF.Classes.Weapons = ACF.Classes.Weapons or {}

	local Weapons = ACF.Classes.Weapons

	function ACF.RegisterWeaponClass(ID, Data)
		local Group = AddClassGroup(ID, Weapons, Data)

		if not Group.LimitConVar then
			Group.LimitConVar = {
				Name = "_acf_weapon",
				Amount = 16,
				Text = "Maximum amount of ACF weapons a player can create."
			}
		end

		AddSboxLimit(Group.LimitConVar)

		if Group.MuzzleFlash then
			PrecacheParticleSystem(Group.MuzzleFlash)
		end

		return Group
	end

	function ACF.RegisterWeapon(ID, ClassID, Data)
		local Class = AddGroupedClass(ID, ClassID, Weapons, Data)

		Class.Destiny = "Weapons"

		if Class.MuzzleFlash then
			PrecacheParticleSystem(Class.MuzzleFlash)
		end

		return Class
	end
end

do -- Ammo crate registration function
	ACF.Classes.Crates = ACF.Classes.Crates or {}

	local Crates = ACF.Classes.Crates

	function ACF.RegisterCrate(ID, Data)
		return AddSimpleClass(ID, Crates, Data)
	end
end

do -- Ammo type registration function
	ACF.Classes.AmmoTypes = ACF.Classes.AmmoTypes or {}

	local RegisterClass = ACF.RegisterClass
	local Types = ACF.Classes.AmmoTypes

	function ACF.RegisterAmmoType(ID, Base)
		return RegisterClass(ID, Base, Types)
	end
end

do -- Engine registration functions
	ACF.Classes.Engines = ACF.Classes.Engines or {}

	local Engines = ACF.Classes.Engines

	function ACF.RegisterEngineClass(ID, Data)
		local Group = AddClassGroup(ID, Engines, Data)

		if not Group.LimitConVar then
			Group.LimitConVar = {
				Name = "_acf_engine",
				Amount = 16,
				Text = "Maximum amount of ACF engines a player can create."
			}
		end

		AddSboxLimit(Group.LimitConVar)

		return Group
	end

	function ACF.RegisterEngine(ID, ClassID, Data)
		return AddGroupedClass(ID, ClassID, Engines, Data)
	end
end

do -- Engine type registration function
	ACF.Classes.EngineTypes = ACF.Classes.EngineTypes or {}

	local Types = ACF.Classes.EngineTypes

	function ACF.RegisterEngineType(ID, Data)
		return AddSimpleClass(ID, Types, Data)
	end
end

do -- Fuel tank registration functions
	ACF.Classes.FuelTanks = ACF.Classes.FuelTanks or {}

	local FuelTanks = ACF.Classes.FuelTanks

	function ACF.RegisterFuelTankClass(ID, Data)
		local Group = AddClassGroup(ID, FuelTanks, Data)

		if not Group.LimitConVar then
			Group.LimitConVar = {
				Name = "_acf_fueltank",
				Amount = 32,
				Text = "Maximum amount of ACF fuel tanks a player can create."
			}
		end

		AddSboxLimit(Group.LimitConVar)

		return Group
	end

	function ACF.RegisterFuelTank(ID, ClassID, Data)
		local Class = AddGroupedClass(ID, ClassID, FuelTanks, Data)

		if Class.IsExplosive == nil then
			Class.IsExplosive = true
		end

		return Class
	end
end

do -- Fuel type registration function
	ACF.Classes.FuelTypes = ACF.Classes.FuelTypes or {}

	local Types = ACF.Classes.FuelTypes

	function ACF.RegisterFuelType(ID, Data)
		return AddSimpleClass(ID, Types, Data)
	end
end

do -- Gearbox registration functions
	ACF.Classes.Gearboxes = ACF.Classes.Gearboxes or {}

	local Gearboxes = ACF.Classes.Gearboxes

	function ACF.RegisterGearboxClass(ID, Data)
		local Group = AddClassGroup(ID, Gearboxes, Data)

		if not Group.LimitConVar then
			Group.LimitConVar = {
				Name = "_acf_gearbox",
				Amount = 24,
				Text = "Maximum amount of ACF gearboxes a player can create."
			}
		end

		AddSboxLimit(Group.LimitConVar)

		return Group
	end

	function ACF.RegisterGearbox(ID, ClassID, Data)
		local Class = AddGroupedClass(ID, ClassID, Gearboxes, Data)

		if not Class.Sound then
			Class.Sound = "vehicles/junker/jnk_fourth_cruise_loop2.wav"
		end

		return Class
	end
end

do -- Component registration functions
	ACF.Classes.Components = ACF.Classes.Components or {}

	local Components = ACF.Classes.Components

	function ACF.RegisterComponentClass(ID, Data)
		local Group = AddClassGroup(ID, Components, Data)

		if not Group.LimitConVar then
			Group.LimitConVar = {
				Name = "_acf_misc",
				Amount = 32,
				Text = "Maximum amount of ACF components a player can create."
			}
		end

		AddSboxLimit(Group.LimitConVar)

		return Group
	end

	function ACF.RegisterComponent(ID, ClassID, Data)
		return AddGroupedClass(ID, ClassID, Components, Data)
	end
end

do -- Sensor registration functions
	ACF.Classes.Sensors = ACF.Classes.Sensors or {}

	local Sensors = ACF.Classes.Sensors

	function ACF.RegisterSensorClass(ID, Data)
		local Group = AddClassGroup(ID, Sensors, Data)

		if not Group.LimitConVar then
			Group.LimitConVar = {
				Name = "_acf_sensor",
				Amount = 16,
				Text = "Maximum amount of ACF sensors a player can create."
			}
		end

		AddSboxLimit(Group.LimitConVar)

		return Group
	end

	function ACF.RegisterSensor(ID, ClassID, Data)
		return AddGroupedClass(ID, ClassID, Sensors, Data)
	end
end

do -- Entity class registration function
	ACF.Classes.Entities = ACF.Classes.Entities or {}

	local Entities = ACF.Classes.Entities

	local function GetEntityTable(Class)
		if Entities[Class] then return Entities[Class] end

		local Table = {
			Lookup = {},
			Count = 0,
			List = {},
		}

		Entities[Class] = Table

		return Table
	end

	local function AddArguments(Entity, Arguments)
		local Lookup = Entity.Lookup
		local Count = Entity.Count
		local List = Entity.List

		for _, V in ipairs(Arguments) do
			if not Lookup[V] then
				Count = Count + 1

				Lookup[V] = true
				List[Count] = V
			end
		end

		Entity.Count = Count

		return List
	end

	function ACF.RegisterEntityClass(Class, Function, ...)
		if not isstring(Class) then return end
		if not isfunction(Function) then return end

		local Entity = GetEntityTable(Class)
		local Arguments = istable(...) and ... or { ... }
		local List = AddArguments(Entity, Arguments)

		Entity.Spawn = Function

		duplicator.RegisterEntityClass(Class, Function, "Pos", "Angle", "Data", unpack(List))
	end

	function ACF.AddEntityArguments(Class, ...)
		if not isstring(Class) then return end

		local Entity = GetEntityTable(Class)
		local Arguments = istable(...) and ... or { ... }
		local List = AddArguments(Entity, Arguments)

		if Entity.Spawn then
			duplicator.RegisterEntityClass(Class, Entity.Spawn, "Pos", "Angle", "Data", unpack(List))
		end
	end

	function ACF.GetEntityClass(Class)
		if not Class then return end

		return Entities[Class]
	end

	function ACF.GetEntityArguments(Class)
		if not isstring(Class) then return end

		local Entity = GetEntityTable(Class)
		local List = {}

		for K, V in ipairs(Entity.List) do
			List[K] = V
		end

		return List
	end
end

do -- Discontinued functions
	function ACF_defineGunClass(ID)
		print("Attempted to register weapon class " .. ID .. " with a discontinued function. Use ACF.RegisterWeaponClass instead.")
	end

	function ACF_defineGun(ID)
		print("Attempted to register weapon " .. ID .. " with a discontinued function. Use ACF.RegisterWeapon instead.")
	end

	function ACF_DefineEngine(ID)
		print("Attempted to register engine " .. ID .. " with a discontinued function. Use ACF.RegisterEngine instead.")
	end

	function ACF_DefineGearbox(ID)
		print("Attempted to register gearbox " .. ID .. " with a discontinued function. Use ACF.RegisterGearbox instead.")
	end

	function ACF_DefineFuelTank(ID)
		print("Attempted to register fuel tank type " .. ID .. " with a discontinued function. Use ACF.RegisterFuelTankClass instead.")
	end

	function ACF_DefineFuelTankSize(ID)
		print("Attempted to register fuel tank " .. ID .. " with a discontinued function. Use ACF.RegisterFuelTank instead.")
	end
end
