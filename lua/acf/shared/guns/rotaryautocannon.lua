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

ACF_defineGun("20mmRAC", {
	name = "20mm Rotary Autocannon",
	desc = "The 20mm is able to chew up light armor with decent penetration or put up a big flak screen. Typically mounted on ground attack aircraft, SPAAGs and the ocassional APC. Suffers from a moderate cooldown period between bursts to avoid overheating the barrels.",
	model = "models/rotarycannon/kw/20mmrac.mdl",
	gunclass = "RAC",
	caliber = 2.0,
	weight = 760,
	year = 1965,
	magsize = 40,
	magreload = 7,
	rofmod = 2.1,
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
	magsize = 40,
	magreload = 8,
	rofmod = 1,
	round = {
		maxlength = 40,
		propweight = 0.350
	}
} )


ACF_defineGun("20mmHRAC", {
	name = "20mm Heavy Rotary Autocannon",
	desc = "A reinforced, heavy-duty 20mm rotary autocannon, able to fire heavier rounds with a larger magazine.  Phalanx.",
	model = "models/rotarycannon/kw/20mmrac.mdl",
	gunclass = "RAC",
	caliber = 2.0,
	weight = 1200,
	year = 1981,
	magsize = 60,
	magreload = 4,
	rofmod = 2.5,
	round = {
		maxlength = 36,
		propweight = 0.12
	}
} )

ACF_defineGun("30mmHRAC", {
	name = "30mm Heavy Rotary Autocannon",
	desc = "A reinforced, heavy duty 30mm rotary autocannon, able to fire heavier rounds with a larger magazine.  Keeper of goals.",
	model = "models/rotarycannon/kw/30mmrac.mdl",
	gunclass = "RAC",
	caliber = 3.0,
	weight = 2850,
	year = 1985,
	magsize = 50,
	magreload = 6,
	rofmod = 1.2,
	round = {
		maxlength = 45,
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

ACF.RegisterWeapon("14.5mmRAC", "RAC", {
	Name		= "14.5mm Rotary Autocannon",
	Description	= "A lightweight rotary autocannon, used primarily against infantry and light vehicles. It has a lower firerate than its larger brethren, but a significantly quicker cooldown period as well.",
	Model		= "models/rotarycannon/kw/14_5mmrac.mdl",
	Caliber		= 14.5,
	Mass		= 240,
	Year		= 1962,
	ROFMod		= 5.4,
	MagSize		= 60,
	MagReload	= 6,
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
	MagReload	= 8,
	Round = {
		MaxLength = 40,
		PropMass  = 0.350,
	}
})

ACF.RegisterWeapon("20mmHRAC", "RAC", {
	Name		= "20mm Heavy Rotary Autocannon",
	Description	= "A reinforced, heavy-duty 20mm rotary autocannon, able to fire heavier rounds with a larger magazine. Phalanx.",
	Model		= "models/rotarycannon/kw/20mmrac.mdl",
	Caliber		= 20,
	Mass		= 1200,
	Year		= 1981,
	ROFMod		= 2.5,
	MagSize		= 60,
	MagReload	= 4,
	Round = {
		MaxLength = 36,
		PropMass  = 0.12,
	}
})

ACF.RegisterWeapon("30mmHRAC", "RAC", {
	Name		= "30mm Heavy Rotary Autocannon",
	Description	= "A reinforced, heavy duty 30mm rotary autocannon, able to fire heavier rounds with a larger magazine. Keeper of goals.",
	Model		= "models/rotarycannon/kw/30mmrac.mdl",
	Caliber		= 30,
	Mass		= 2850,
	Year		= 1985,
	ROFMod		= 1.2,
	MagSize		= 50,
	MagReload	= 6,
	Round = {
		MaxLength = 45,
		PropMass  = 0.350,
	}
})