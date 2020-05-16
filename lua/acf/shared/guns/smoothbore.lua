--define the class
ACF_defineGunClass("SB", {
	spread = 0.08,
	name = "Smoothbore Cannon",
	desc = "More modern smoothbore cannons that can only fire munitions that do not rely on spinning for accuracy.",
	muzzleflash = "cannon_muzzleflash_noscale",
	rofmod = 1.72,
	sound = "acf_base/weapons/cannon_new.mp3",
	soundDistance = "Cannon.Fire",
	soundNormal = " "
} )

--add a gun to the class


ACF_defineGun("105mmSB", {
	name = "105mm Smoothbore Cannon",
	desc = "The 105mm was a benchmark for the early cold war period, and has great muzzle velocity and hitting power, while still boasting a respectable, if small, payload.",
	model = "models/tankgun_old/tankgun_100mm.mdl",
	gunclass = "SB",
	caliber = 10.5,
	weight = 3550,
	year = 1970,
	round = {
		maxlength = 101,
		propweight = 9
	}
} )

ACF_defineGun("120mmSB", {
	name = "120mm Smoothbore Cannon",
	desc = "Often found in MBTs, the 120mm shreds lighter armor with utter impunity, and is formidable against even the big boys.",
	model = "models/tankgun_old/tankgun_120mm.mdl",
	gunclass = "SB",
	caliber = 12.0,
	weight = 6000,
	year = 1975,
	round = {
		maxlength = 123,
		propweight = 18
	}
} )

ACF_defineGun("140mmSB", {
	name = "140mm Smoothbore Cannonn",
	desc = "The 140mm fires a massive shell with enormous penetrative capability, but has a glacial reload speed and a very hefty weight.",
	model = "models/tankgun_old/tankgun_140mm.mdl",
	gunclass = "SB",
	caliber = 14.0,
	weight = 8980,
	year = 1990,
	round = {
		maxlength = 145,
		propweight = 28
	}
} )

--[[
ACF_defineGun("170mmC", {
	name = "170mm Cannon",
	desc = "The 170mm fires a gigantic shell with ginormous penetrative capability, but has a glacial reload speed and an extremely hefty weight.",
	model = "models/tankgun/tankgun_170mm.mdl",
	gunclass = "C",
	caliber = 17.0,
	weight = 12350,
	year = 1990,
	round = {
		maxlength = 154,
		propweight = 34
	}
} )
]]--

ACF.RegisterWeaponClass("SB", {
	Name		  = "Smoothbore Cannon",
	Description	  = "More modern smoothbore cannons that can only fire munitions that do not rely on spinning for accuracy.",
	MuzzleFlash	  = "cannon_muzzleflash_noscale",
	Spread		  = 0.08,
	Sound		  = "weapons/ACF_Gun/cannon_new.mp3",
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
