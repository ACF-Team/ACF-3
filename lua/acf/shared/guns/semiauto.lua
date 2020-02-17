--define the class
ACF_defineGunClass("SA", {
	spread = 0.1,
	name = "Semiautomatic Cannon",
	desc = "Semiautomatic cannons offer better payloads than autocannons and less weight at the cost of rate of fire.",
	muzzleflash = "semi_muzzleflash_noscale",
	rofmod = 0.36,
	sound = "weapons/acf_gun/sa_fire1.mp3",
	soundDistance = " ",
	soundNormal = " "
})

--add a gun to the class
--id
ACF_defineGun("25mmSA", {
	name = "25mm Semiautomatic Cannon",
	desc = "The 25mm semiauto can quickly put five rounds downrange, being lethal, yet light.",
	model = "models/autocannon/semiautocannon_25mm.mdl",
	gunclass = "SA",
	caliber = 2.5,
	weight = 200,
	year = 1935,
	rofmod = 0.7,
	magsize = 5,
	magreload = 2,
	round = {
		maxlength = 39,
		propweight = 0.5
	}
})

ACF_defineGun("37mmSA", {
	name = "37mm Semiautomatic Cannon",
	desc = "The 37mm is surprisingly powerful, its five-round clips boasting a respectable payload and a high muzzle velocity.",
	model = "models/autocannon/semiautocannon_37mm.mdl",
	gunclass = "SA",
	caliber = 3.7,
	weight = 540,
	year = 1940,
	rofmod = 0.7,
	magsize = 5,
	magreload = 3.5,
	round = {
		maxlength = 42,
		propweight = 1.125
	}
})

ACF_defineGun("45mmSA", {
	name = "45mm Semiautomatic Cannon",
	desc = "The 45mm can easily shred light armor, with a respectable rate of fire, but its armor penetration pales in comparison to regular cannons.",
	model = "models/autocannon/semiautocannon_45mm.mdl",
	gunclass = "SA",
	caliber = 4.5,
	weight = 870,
	year = 1965,
	rofmod = 0.72,
	magsize = 5,
	magreload = 4,
	round = {
		maxlength = 52,
		propweight = 1.8
	}
})

ACF_defineGun("57mmSA", {
	name = "57mm Semiautomatic Cannon",
	desc = "The 57mm is a respectable light armament, offering considerable penetration and moderate fire rate.",
	model = "models/autocannon/semiautocannon_57mm.mdl",
	gunclass = "SA",
	caliber = 5.7,
	weight = 1560,
	year = 1965,
	rofmod = 0.8,
	magsize = 5,
	magreload = 4.5,
	round = {
		maxlength = 62,
		propweight = 2
	}
})

ACF_defineGun("76mmSA", {
	name = "76mm Semiautomatic Cannon",
	desc = "The 76mm semiauto is a fearsome weapon, able to put 5 76mm rounds downrange in 8 seconds.",
	model = "models/autocannon/semiautocannon_76mm.mdl",
	gunclass = "SA",
	caliber = 7.62,
	weight = 2990,
	year = 1984,
	rofmod = 0.85,
	magsize = 5,
	magreload = 5,
	round = {
		maxlength = 70,
		propweight = 4.75
	}
})

ACF.RegisterWeaponClass("SA", {
	Name		  = "Semiautomatic Cannon",
	Description	  = "Semiautomatic cannons offer better payloads than autocannons and less weight at the cost of rate of fire.",
	MuzzleFlash	  = "semi_muzzleflash_noscale",
	ROFMod		  = 0.36,
	Spread		  = 0.1,
	Sound		  = "weapons/acf_gun/sa_fire1.mp3",
	Caliber	= {
		Min = 20,
		Max = 76,
	},
})

ACF.RegisterWeapon("25mmSA", "SA", {
	Name		= "25mm Semiautomatic Cannon",
	Description	= "The 25mm semiauto can quickly put five rounds downrange, being lethal, yet light.",
	Model		= "models/autocannon/semiautocannon_25mm.mdl",
	Caliber		= 25,
	Mass		= 200,
	Year		= 1935,
	ROFMod		= 0.7,
	MagSize		= 5,
	MagReload	= 2,
	Round = {
		MaxLength = 39,
		PropMass  = 0.5,
	}
})

ACF.RegisterWeapon("37mmSA", "SA", {
	Name		= "37mm Semiautomatic Cannon",
	Description	= "The 37mm is surprisingly powerful, its five-round clips boasting a respectable payload and a high muzzle velocity.",
	Model		= "models/autocannon/semiautocannon_37mm.mdl",
	Caliber		= 37,
	Mass		= 540,
	Year		= 1940,
	ROFMod		= 0.7,
	MagSize		= 5,
	MagReload	= 3.5,
	Round = {
		MaxLength = 42,
		PropMass  = 1.125,
	}
})

ACF.RegisterWeapon("45mmSA", "SA", {
	Name		= "45mm Semiautomatic Cannon",
	Description	= "The 45mm can easily shred light armor, with a respectable rate of fire, but its armor penetration pales in comparison to regular cannons.",
	Model		= "models/autocannon/semiautocannon_45mm.mdl",
	Caliber		= 45,
	Mass		= 870,
	Year		= 1965,
	ROFMod		= 0.72,
	MagSize		= 5,
	MagReload	= 4,
	Round = {
		MaxLength = 52,
		PropMass  = 1.8,
	}
})

ACF.RegisterWeapon("57mmSA", "SA", {
	Name		= "57mm Semiautomatic Cannon",
	Description	= "The 57mm is a respectable light armament, offering considerable penetration and moderate fire rate.",
	Model		= "models/autocannon/semiautocannon_57mm.mdl",
	Caliber		= 57,
	Mass		= 1560,
	Year		= 1965,
	ROFMod		= 0.8,
	MagSize		= 5,
	MagReload	= 4.5,
	Round = {
		MaxLength = 62,
		PropMass  = 2,
	}
})

ACF.RegisterWeapon("76mmSA", "SA", {
	Name		= "76mm Semiautomatic Cannon",
	Description	= "The 76mm semiauto is a fearsome weapon, able to put five 76mm rounds downrange in 8 seconds.",
	Model		= "models/autocannon/semiautocannon_76mm.mdl",
	Caliber		= 76.2,
	Mass		= 2990,
	Year		= 1984,
	ROFMod		= 0.85,
	MagSize		= 5,
	MagReload	= 5,
	Round = {
		MaxLength = 70,
		PropMass  = 4.75,
	}
})
