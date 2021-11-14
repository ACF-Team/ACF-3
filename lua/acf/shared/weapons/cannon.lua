ACF.RegisterWeaponClass("C", {
	Name        = "Cannon",
	Description = "Manually loaded weaponry, allows you fire all kinds of rounds at high velocity.",
	Model       = "models/tankgun_new/tankgun_100mm.mdl",
	Sound       = "acf_base/weapons/cannon_new.mp3",
	MuzzleFlash = "cannon_muzzleflash_noscale",
	IsScalable  = true,
	Mass        = 2031,
	Spread      = 0.08,
	Round = {
		MaxLength  = 80,
		PropLength = 65,
	},
	Preview = {
		Height = 50,
		FOV    = 60,
	},
	Caliber	= {
		Base = 100,
		Min  = 20,
		Max  = 170,
	},
	Sounds = {
		[50] = "acf_base/weapons/ac_fire4.mp3",
	},
})

ACF.RegisterWeapon("37mmC", "C", {
	Caliber = 37,
})

ACF.RegisterWeapon("50mmC", "C", {
	Caliber = 50,
})

ACF.RegisterWeapon("75mmC", "C", {
	Caliber = 75,
})

ACF.RegisterWeapon("100mmC", "C", {
	Caliber = 100,
})

ACF.RegisterWeapon("120mmC", "C", {
	Caliber = 120,
})

ACF.RegisterWeapon("140mmC", "C", {
	Caliber = 140,
})

ACF.SetCustomAttachment("models/tankgun_new/tankgun_100mm.mdl", "muzzle", Vector(150.72, -0.01), Angle(0, 0, 90))

ACF.AddHitboxes("models/tankgun_new/tankgun_100mm.mdl", {
	Breech = {
		Pos       = Vector(-14.25),
		Scale     = Vector(28.5, 12.5, 12.5),
		Sensitive = true
	},
	Barrel = {
		Pos   = Vector(75),
		Scale = Vector(150, 5, 5)
	}
})
