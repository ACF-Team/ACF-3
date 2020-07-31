--define the class
ACF_defineGunClass("RAC", {
	spread = 0.48,
	name = "Rotary Autocannon",
	desc = "Rotary Autocannons sacrifice weight, bulk and accuracy over classic Autocannons to get the highest rate of fire possible.",
	muzzleflash = "mg_muzzleflash_noscale",
	rofmod = 0.07,
	sound = "acf_base/weapons/mg_fire3.mp3",
	soundDistance = " ",
	soundNormal = " ",
	color = {135, 135, 135}
} )

ACF_defineGun("14.5mmRAC", { --id
	name = "14.5mm Rotary Autocannon",
	desc = "A lightweight rotary autocannon, used primarily against infantry and light vehicles.",
	model = "models/rotarycannon/kw/14_5mmrac.mdl",
	gunclass = "RAC",
	caliber = 1.45,
	weight = 400,
	year = 1962,
	magsize = 250,
	magreload = 15,
	rofmod = 5.4,
	Cyclic = 2250,
	round = {
		maxlength = 25,
		propweight = 0.06
	}
} )

ACF_defineGun("20mmRAC", {
	name = "20mm Rotary Autocannon",
	desc = "The 20mm is able to chew up light armor with decent penetration or put up a big flak screen.",
	model = "models/rotarycannon/kw/20mmrac.mdl",
	gunclass = "RAC",
	caliber = 2.0,
	weight = 760,
	year = 1965,
	magsize = 200,
	magreload = 20,
	rofmod = 2.1,
	Cyclic = 2000,
	round = {
		maxlength = 30,
		propweight = 0.12
	}
} )

ACF_defineGun("30mmRAC", {
	name = "30mm Rotary Autocannon",
	desc = "The 30mm is the bane of ground-attack aircraft, able to tear up light armor without giving one single fuck. Also seen in the skies above dead T-72s.",
	model = "models/rotarycannon/kw/30mmrac.mdl",
	gunclass = "RAC",
	caliber = 3.0,
	weight = 1500,
	year = 1975,
	magsize = 100,
	magreload = 30,
	rofmod = 1,
	Cyclic = 1500,
	round = {
		maxlength = 40,
		propweight = 0.350
	}
} )