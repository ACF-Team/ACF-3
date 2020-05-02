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
				Name = "_acf_gun",
				Amount = 16,
				Text = "Maximum amount of weapons a player can create."
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

		if not Class.EntClass then
			Class.EntClass = "acf_gun"
		end

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
		local Class = AddSimpleClass(ID, Crates, Data)

		if not Class.EntClass then
			Class.EntClass = "acf_ammo"
		end

		return Class
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
				Text = "Maximum amount of engines a player can create."
			}
		end

		AddSboxLimit(Group.LimitConVar)

		return Group
	end

	function ACF.RegisterEngine(ID, ClassID, Data)
		local Class = AddGroupedClass(ID, ClassID, Engines, Data)

		if not Class.EntClass then
			Class.EntClass = "acf_engine"
		end

		return Class
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
				Amount = 24,
				Text = "Maximum amount of fuel tanks a player can create."
			}
		end

		AddSboxLimit(Group.LimitConVar)

		return Group
	end

	function ACF.RegisterFuelTank(ID, ClassID, Data)
		local Class = AddGroupedClass(ID, ClassID, FuelTanks, Data)

		if not Class.EntClass then
			Class.EntClass = "acf_engine"
		end

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
				Text = "Maximum amount of gearboxes a player can create."
			}
		end

		AddSboxLimit(Group.LimitConVar)

		return Group
	end

	function ACF.RegisterGearbox(ID, ClassID, Data)
		local Class = AddGroupedClass(ID, ClassID, Gearboxes, Data)

		if not Class.EntClass then
			Class.EntClass = "acf_gearbox"
		end

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
		return AddClassGroup(ID, Components, Data)
	end

	function ACF.RegisterComponent(ID, ClassID, Data)
		return AddGroupedClass(ID, ClassID, Components, Data)
	end
end

do -- Sensor registration functions
	ACF.Classes.Sensors = ACF.Classes.Sensors or {}

	local Sensors = ACF.Classes.Sensors

	function ACF.RegisterSensorClass(ID, Data)
		return AddClassGroup(ID, Sensors, Data)
	end

	function ACF.RegisterSensor(ID, ClassID, Data)
		return AddGroupedClass(ID, ClassID, Sensors, Data)
	end
end

-- Serverside-only stuff
if CLIENT then return end

do -- Entity class registration function
	ACF.Classes.Entities = ACF.Classes.Entities or {}

	local Entities = ACF.Classes.Entities
	local VarLookup = {}
	local VarList = {}

	function ACF.RegisterEntityClass(Class, Function, ...)
		if not isstring(Class) then return end
		if not isfunction(Function) then return end

		Entities[Class] = {
			Spawn = Function,
		}

		local Vars = istable(...) and ... or { ... }
		local Lookup, List = {}, {}
		local Count = 0

		for _, V in pairs(Vars) do
			Count = Count + 1

			Lookup[V] = true
			List[Count] = V
		end

		VarLookup[Class] = Lookup
		VarList[Class] = List

		duplicator.RegisterEntityClass(Class, Function, "Pos", "Angle", "Data", unpack(List))
	end

	function ACF.AddEntClassVars(Class, ...)
		if not isstring(Class) then return end
		if not Entities[Class] then return end

		local Vars = istable(...) and ... or { ... }
		local Lookup = VarLookup[Class]
		local List = VarList[Class]
		local Count = #List

		for _, V in pairs(Vars) do
			if not Lookup[V] then
				Count = Count + 1

				Lookup[V] = true
				List[Count] = V
			end
		end

		duplicator.RegisterEntityClass(Class, Function, "Pos", "Angle", "Data", unpack(List))
	end

	function ACF.GetEntityClass(Class)
		if not Class then return end

		return Entities[Class]
	end

	function ACF.GetEntClassVars(Class)
		if not Class then return end
		if not VarList[Class] then return end

		local List = {}

		for K, V in ipairs(VarList[Class]) do
			List[K] = V
		end

		return List
	end
end
