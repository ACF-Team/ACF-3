ACF.RegisterWeaponClass("SC", {
	Name        = "Short-Barrelled Cannon",
	Description = "Short cannons trade muzzle velocity and accuracy for lighter weight and smaller size, with more penetration than howitzers and lighter than cannons.",
	Model       = "models/tankgun/tankgun_short_100mm.mdl",
	Sound       = "acf_base/weapons/cannon_new.mp3",
	MuzzleFlash = "cannon_muzzleflash_noscale",
	IsScalable  = true,
	Spread      = 0.16,
	Mass        = 1750,
	Caliber	= {
		Base = 100,
		Min  = 20,
		Max  = 140,
	},
	Sounds = {
		[50] = "acf_base/weapons/ac_fire4.mp3",
	},
	Round = {
		MaxLength = 93,
		PropMass  = 4.5,
	}
})

ACF.RegisterWeapon("37mmSC", "SC", {
	Name		= "37mm Short Cannon",
	Description	= "Quick-firing and light, but penetration is laughable. You're better off throwing rocks.",
	Model		= "models/tankgun/tankgun_short_37mm.mdl",
	Caliber		= 37,
	Mass		= 200,
	Year		= 1915,
	Sound		= "acf_base/weapons/ac_fire4.mp3",
	Round = {
		MaxLength = 45,
		PropMass  = 0.29,
	}
})

ACF.RegisterWeapon("50mmSC", "SC", {
	Name		= "50mm Short Cannon",
	Description	= "The 50mm is a quick-firing pea-shooter, good for scouts, and common on old interwar tanks.",
	Model		= "models/tankgun/tankgun_short_50mm.mdl",
	Caliber		= 50,
	Mass		= 330,
	Year		= 1915,
	Sound		= "acf_base/weapons/ac_fire4.mp3",
	Round = {
		MaxLength = 63,
		PropMass  = 0.6,
	}
})

ACF.RegisterWeapon("75mmSC", "SC", {
	Name		= "75mm Short Cannon",
	Description	= "The 75mm is common WW2 medium tank armament, and still useful in many other applications.",
	Model		= "models/tankgun/tankgun_short_75mm.mdl",
	Caliber		= 75,
	Mass		= 750,
	Year		= 1936,
	Round = {
		MaxLength = 76,
		PropMass  = 2,
	}
})

ACF.RegisterWeapon("100mmSC", "SC", {
	Name		= "100mm Short Cannon",
	Description	= "The 100mm is an effective infantry-support or antitank weapon, with a lot of uses and surprising lethality.",
	Model		= "models/tankgun/tankgun_short_100mm.mdl",
	Caliber		= 100,
	Mass		= 1750,
	Year		= 1940,
	Round = {
		MaxLength = 93,
		PropMass  = 4.5,
	}
})

ACF.RegisterWeapon("120mmSC", "SC", {
	Name		= "120mm Short Cannon",
	Description	= "The 120mm is a formidable yet lightweight weapon, with excellent performance against larger vehicles.",
	Model		= "models/tankgun/tankgun_short_120mm.mdl",
	Caliber		= 120,
	Mass		= 3800,
	Year		= 1944,
	Round = {
		MaxLength = 110,
		PropMass  = 8.5,
	}
})

ACF.RegisterWeapon("140mmSC", "SC", {
	Name		= "140mm Short Cannon",
	Description	= "A specialized weapon, developed from dark magic and anti-heavy tank hatred. Deal with it.",
	Model		= "models/tankgun/tankgun_short_140mm.mdl",
	Caliber		= 140,
	Mass		= 6040,
	Year		= 1999,
	Round = {
		MaxLength = 127,
		PropMass  = 12.8,
	}
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
