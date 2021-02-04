ACF.RegisterWeaponClass("AL", {
	Name        = "Autoloader",
	Description = "A cannon with attached autoloading mechanism. While it allows for several quick shots, the mechanism adds considerable bulk, weight, and magazine reload time.",
	Model       = "models/tankgun/tankgun_al_100mm.mdl",
	Sound       = "acf_base/weapons/autoloader.mp3",
	MuzzleFlash = "cannon_muzzleflash_noscale",
	IsScalable  = true,
	Mass        = 3325,
	Spread      = 0.08,
	Caliber	= {
		Base = 100,
		Min  = 75,
		Max  = 140,
	},
	MagSize = {
		Min = 8,
		Max = 5,
	},
	MagReload = {
		Min = 15,
		Max = 35,
	},
	Cyclic = {
		Min = 30,
		Max = 8,
	},
	Round = {
		MaxLength = 93,
		PropMass  = 9.5,
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

ACF.SetCustomAttachment("models/tankgun/tankgun_al_75mm.mdl", "muzzle", Vector(109.65), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/tankgun/tankgun_al_100mm.mdl", "muzzle", Vector(146.2), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/tankgun/tankgun_al_120mm.mdl", "muzzle", Vector(175.44), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/tankgun/tankgun_al_140mm.mdl", "muzzle", Vector(204.68), Angle(0, 0, 90))
