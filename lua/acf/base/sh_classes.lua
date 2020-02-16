do -- Weapon class registration functions
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
				Type = "Weapons",
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