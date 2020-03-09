--define the class
ACF_defineGunClass("RAC", {
	spread = 0.4,
	name = "Rotary Autocannon",
	desc = "Rotary Autocannons sacrifice weight, bulk and accuracy over classic Autocannons to get the highest rate of fire possible.",
	muzzleflash = "mg_muzzleflash_noscale",
	rofmod = 0.07,
	sound = "weapons/acf_gun/mg_fire3.mp3",
	soundDistance = " ",
	soundNormal = " ",
	color = {135, 135, 135}
} )

--[[ What purpose does this serve? These don't even exist.
ACF_defineGun("14.5mmRAC", { --id
	name = "14.5mm Rotary Autocannon",
	desc = "A lightweight rotary autocannon, used primarily against infantry and light vehicles.  It has a lower firerate than its larger brethren, but a significantly quicker cooldown period as well.",
	model = "models/rotarycannon/kw/14_5mmrac.mdl",
	gunclass = "RAC",
	caliber = 1.45,
	weight = 240,
	year = 1962,
	magsize = 60,
	magreload = 6,
	rofmod = 5.4,
	round = {
		maxlength = 25,
		propweight = 0.06
	}
} )
]]--

ACF_defineGun("20mmRAC", {
	name = "20mm Rotary Autocannon",
	desc = "The 20mm is able to chew up light armor with decent penetration or put up a big flak screen. Typically mounted on ground attack aircraft, SPAAGs and the ocassional APC. Suffers from a moderate cooldown period between bursts to avoid overheating the barrels.",
	model = "models/rotarycannon/kw/20mmrac.mdl",
	gunclass = "RAC",
	caliber = 2.0,
	weight = 760,
	year = 1965,
	magsize = 200,
	magreload = 25,
	rofmod = 2.1,
	Cyclic = 4000,
	round = {
		maxlength = 30,
		propweight = 0.12
	}
} )

ACF_defineGun("30mmRAC", {
	name = "30mm Rotary Autocannon",
	desc = "The 30mm is the bane of ground-attack aircraft, able to tear up light armor without giving one single fuck.  Also seen in the skies above dead T-72s.  Has a moderate cooldown period between bursts to avoid overheating the barrels.",
	model = "models/rotarycannon/kw/30mmrac.mdl",
	gunclass = "RAC",
	caliber = 3.0,
	weight = 1500,
	year = 1975,
	magsize = 100,
	magreload = 35,
	rofmod = 1,
	Cyclic = 3000,
	round = {
		maxlength = 40,
		propweight = 0.350
	}
} )

ACF.RegisterWeaponClass("RAC", {
	Name		  = "Rotary Autocannon",
	Description	  = "Rotary Autocannons sacrifice weight, bulk and accuracy over classic autocannons to get the highest rate of fire possible.",
	MuzzleFlash	  = "mg_muzzleflash_noscale",
	ROFMod		  = 0.07,

	Spread		  = 0.4,
	Sound		  = "weapons/acf_gun/mg_fire3.mp3",
	Caliber	= {
		Min = 7.62,
		Max = 30,
	},
})

ACF.RegisterWeapon("20mmRAC", "RAC", {
	Name		= "20mm Rotary Autocannon",
	Description	= "The 20mm is able to chew up light armor with decent penetration or put up a big flak screen. Typically mounted on ground attack aircraft, SPAAGs and the ocassional APC. Suffers from a moderate cooldown period between bursts to avoid overheating the barrels.",
	Model		= "models/rotarycannon/kw/20mmrac.mdl",
	Caliber		= 20,
	Mass		= 760,
	Year		= 1965,
	ROFMod		= 2.1,
	MagSize		= 40,
	MagReload	= 7,
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
	ROFMod		= 1,
	MagSize		= 40,
	Round = {
	MagReload	= 8,
		MaxLength = 40,
		PropMass  = 0.350,
	}

})