-- DELETE
ACF_defineGunClass("AL", {
	spread = 0.08,
	name = "Autoloader",
	desc = "A cannon with attached autoloading mechanism.  While it allows for several quick shots, the mechanism adds considerable bulk, weight, and magazine reload time.",
	muzzleflash = "cannon_muzzleflash_noscale",
	rofmod = 0.64,
	sound = "acf_base/weapons/autoloader.mp3",
	soundDistance = "Cannon.Fire",
	soundNormal = " "
})

-- DELETE
ACF_defineGun("75mmAL", {
	name = "75mm Autoloading Cannon",
	desc = "A quick-firing 75mm gun, pops off a number of rounds in relatively short order.",
	model = "models/tankgun/tankgun_al_75mm.mdl",
	gunclass = "AL",
	caliber = 7.5,
	weight = 1892,
	year = 1946,
	rofmod = 1,
	magsize = 8,
	magreload = 15,
	Cyclic = 30,
	round = {
		maxlength = 78,
		propweight = 3.8
	}
})

-- DELETE
ACF_defineGun("100mmAL", {
	name = "100mm Autoloading Cannon",
	desc = "The 100mm is good for rapidly hitting medium armor, then running like your ass is on fire to reload.",
	model = "models/tankgun/tankgun_al_100mm.mdl",
	gunclass = "AL",
	caliber = 10.0,
	weight = 3325,
	year = 1956,
	rofmod = 0.85,
	magsize = 6,
	magreload = 21,
	Cyclic = 18,
	round = {
		maxlength = 93,
		propweight = 9.5
	}
})

-- DELETE
ACF_defineGun("120mmAL", {
	name = "120mm Autoloading Cannon",
	desc = "The 120mm autoloader can do serious damage before reloading, but the reload time is killer.",
	model = "models/tankgun/tankgun_al_120mm.mdl",
	gunclass = "AL",
	caliber = 12.0,
	weight = 6050,
	year = 1956,
	rofmod = 0.757,
	magsize = 5,
	magreload = 27,
	Cyclic = 11,
	round = {
		maxlength = 110,
		propweight = 18
	}
})

-- DELETE
ACF_defineGun("140mmAL", {
	name = "140mm Autoloading Cannon",
	desc = "The 140mm can shred a medium tank's armor with one magazine, and even function as shoot & scoot artillery, with its useful HE payload.",
	model = "models/tankgun/tankgun_al_140mm.mdl",
	gunclass = "AL",
	caliber = 14.0,
	weight = 8830,
	year = 1970,
	rofmod = 0.743,
	magsize = 5,
	magreload = 35,
	Cyclic = 8,
	round = {
		maxlength = 127,
		propweight = 28
	}
})
--[[
ACF_defineGun("170mmAL", {
	name = "170mm Autoloading Cannon",
	desc = "The 170mm can shred an average 40ton tank's armor with one magazine.",
	model = "models/tankgun/tankgun_al_170mm.mdl",
	gunclass = "AL",
	caliber = 17.0,
	weight = 13350,
	year = 1970,
	rofmod = 0.8,
	magsize = 4,
	magreload = 40,
	round = {
		maxlength = 154,
		propweight = 34
	}
} )
]]
--

ACF.RegisterWeaponClass("AL", {
	Name		  = "Autoloader",
	Description	  = "A cannon with attached autoloading mechanism. While it allows for several quick shots, the mechanism adds considerable bulk, weight, and magazine reload time.",
	MuzzleFlash	  = "cannon_muzzleflash_noscale",
	Spread		  = 0.08,
	Sound		  = "acf_base/weapons/autoloader.mp3",
	Caliber	= {
		Min = 75,
		Max = 140,
	},
})

ACF.RegisterWeapon("75mmAL", "AL", {
	Name		= "75mm Autoloading Cannon",
	Description	= "A quick-firing 75mm gun, pops off a number of rounds in relatively short order.",
	Model		= "models/tankgun/tankgun_al_75mm.mdl",
	Caliber		= 75,
	Mass		= 1892,
	Year		= 1946,
	MagSize		= 8,
	MagReload	= 15,
	Cyclic		= 30,
	Round = {
		MaxLength = 78,
		PropMass  = 3.8,
	}
})

ACF.RegisterWeapon("100mmAL", "AL", {
	Name		= "100mm Autoloading Cannon",
	Description	= "The 100mm is good for rapidly hitting medium armor, then running like your ass is on fire to reload.",
	Model		= "models/tankgun/tankgun_al_100mm.mdl",
	Caliber		= 100,
	Mass		= 3325,
	Year		= 1956,
	MagSize		= 6,
	MagReload	= 21,
	Cyclic		= 18,
	Round = {
		MaxLength = 93,
		PropMass  = 9.5,
	}
})

ACF.RegisterWeapon("120mmAL", "AL", {
	Name		= "120mm Autoloading Cannon",
	Description	= "The 120mm autoloader can do serious damage before reloading, but the reload time is killer.",
	Model		= "models/tankgun/tankgun_al_120mm.mdl",
	Caliber		= 120,
	Mass		= 6050,
	Year		= 1956,
	MagSize		= 5,
	MagReload	= 27,
	Cyclic		= 11,
	Round = {
		MaxLength = 110,
		PropMass  = 18,
	}
})

ACF.RegisterWeapon("140mmAL", "AL", {
	Name		= "140mm Autoloading Cannon",
	Description	= "The 140mm can shred a medium tank's armor with one magazine, and even function as shoot & scoot artillery, with its useful HE payload.",
	Model		= "models/tankgun/tankgun_al_140mm.mdl",
	Caliber		= 140,
	Mass		= 8830,
	Year		= 1970,
	MagSize		= 5,
	MagReload	= 35,
	Cyclic		= 8,
	Round = {
		MaxLength = 127,
		PropMass  = 28,
	}
})
