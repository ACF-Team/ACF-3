--define the class
ACF_defineGunClass("MG", {
	spread = 0.24,
	name = "Machinegun",
	desc = "Machineguns are light guns that fire equally light bullets at a fast rate.",
	muzzleflash = "mg_muzzleflash_noscale",
	rofmod = 0.9,
	sound = "weapons/ACF_Gun/mg_fire4.mp3",
	soundNormal = "weapons/ACF_Gun/mg_fire4.mp3",
	soundDistance = ""
})

--add a gun to the class
--id
ACF_defineGun("7.62mmMG", {
	name = "7.62mm Machinegun",
	desc = "The 7.62mm is effective against infantry, but its usefulness against armor is laughable at best.",
	model = "models/machinegun/machinegun_762mm.mdl",
	gunclass = "MG",
	canparent = true,
	caliber = 0.762,
	weight = 15,
	year = 1930,
	rofmod = 1.59,
	magsize = 250,
	magreload = 6,
	round = {
		maxlength = 13,
		propweight = 0.04
	}
})

ACF_defineGun("12.7mmMG", {
	name = "12.7mm Machinegun",
	desc = "The 12.7mm MG is still light, finding its way into a lot of mountings, including on top of tanks.",
	model = "models/machinegun/machinegun_127mm.mdl",
	gunclass = "MG",
	canparent = true,
	caliber = 1.27,
	weight = 30,
	year = 1910,
	rofmod = 1, --0.766
	magsize = 150,
	magreload = 6,
	round = {
		maxlength = 15.8,
		propweight = 0.03
	}
})

ACF_defineGun("14.5mmMG", {
	name = "14.5mm Machinegun",
	desc = "The 14.5mm MG trades its smaller stablemates' rate of fire for more armor penetration and damage.",
	model = "models/machinegun/machinegun_145mm.mdl",
	gunclass = "MG",
	canparent = true,
	caliber = 1.45,
	weight = 45,
	year = 1932,
	rofmod = 1, --0.722
	magsize = 90,
	magreload = 5,
	round = {
		maxlength = 19.5,
		propweight = 0.04
	}
})
--ACF_defineGun("20mmMG", {
--name = "20mm Machinegun",
--desc = "The 20mm MG is practically a cannon in its own right; the weight and recoil made it difficult to mount on light land vehicles, though it was adapted for use on both aircraft and ships.",
--model = "models/machinegun/machinegun_20mm.mdl",
--gunclass = "MG",
--caliber = 2.0,
--weight = 95,
--year = 1935,
--rofmod = 0.3,
--magsize = 50,
--magreload = 4,
--round = {
--maxlength = 22,
--propweight = 0.09
--}
--} )

ACF.RegisterWeaponClass("MG", {
	Name		  = "Machinegun",
	Description	  = "Machineguns are light guns that fire equally light bullets at a fast rate.",
	MuzzleFlash	  = "mg_muzzleflash_noscale",
	ROFMod		  = 0.9,
	Spread		  = 0.24,
	Sound		  = "weapons/ACF_Gun/mg_fire4.mp3",
	Caliber	= {
		Min = 5.56,
		Max = 14.5,
	},
})

ACF.RegisterWeapon("7.62mmMG", "MG", {
	Name		= "7.62mm Machinegun",
	Description	= "The 7.62mm is effective against infantry, but its usefulness against armor is laughable at best.",
	Model		= "models/machinegun/machinegun_762mm.mdl",
	Caliber		= 7.62,
	Mass		= 15,
	Year		= 1930,
	ROFMod		= 1.59,
	MagSize		= 250,
	MagReload	= 6,
	Round = {
		MaxLength = 13,
		PropMass  = 0.04,
	}
})

ACF.RegisterWeapon("12.7mmMG", "MG", {
	Name		= "12.7mm Machinegun",
	Description	= "The 12.7mm MG is still light, finding its way into a lot of mountings, including on top of tanks.",
	Model		= "models/machinegun/machinegun_127mm.mdl",
	Caliber		= 12.7,
	Mass		= 30,
	Year		= 1910,
	ROFMod		= 1,
	MagSize		= 150,
	MagReload	= 6,
	Round = {
		MaxLength = 15.8,
		PropMass  = 0.03,
	}
})

ACF.RegisterWeapon("14.5mmMG", "MG", {
	Name		= "14.5mm Machinegun",
	Description	= "The 14.5mm MG trades its smaller stablemates' rate of fire for more armor penetration and damage.",
	Model		= "models/machinegun/machinegun_145mm.mdl",
	Caliber		= 14.5,
	Mass		= 45,
	Year		= 1932,
	ROFMod		= 1,
	MagSize		= 90,
	MagReload	= 5,
	Round = {
		MaxLength = 19.5,
		PropMass  = 0.04,
	}
})
