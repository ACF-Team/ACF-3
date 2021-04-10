ACF.RegisterWeaponClass("MG", {
	Name        = "Machinegun",
	Description = "The lightest piece of automatic weaponry, machineguns offer a high rate of fire and good magazine size at the cost of a poor variety of ammo types.",
	Model       = "models/machinegun/machinegun_20mm.mdl",
	Sound       = "acf_base/weapons/mg_fire4.mp3",
	MuzzleFlash = "mg_muzzleflash_noscale",
	IsScalable  = true,
	IsBoxed     = true,
	Spread      = 0.16,
	Mass        = 53,
	Round = {
		MaxLength  = 16,
		PropLength = 13,
	},
	Preview = {
		Height = 60,
		FOV    = 60,
	},
	Caliber	= {
		Base = 20,
		Min  = 5.56,
		Max  = 20,
	},
	MagSize = {
		Min = 400,
		Max = 100,
	},
	MagReload = {
		Min = 5,
		Max = 12,
	},
	Cyclic = {
		Min = 900,
		Max = 600,
	},
})

ACF.RegisterWeapon("7.62mmMG", "MG", {
	Caliber = 7.62,
})

ACF.RegisterWeapon("12.7mmMG", "MG", {
	Caliber = 12.7,
})

ACF.RegisterWeapon("13mmHMG", "MG", {
	Caliber = 13,
})

ACF.RegisterWeapon("14.5mmMG", "MG", {
	Caliber = 14.5,
})

ACF.RegisterWeapon("20mmMG", "MG", {
	Caliber = 20,
})

ACF.SetCustomAttachment("models/machinegun/machinegun_20mm.mdl", "muzzle", Vector(53.05, 0, -0.11), Angle(0, 0, 90))

ACF.AddHitboxes("models/machinegun/machinegun_20mm.mdl", {
	Frame = {
		Pos   = Vector(-5, 0.2, -1.5),
		Scale = Vector(18, 2, 6),
		Sensitive = true,
	},
	Barrel = {
		Pos = Vector(28, 0, 0),
		Scale = Vector(49, 1.15, 1.15),
		Cylinder = true
	}
})
