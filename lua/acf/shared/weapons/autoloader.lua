ACF.RegisterWeaponClass("AL", {
	Name        = "Autoloader",
	Description = "A cannon with attached autoloading mechanism. While it allows for several quick shots, the mechanism adds considerable bulk, weight, and magazine reload time.",
	Model       = "models/tankgun/tankgun_al_100mm.mdl",
	Sound       = "acf_base/weapons/autoloader.mp3",
	MuzzleFlash = "cannon_muzzleflash_noscale",
	IsScalable  = true,
	Mass        = 3000,
	Spread      = 0.08,
	Round = {
		MaxLength  = 95,
		PropLength = 70,
	},
	Preview = {
		Height = 60,
		FOV    = 60,
	},
	Caliber	= {
		Base = 100,
		Min  = 75,
		Max  = 140,
	},
	MagSize = {
		Min = 8,
		Max = 5,
	},
	MagReload = {
		Min = 15,
		Max = 35,
	},
	Cyclic = {
		Min = 25,
		Max = 10,
	},
})

ACF.RegisterWeapon("75mmAL", "AL", {
	Caliber = 75,
})

ACF.RegisterWeapon("100mmAL", "AL", {
	Caliber = 100,
})

ACF.RegisterWeapon("120mmAL", "AL", {
	Caliber = 120,
})

ACF.RegisterWeapon("140mmAL", "AL", {
	Caliber = 140,
})

ACF.SetCustomAttachment("models/tankgun/tankgun_al_100mm.mdl", "muzzle", Vector(146.2), Angle(0, 0, 90))

ACF.AddHitboxes("models/tankgun/tankgun_al_100mm.mdl", {
	Breech = {
		Pos       = Vector(-35.33),
		Scale     = Vector(84, 16, 12),
		Sensitive = true
	},
	Barrel = {
		Pos   = Vector(76.67),
		Scale = Vector(140, 9, 9)
	},
	LeftDrum = {
		Pos   = Vector(-57.33, 16, 3),
		Scale = Vector(40, 16, 16)
		-- Critical = true
	},
	RightDrum = {
		Pos   = Vector(-57.33, -16, 3),
		Scale = Vector(40, 16, 16)
		-- Critical = true
	}
})
