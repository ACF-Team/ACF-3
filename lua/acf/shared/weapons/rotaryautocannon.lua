ACF.RegisterWeaponClass("RAC", {
	Name        = "Rotary Autocannon",
	Description = "Rotary Autocannons sacrifice weight, bulk and accuracy over classic autocannons to get the highest rate of fire possible.",
	Model       = "models/rotarycannon/kw/20mmrac.mdl",
	Sound       = "acf_base/weapons/mg_fire3.mp3",
	MuzzleFlash = "mg_muzzleflash_noscale",
	IsScalable  = true,
	Spread      = 0.48,
	Mass        = 500,
	Cyclic      = 2000,
	Round = {
		MaxLength  = 25,
		PropLength = 20,
	},
	Preview = {
		Height = 90,
		FOV    = 60,
	},
	Caliber	= {
		Base = 20,
		Min  = 7.62,
		Max  = 37,
	},
	MagSize = {
		Min = 450,
		Max = 150,
	},
	MagReload = {
		Min = 8,
		Max = 15,
	},
})

ACF.RegisterWeapon("14.5mmRAC", "RAC", {
	Caliber = 14.5,
})

ACF.RegisterWeapon("20mmRAC", "RAC", {
	Caliber = 20,
})

ACF.RegisterWeapon("30mmRAC", "RAC", {
	Caliber = 30,
})

ACF.RegisterWeapon("20mmHRAC", "RAC", {
	Caliber = 20,
})

ACF.RegisterWeapon("30mmHRAC", "RAC", {
	Caliber = 30,
})

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
