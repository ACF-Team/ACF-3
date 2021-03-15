ACF.RegisterWeaponClass("C", {
	Name        = "Cannon",
	Description = "High velocity guns that can fire very powerful ammunition, but are rather slow to reload.",
	Model       = "models/tankgun/tankgun_100mm.mdl",
	Sound       = "acf_base/weapons/cannon_new.mp3",
	MuzzleFlash = "cannon_muzzleflash_noscale",
	IsScalable  = true,
	Mass        = 2500,
	Spread      = 0.08,
	Round = {
		MaxLength  = 95,
		PropLength = 70,
	},
	Preview = {
		Height = 50,
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

ACF.RegisterWeapon("37mmC", "C", {
	Name		= "37mm Cannon",
	Description	= "A light and fairly weak cannon with good accuracy.",
	Model		= "models/tankgun/tankgun_37mm.mdl",
	Caliber		= 37,
	Mass		= 350,
	Year		= 1919,
	Sound		= "acf_base/weapons/ac_fire4.mp3",
	Round = {
		MaxLength = 48,
		PropMass  = 1.125,
	}
})

ACF.RegisterWeapon("50mmC", "C", {
	Name		= "50mm Cannon",
	Description	= "The 50mm is surprisingly fast-firing, with good effectiveness against light armor, but a pea-shooter compared to its bigger cousins",
	Model		= "models/tankgun/tankgun_50mm.mdl",
	Caliber		= 50,
	Mass		= 665,
	Year		= 1935,
	Sound		= "acf_base/weapons/ac_fire4.mp3",
	Round = {
		MaxLength = 63,
		PropMass  = 2.1,
	}
})

ACF.RegisterWeapon("75mmC", "C", {
	Name		= "75mm Cannon",
	Description	= "The 75mm is still rather respectable in rate of fire, but has only modest payload. Often found on the Eastern Front, and on cold war light tanks.",
	Model		= "models/tankgun/tankgun_75mm.mdl",
	Caliber		= 75,
	Mass		= 1420,
	Year		= 1942,
	Round = {
		MaxLength = 78,
		PropMass  = 3.8,
	}
})

ACF.RegisterWeapon("100mmC", "C", {
	Name		= "100mm Cannon",
	Description	= "The 100mm was a benchmark for the early cold war period, and has great muzzle velocity and hitting power, while still boasting a respectable, if small, payload.",
	Model		= "models/tankgun/tankgun_100mm.mdl",
	Caliber		= 100,
	Mass		= 2750,
	Year		= 1944,
	Round = {
		MaxLength = 93,
		PropMass  = 9.5,
	}
})

ACF.RegisterWeapon("120mmC", "C", {
	Name		= "120mm Cannon",
	Description	= "Often found in MBTs, the 120mm shreds lighter armor with utter impunity, and is formidable against even the big boys.",
	Model		= "models/tankgun/tankgun_120mm.mdl",
	Caliber		= 120,
	Mass		= 5200,
	Year		= 1955,
	Round = {
		MaxLength = 110,
		PropMass  = 18,
	}
})

ACF.RegisterWeapon("140mmC", "C", {
	Name		= "140mm Cannon",
	Description	= "The 140mm fires a massive shell with enormous penetrative capability, but has a glacial reload speed and a very hefty weight.",
	Model		= "models/tankgun/tankgun_140mm.mdl",
	Caliber		= 140,
	Mass		= 8180,
	Year		= 1990,
	Round = {
		MaxLength = 127,
		PropMass  = 28,
	}
})

ACF.SetCustomAttachment("models/tankgun/tankgun_100mm.mdl", "muzzle", Vector(150.72, -0.01), Angle(0, 0, 90))

ACF.AddHitboxes("models/tankgun/tankgun_100mm.mdl", {
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
