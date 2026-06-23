local ACF     = ACF

ACF.Classes.DefineClass("ACF.Guns.LightAutocannon", "ACF.Guns.BaseScalableGun", function()
	CLASS.Name        		= "Light Autocannon"
	CLASS.ID				= "LAC"
	CLASS.IsWeapon			= true
	CLASS.Description 		= "#acf.descs.weapons.lac"
	CLASS.Model       		= "models/machinegun/machinegun_40mm_compact.mdl"
	CLASS.Sound       		= "acf_base/weapons/mg_fire3.mp3"
	CLASS.MuzzleFlash 		= "mg_muzzleflash_noscale"
	CLASS.IsAutomatic 		= true
	CLASS.IsBelted			= true
	CLASS.Mass        		= 301
	CLASS.Spread      		= 0.48
	CLASS.ScaleFactor 		= 0.81 -- Corrective factor to account for improperly scaled base models
	CLASS.ReloadMod 		= 0.5 -- Load time multiplier. Represents the ease of manipulating the weapon's ammunition
	CLASS.TransferMult 		= 20 -- Thermal energy transfer rate
	CLASS.CyclicCeilMult 	= 2 -- How high above base cyclic the gun can be set to
	CLASS.Round 			= {
		MaxLength  = 32,
		PropLength = 26,
	}
	CLASS.LongBarrel 		= {
		Index    = 2,
		Submodel = 4,
		NewPos   = "muzzle2",
	}
	CLASS.Preview 			= {
		Height = 100,
		FOV    = 60,
	}
	CLASS.CaliberLimits		= {
		Base = 40,
		Min  = 20,
		Max  = 40,
	}
	CLASS.MagSize 			= {
		Min = 250,
		Max = 100,
	}
	CLASS.MagReload 	= {
		Min = 6,
		Max = 12,
	}
	CLASS.Cyclic 		= {
		Min = 600,
		Max = 400,
	}
	CLASS.LimitConVar 		= {
		Name = "_acf_lightautocannon",
		Amount = 4,
		Text = "Maximum amount of ACF light auto cannons a player can create."
	}
	CLASS.CostScalar		= 0.5
end)

ACF.SetCustomAttachments("models/machinegun/machinegun_40mm_compact.mdl", {
	{ Name = "muzzle", Pos = Vector(51.04, -0.03), Ang = Angle(0, 0, 90) },
	{ Name = "muzzle2", Pos = Vector(115.39, -0.25), Ang = Angle(0, 0, 90) },
})

ACF.AddHitboxes("models/machinegun/machinegun_40mm_compact.mdl", {
	Base = {
		Pos   = Vector(17.5),
		Scale = Vector(68, 5, 10)
	}
})
