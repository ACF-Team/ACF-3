ACF.RegisterWeaponClass("AL", {
	Name        = "Autoloaded Cannon",
	Description = "An improvement over cannons that allows you fire multiple rounds in succesion at the cost of internal volume, mass and reload speed.",
	Model       = "models/tankgun/tankgun_al_100mm.mdl",
	Sound       = "acf_base/weapons/autoloader.mp3",
	MuzzleFlash = "cannon_muzzleflash_noscale",
	IsScalable  = true,
	Mass        = 5630,
	Spread      = 0.08,
	MagSize     = 8,
	Round = {
		MaxLength  = 80,
		PropLength = 65,
	},
	Preview = {
		Height = 60,
		FOV    = 60,
	},
	Caliber	= {
		Base = 100,
		Min  = 75,
		Max  = 170,
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
		Scale = Vector(140, 5, 9),
		Cylinder = true
	},
	LeftDrum = {
		Pos   = Vector(-57, 16, 3),
		Scale = Vector(40, 16, 16),
		Cylinder = true
		-- Critical = true
	},
	RightDrum = {
		Pos   = Vector(-57, -16, 3),
		Scale = Vector(40, 16, 16),
		Cylinder = true
		-- Critical = true
	}
})
