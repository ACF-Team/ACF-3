ACF.RegisterWeaponClass("C", {
	Name		  = "Cannon",
	Description	  = "High velocity guns that can fire very powerful ammunition, but are rather slow to reload.",
	MuzzleFlash	  = "cannon_muzzleflash_noscale",
	Spread		  = 0.08,
	Sound		  = "acf_base/weapons/cannon_new.mp3",
	Caliber	= {
		Min = 20,
		Max = 140,
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
	Description	= "The 75mm is still rather respectable in rate of fire, but has only modest payload.  Often found on the Eastern Front, and on cold war light tanks.",
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

ACF.SetCustomAttachment("models/tankgun/tankgun_37mm.mdl", "muzzle", Vector(55.77), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/tankgun/tankgun_50mm.mdl", "muzzle", Vector(75.36, -0.01, 0), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/tankgun/tankgun_75mm.mdl", "muzzle", Vector(113.04, -0.01, 0), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/tankgun/tankgun_100mm.mdl", "muzzle", Vector(150.72, -0.01, 0), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/tankgun/tankgun_120mm.mdl", "muzzle", Vector(180.85, -0.02, 0), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/tankgun/tankgun_140mm.mdl", "muzzle", Vector(210.99, -0.02, 0), Angle(0, 0, 90))
