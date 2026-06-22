local Classes = ACF.Classes

Classes.DefineClass("ACF.Guns.BaseGun", function()
	CLASS.Cleanup 		= "acf_gun"
	CLASS.IsScalable 	= false

	function CLASS.__inherited(NewClass)
		if not NewClass.LimitConvar then
			NewClass.LimitConvar = {
				Name   = "_acf_weapon", -- should rename this...
				Amount = 16,
				Text   = "Maximum amount of ACF weapons a player can create."
			}
		end

		Classes.AddSboxLimit(NewClass.LimitConvar)

		if NewClass.MuzzleFlash then
			PrecacheParticleSystem(Group.MuzzleFlash)
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

	function CLASS.__inherited(NewClass)
		BASE.__inherited(NewClass)
	end

	function CLASS:VerifyData()
		BASE.VerifyData(self)
		local Limits = self.CaliberLimits
		self.Caliber = math.Clamp(self.Caliber or 0, Limits.Min, Limits.Max)
	end
end)