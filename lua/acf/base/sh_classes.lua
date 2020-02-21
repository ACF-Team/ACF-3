do -- Class registration function
	local Classes = {}
	local Queued = {}

	local function CreateInstance(Class)
		local New = {}

		setmetatable(New, { __index = Class })

		if New.OnCalled then
			New:OnCalled()
		end

		return New
	end

	local function QueueBaseClass(Name, Base)
		if not Queued[Base] then
			Queued[Base] = { [Name] = true }
		else
			Queued[Base][Name] = true
		end
	end

	local function AttachMetaTable(Class, Name, Base)
		local OldMeta = getmetatable(Class) or {}

		if Base then
			local BaseClass = Classes[Base]

			if BaseClass then
				Class.BaseClass = BaseClass
				OldMeta.__index = BaseClass
			else
				QueueBaseClass(Name, Base)
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

	function ACF.RegisterClass(Name, Base, Destiny)
		if not Classes[Name] then
			Classes[Name] = {}
		end

		local Class = Classes[Name]
		Class.Name = Name

		AttachMetaTable(Class, Name, Base)

		if Queued[Name] then
			local Current

			for K in pairs(Queued[Name]) do
				Current = Classes[K]

				AttachMetaTable(Current, Current.Name, Name)
			end

			Queued[Name] = nil
		end

		if Destiny then
			Destiny[Name] = Class
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