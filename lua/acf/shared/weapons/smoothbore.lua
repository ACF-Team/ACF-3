ACF.RegisterWeaponClass("SB", {
	Name		  = "Smoothbore Cannon",
	Description	  = "More modern smoothbore cannons that can only fire munitions that do not rely on spinning for accuracy.",
	MuzzleFlash	  = "cannon_muzzleflash_noscale",
	Spread		  = 0.08,
	Sound		  = "acf_base/weapons/cannon_new.mp3",
	Caliber	= {
		Min = 20,
		Max = 140,
	},
})

ACF.RegisterWeapon("105mmSB", "SB", {
	Name		= "105mm Smoothbore Cannon",
	Description	= "The 105mm was a benchmark for the early cold war period, and has great muzzle velocity and hitting power, while still boasting a respectable, if small, payload.",
	Model		= "models/tankgun_old/tankgun_100mm.mdl",
	Caliber		= 105,
	Mass		= 3550,
	Year		= 1970,
	Round = {
		MaxLength = 101,
		PropMass  = 9,
	}
})

ACF.RegisterWeapon("120mmSB", "SB", {
	Name		= "120mm Smoothbore Cannon",
	Description	= "Often found in MBTs, the 120mm shreds lighter armor with utter impunity, and is formidable against even the big boys.",
	Model		= "models/tankgun_old/tankgun_120mm.mdl",
	Caliber		= 120,
	Mass		= 6000,
	Year		= 1975,
	Round = {
		MaxLength = 145,
		PropMass  = 18,
	}
})

ACF.RegisterWeapon("140mmSB", "SB", {
	Name		= "140mm Smoothbore Cannon",
	Description	= "The 140mm fires a massive shell with enormous penetrative capability, but has a glacial reload speed and a very hefty weight.",
	Model		= "models/tankgun_old/tankgun_140mm.mdl",
	Caliber		= 140,
	Mass		= 8980,
	Year		= 1990,
	Round = {
		MaxLength = 145,
		PropMass  = 28,
	}
})

ACF.SetCustomAttachment("models/tankgun_old/tankgun_100mm.mdl", "muzzle", Vector(135), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/tankgun_old/tankgun_120mm.mdl", "muzzle", Vector(162), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/tankgun_old/tankgun_140mm.mdl", "muzzle", Vector(189), Angle(0, 0, 90))
