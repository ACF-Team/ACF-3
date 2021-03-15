ACF.RegisterWeaponClass("HW", {
	Name        = "Howitzer",
	Description = "Howitzers are limited to rather mediocre muzzle velocities, but can fire extremely heavy projectiles with large useful payload capacities.",
	Sound       = "acf_base/weapons/howitzer_new2.mp3",
	Model       = "models/howitzer/howitzer_105mm.mdl",
	MuzzleFlash = "howie_muzzleflash_noscale",
	IsScalable  = true,
	Mass        = 2315, -- Approx 2 tons @ 100mm
	Spread      = 0.1,
	Round = {
		MaxLength  = 105,
		PropLength = 40.5,
	},
	Preview = {
		FOV = 65,
	},
	Caliber	= {
		Base = 105,
		Min  = 75,
		Max  = 203,
	},
})

ACF.RegisterWeapon("75mmHW", "HW", {
	Caliber = 75,
})

ACF.RegisterWeapon("105mmHW", "HW", {
	Caliber = 105,
})

ACF.RegisterWeapon("122mmHW", "HW", {
	Caliber = 122,
})

ACF.RegisterWeapon("155mmHW", "HW", {
	Caliber = 155,
})

ACF.RegisterWeapon("203mmHW", "HW", {
	Caliber = 203,
})

ACF.SetCustomAttachment("models/howitzer/howitzer_105mm.mdl", "muzzle", Vector(101.08, 0, -1.08))

ACF.AddHitboxes("models/howitzer/howitzer_105mm.mdl", {
	Breech = {
		Pos       = Vector(-8, 0, -0.8),
		Scale     = Vector(47, 11.25, 9.5),
		Sensitive = true
	},
	Barrel = {
		Pos   = Vector(58.5, 0, -0.7),
		Scale = Vector(86, 6, 6)
	}
})
