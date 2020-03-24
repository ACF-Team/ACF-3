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
		if not ID then return end
		if not Data then return end

		local Class = Weapons[ID]

		if not Class then
			Class = {
				ID = ID,
				Lookup = {},
				Items = {},
				Count = 0,
			}

			Weapons[ID] = Class
		end

		for K, V in pairs(Data) do
			Class[K] = V
		end

		if Class.MuzzleFlash then
			PrecacheParticleSystem(Class.MuzzleFlash)
		end
	end

	function ACF.RegisterWeapon(ID, ClassID, Data)
		if not ID then return end
		if not ClassID then return end
		if not Data then return end
		if not Weapons[ClassID] then return end

		local Class  = Weapons[ClassID]
		local Weapon = Class.Lookup[ID]

		if not Weapon then
			Weapon = {
				ID = ID,
				Class = Class,
				ClassID = ClassID,
				EntClass = "acf_gun",
			}

			Class.Count = Class.Count + 1
			Class.Items[Class.Count] = Weapon
			Class.Lookup[ID] = Weapon
		end

		for K, V in pairs(Data) do
			Weapon[K] = V
		end

		if Weapon.MuzzleFlash then
			PrecacheParticleSystem(Weapon.MuzzleFlash)
		end
	end
end

do -- Ammo crate registration function
	ACF.Classes.Crates = ACF.Classes.Crates or {}

	local Crates = ACF.Classes.Crates

	function ACF.RegisterCrate(ID, Data)
		if not ID then return end
		if not Data then return end

		local Crate = Crates[ID]

		if not Crate then
			Crate = {
				ID = ID,
				EntClass = "acf_ammo",
			}

			Crates[ID] = Crate
		end

		for K, V in pairs(Data) do
			Crate[K] = V
		end
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
		if not ID then return end
		if not Data then return end

		local Class = Engines[ID]

		if not Class then
			Class = {
				ID = ID,
				Lookup = {},
				Items = {},
				Count = 0,
			}

			Engines[ID] = Class
		end

		for K, V in pairs(Data) do
			Class[K] = V
		end
	end

	function ACF.RegisterEngine(ID, ClassID, Data)
		if not ID then return end
		if not ClassID then return end
		if not Data then return end
		if not Engines[ClassID] then return end

		local Class  = Engines[ClassID]
		local Engine = Class.Lookup[ID]

		if not Engine then
			Engine = {
				ID = ID,
				Class = Class,
				ClassID = ClassID,
				EntClass = "acf_engine",
			}

			Class.Count = Class.Count + 1
			Class.Items[Class.Count] = Engine
			Class.Lookup[ID] = Engine
		end

		for K, V in pairs(Data) do
			Engine[K] = V
		end
	end
end

do -- Engine type registration function
	ACF.Classes.EngineTypes = ACF.Classes.EngineTypes or {}

	local Types = ACF.Classes.EngineTypes

	function ACF.RegisterEngineType(ID, Data)
		if not ID then return end
		if not Data then return end

		local Type = Types[ID]

		if not Type then
			Type = {
				ID = ID,
			}

			Types[ID] = Type
		end

		for K, V in pairs(Data) do
			Type[K] = V
		end
	end
end

do -- Fuel tank registration functions
	ACF.Classes.FuelTanks = ACF.Classes.FuelTanks or {}

	local FuelTanks = ACF.Classes.FuelTanks

	function ACF.RegisterFuelTankClass(ID, Data)
		if not ID then return end
		if not Data then return end

		local Class = FuelTanks[ID]

		if not Class then
			Class = {
				ID = ID,
				Lookup = {},
				Items = {},
				Count = 0,
			}

			FuelTanks[ID] = Class
		end

		for K, V in pairs(Data) do
			Class[K] = V
		end
	end

	function ACF.RegisterFuelTank(ID, ClassID, Data)
		if not ID then return end
		if not ClassID then return end
		if not Data then return end
		if not FuelTanks[ClassID] then return end

		local Class  = FuelTanks[ClassID]
		local FuelTank = Class.Lookup[ID]

		if not FuelTank then
			FuelTank = {
				ID = ID,
				Class = Class,
				ClassID = ClassID,
				EntClass = "acf_engine",
				IsExplosive = true,
			}

			Class.Count = Class.Count + 1
			Class.Items[Class.Count] = FuelTank
			Class.Lookup[ID] = FuelTank
		end

		for K, V in pairs(Data) do
			FuelTank[K] = V
		end
	end
end

do -- Fuel type registration function
	ACF.Classes.FuelTypes = ACF.Classes.FuelTypes or {}

	local Types = ACF.Classes.FuelTypes

	function ACF.RegisterFuelType(ID, Data)
		if not ID then return end
		if not Data then return end

		local Type = Types[ID]

		if not Type then
			Type = {
				ID = ID,
			}

			Types[ID] = Type
		end

		for K, V in pairs(Data) do
			Type[K] = V
		end
	end
end

do -- Gearbox registration functions
	ACF.Classes.Gearboxes = ACF.Classes.Gearboxes or {}

	local Gearboxes = ACF.Classes.Gearboxes

	function ACF.RegisterGearboxClass(ID, Data)
		if not ID then return end
		if not Data then return end

		local Class = Gearboxes[ID]

		if not Class then
			Class = {
				ID = ID,
				Lookup = {},
				Items = {},
				Count = 0,
			}

			Gearboxes[ID] = Class
		end

		for K, V in pairs(Data) do
			Class[K] = V
		end
	end

	function ACF.RegisterGearbox(ID, ClassID, Data)
		if not ID then return end
		if not ClassID then return end
		if not Data then return end
		if not Gearboxes[ClassID] then return end

		local Class   = Gearboxes[ClassID]
		local Gearbox = Class.Lookup[ID]

		if not Gearbox then
			Gearbox = {
				ID = ID,
				Class = Class,
				ClassID = ClassID,
				EntClass = "acf_gearbox",
				Sound = "vehicles/junker/jnk_fourth_cruise_loop2.wav",
			}

			Class.Count = Class.Count + 1
			Class.Items[Class.Count] = Gearbox
			Class.Lookup[ID] = Gearbox
		end

		for K, V in pairs(Data) do
			Gearbox[K] = V
		end
	end
end
