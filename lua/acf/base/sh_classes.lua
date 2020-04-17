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
		end

		for K, V in pairs(Data) do
			Class[K] = V
		end

		return Class
	end
end

local AddSimpleClass  = ACF.AddSimpleClass
local AddClassGroup   = ACF.AddClassGroup
local AddGroupedClass = ACF.AddGroupedClass

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
		return AddClassGroup(ID, Engines, Data)
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
		return AddClassGroup(ID, FuelTanks, Data)
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
		return AddClassGroup(ID, Gearboxes, Data)
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

	function ACF.RegisterEntityClass(Class, Function, Data)
		if not isstring(Class) then return end
		if not isfunction(Function) then return end

		local Entity = {
			Spawn = Function,
		}

		if istable(Data) then
			for K, V in pairs(Data) do
				Entity[K] = V
			end
		end

		Entities[Class] = Entity

		duplicator.RegisterEntityClass(Class, Function, "Pos", "Angle", "Data")
	end

	function ACF.GetEntityClass(Class)
		if not Class then return end

		return Entities[Class]
	end
end
