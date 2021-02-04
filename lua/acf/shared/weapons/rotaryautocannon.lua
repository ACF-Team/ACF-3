ACF.RegisterWeaponClass("RAC", {
	Name        = "Rotary Autocannon",
	Description = "Rotary Autocannons sacrifice weight, bulk and accuracy over classic autocannons to get the highest rate of fire possible.",
	Model       = "models/rotarycannon/kw/20mmrac.mdl",
	Sound       = "acf_base/weapons/mg_fire3.mp3",
	MuzzleFlash = "mg_muzzleflash_noscale",
	IsScalable  = true,
	Spread      = 0.48,
	Mass        = 760,
	Caliber	= {
		Base = 20,
		Min  = 7.62,
		Max  = 37,
	},
	MagSize = {
		Min = 400,
		Max = 100,
	},
	MagReload = {
		Min = 8,
		Max = 20,
	},
	Cyclic = {
		Min = 2500,
		Max = 1500,
	},
	Round = {
		MaxLength = 30,
		PropMass  = 0.12,
	},
})

ACF.RegisterWeapon("14.5mmRAC", "RAC", {
	Name		= "14.5mm Rotary Autocannon",
	Description	= "A lightweight rotary autocannon, used primarily against infantry and light vehicles.",
	Model		= "models/rotarycannon/kw/14_5mmrac.mdl",
	Caliber		= 14.5,
	Mass		= 400,
	Year		= 1962,
	MagSize		= 250,
	MagReload	= 10,
	Cyclic		= 2250,
	Round = {
		MaxLength = 25,
		PropMass  = 0.06,
	}
})

ACF.RegisterWeapon("20mmRAC", "RAC", {
	Name		= "20mm Rotary Autocannon",
	Description	= "The 20mm is able to chew up light armor with decent penetration or put up a big flak screen. Typically mounted on ground attack aircraft, SPAAGs and the ocassional APC. Suffers from a moderate cooldown period between bursts to avoid overheating the barrels.",
	Model		= "models/rotarycannon/kw/20mmrac.mdl",
	Caliber		= 20,
	Mass		= 760,
	Year		= 1965,
	MagSize		= 200,
	MagReload	= 15,
	Cyclic		= 2000,
	Round = {
		MaxLength = 30,
		PropMass  = 0.12,
	}
})

ACF.RegisterWeapon("30mmRAC", "RAC", {
	Name		= "30mm Rotary Autocannon",
	Description	= "The 30mm is the bane of ground-attack aircraft, able to tear up light armor without giving one single fuck. Also seen in the skies above dead T-72s. Has a moderate cooldown period between bursts to avoid overheating the barrels.",
	Model		= "models/rotarycannon/kw/30mmrac.mdl",
	Caliber		= 30,
	Mass		= 1500,
	Year		= 1975,
	MagSize		= 100,
	MagReload	= 20,
	Cyclic		= 1500,
	Round = {
		MaxLength = 40,
		PropMass  = 0.350,
	}
})

ACF.RegisterWeapon("20mmHRAC", "RAC", {
	Caliber = 20,
})

ACF.RegisterWeapon("30mmHRAC", "RAC", {
	Caliber = 30,
})

ACF.SetCustomAttachment("models/rotarycannon/kw/14_5mmrac.mdl", "muzzle", Vector(43.21, 0, 1.26))
ACF.SetCustomAttachment("models/rotarycannon/kw/20mmrac.mdl", "muzzle", Vector(59.6, 0, 1.74))
ACF.SetCustomAttachment("models/rotarycannon/kw/30mmrac.mdl", "muzzle", Vector(89.4, 0, 2.61))
