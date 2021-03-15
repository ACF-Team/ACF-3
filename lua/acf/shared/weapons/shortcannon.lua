ACF.RegisterWeaponClass("SC", {
	Name        = "Short-Barrelled Cannon",
	Description = "Short cannons trade muzzle velocity and accuracy for lighter weight and smaller size, with more penetration than howitzers and lighter than cannons.",
	Model       = "models/tankgun/tankgun_short_100mm.mdl",
	Sound       = "acf_base/weapons/cannon_new.mp3",
	MuzzleFlash = "cannon_muzzleflash_noscale",
	IsScalable  = true,
	Spread      = 0.16,
	Mass        = 1750,
	Round = {
		MaxLength  = 95,
		PropLength = 45,
	},
	Preview = {
		Height = 70,
		FOV    = 60,
	},
	Caliber	= {
		Base = 100,
		Min  = 20,
		Max  = 140,
	},
	Sounds = {
		[50] = "acf_base/weapons/ac_fire4.mp3",
	},
})

ACF.RegisterWeapon("37mmSC", "SC", {
	Caliber = 37,
})

ACF.RegisterWeapon("50mmSC", "SC", {
	Caliber = 50,
})

ACF.RegisterWeapon("75mmSC", "SC", {
	Caliber = 75,
})

ACF.RegisterWeapon("100mmSC", "SC", {
	Caliber = 100,
})

ACF.RegisterWeapon("120mmSC", "SC", {
	Caliber = 120,
})

ACF.RegisterWeapon("140mmSC", "SC", {
	Caliber = 140,
})

ACF.SetCustomAttachment("models/tankgun/tankgun_short_100mm.mdl", "muzzle", Vector(82.86, -0.01), Angle(0, 0, 90))

ACF.AddHitboxes("models/tankgun/tankgun_short_100mm.mdl", {
	Breech = {
		Pos       = Vector(-14.19),
		Scale     = Vector(28.37, 12.83, 12.83),
		Sensitive = true
	},
	Barrel = {
		Pos   = Vector(41.21),
		Scale = Vector(82.41, 6.76, 6.76)
	}
})
