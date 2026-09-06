local ACF     = ACF

ACF.Classes.DefineClass("ACF.Guns.RotaryAutocannon", "ACF.Guns.BaseScalableGun", function(CLASS)
	CLASS.Name        	= "Rotary Autocannon"
	CLASS.ID 			= "RAC"
	CLASS.IsWeapon		= true
	CLASS.Description 	= "#acf.descs.weapons.rac"
	CLASS.Model       	= "models/rotarycannon/kw/20mmrac.mdl"
	CLASS.MassCenter    = Vector(0, 0, 0)
	CLASS.Sound       	= "acf_base/weapons/mg_fire3.mp3"
	CLASS.MuzzleFlash 	= "mg_muzzleflash_noscale"
	CLASS.IsAutomatic 	= true
	CLASS.IsBelted		= true
	CLASS.Spread      	= 0.48
	CLASS.Mass        	= 212
	CLASS.Cyclic      	= 2000
	CLASS.ScaleFactor 	= 1.0 -- Corrective factor to account for improperly scaled base models
	CLASS.Round 		= {
		MaxLength  = 16,
		PropLength = 13,
		CaseScale  = 1.46, -- 37x219mm (T250 rotary): 54mm case over a 37mm projectile
	}
	CLASS.Preview 		= {
		Height = 90,
		FOV    = 60,
	}
	CLASS.CaliberLimits	= {
		Base = 20,
		Min  = 7.62,
		Max  = 37,
	}
	CLASS.LimitConVar 	= {
		Name = "_acf_rotaryautocannon",
		Amount = 2,
		Text = "Maximum amount of ACF rotary auto cannons a player can create."
	}
	CLASS.CostScalar	= 1.75
end)

ACF.SetCustomAttachment("models/rotarycannon/kw/20mmrac.mdl", "muzzle", Vector(59.6, 0, 1.74))

ACF.AddHitboxes("models/rotarycannon/kw/20mmrac.mdl", {
	Breech = {
		Pos       = Vector(1.7, 0, 0.1),
		Scale     = Vector(16, 9, 8),
		Sensitive = true
	},
	Barrel = {
		Pos   = Vector(35),
		Scale = Vector(50, 4, 4)
	}
})
