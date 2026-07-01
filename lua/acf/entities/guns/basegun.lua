local Classes = ACF.Classes

Classes.DefineClass("ACF.Guns.BaseGun", "ACF.Weapons.BaseWeapon", function()
	CLASS.Cleanup 			= "acf_gun"
	CLASS.IsScalable 		= false
	-- IsWeapon marks a class that shows up in the weapon menu's class list (replaces the old group classes).
	CLASS.IsWeapon      	= false
	-- IsWeaponOption marks a concrete, selectable variant of a non-scalable weapon (e.g. the
	-- 40mm Flare Launcher under the Flare Launcher category). The weapon menu lists IsWeapon classes
	-- and, for non-scalable ones, their IsWeaponOption subtypes (see menu/items_cl/weapons.lua).
	CLASS.IsWeaponOption	= false

	function CLASS.__inherited(NewClass)
		if not NewClass.LimitConVar then
			NewClass.LimitConVar = {
				Name   = "_acf_weapon", -- should rename this...
				Amount = 16,
				Text   = "Maximum amount of ACF weapons a player can create."
			}
		end
		Classes.AddSboxLimit(NewClass.LimitConVar)

		if NewClass.MuzzleFlash then
			PrecacheParticleSystem(NewClass.MuzzleFlash)
		end
	end

	function CLASS:VerifyData()

	end
end)

Classes.DefineClass("ACF.Guns.BaseScalableGun", "ACF.Guns.BaseGun", function()
	local BASE = BASE
	CLASS.IsScalable = true

	MENU_FIELD("Number", "Caliber",	{Default = 50})
	CLASS.CaliberLimits = {Base = 50, Min = 25, Max = 75}

	function CLASS.__inherited()

	end

	function CLASS:VerifyData()
		BASE.VerifyData(self)
		local Limits = self.CaliberLimits
		self.Caliber = math.Clamp(self.Caliber or 0, Limits.Min, Limits.Max)
	end

	function CLASS:WeaponEquals(Other)
		return BASE.WeaponEquals(self, Other) and self.Caliber == Other.Caliber
	end
end)