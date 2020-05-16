--define the class
ACF_defineGunClass("HMG", {
	spread = 1.3,
	name = "Heavy Machinegun",
	desc = "Designed as autocannons for aircraft, HMGs are rapid firing, lightweight, and compact but sacrifice accuracy, magazine size, and reload times.  They excel at strafing and dogfighting.\nBecause of their long reload times and high rate of fire, it is best to aim BEFORE pushing the almighty fire switch.",
	muzzleflash = "mg_muzzleflash_noscale",
	rofmod = 0.14,
	sound = "acf_base/weapons/mg_fire3.mp3",
	soundDistance = " ",
	soundNormal = " ",
	longbarrel = {
		index = 2,
		submodel = 4,
		newpos = "muzzle2"
	}
})

--add a gun to the class
ACF_defineGun("13mmHMG", {
	name = "13mm Heavy Machinegun",
	desc = "The lightest of the HMGs, the 13mm has a rapid fire rate but suffers from poor payload size.  Often used to strafe ground troops or annoy low-flying aircraft.",
	model = "models/machinegun/machinegun_20mm.mdl",
	gunclass = "HMG",
	caliber = 1.3,
	weight = 90,
	year = 1935,
	rofmod = 3.3,
	magsize = 35,
	magreload = 6,
	Cyclic = 550,
	round = {
		maxlength = 22,
		propweight = 0.09
	}
})

ACF_defineGun("20mmHMG", {
	name = "20mm Heavy Machinegun",
	desc = "The 20mm has a rapid fire rate but suffers from poor payload size.  Often used to strafe ground troops or annoy low-flying aircraft.",
	model = "models/machinegun/machinegun_20mm_compact.mdl",
	gunclass = "HMG",
	caliber = 2.0,
	weight = 160,
	year = 1935,
	rofmod = 1.9, --at 1.5, 675rpm; at 2.0, 480rpm
	magsize = 30,
	magreload = 6,
	Cyclic = 525,
	round = {
		maxlength = 30,
		propweight = 0.12
	}
})

ACF_defineGun("30mmHMG", {
	name = "30mm Heavy Machinegun",
	desc = "30mm shell chucker, light and compact. Your average cold war dogfight go-to.",
	model = "models/machinegun/machinegun_30mm_compact.mdl",
	gunclass = "HMG",
	caliber = 3.0,
	weight = 480,
	year = 1941,
	rofmod = 1.1, --at 1.05, 495rpm; 
	magsize = 25,
	magreload = 6,
	Cyclic = 500,
	round = {
		maxlength = 37,
		propweight = 0.35
	}
})

ACF_defineGun("40mmHMG", {
	name = "40mm Heavy Machinegun",
	desc = "The heaviest of the heavy machineguns.  Massively powerful with a killer reload and hefty ammunition requirements, it can pop even relatively heavy targets with ease.",
	model = "models/machinegun/machinegun_40mm_compact.mdl",
	gunclass = "HMG",
	caliber = 4.0,
	weight = 780,
	year = 1955,
	rofmod = 0.95, --at 0.75, 455rpm
	magsize = 20,
	magreload = 8,
	Cyclic = 475,
	round = {
		maxlength = 42,
		propweight = 0.9
	}
})

ACF.RegisterWeaponClass("HMG", {
	Name		  = "Heavy Machinegun",
	Description	  = "Designed as autocannons for aircraft, HMGs are rapid firing, lightweight, and compact but sacrifice accuracy, magazine size, and reload times.",
	MuzzleFlash	  = "mg_muzzleflash_noscale",
	Spread		  = 1.3,
	Sound		  = "weapons/ACF_Gun/mg_fire3.mp3",
	Caliber	= {
		Min = 13,
		Max = 40,
	},
	LongBarrel = {
		Index	 = 2,
		Submodel = 4,
		NewPos	 = "muzzle2",
	}
})

ACF.RegisterWeapon("13mmHMG", "HMG", {
	Name		= "13mm Heavy Machinegun",
	Description	= "The lightest of the HMGs, the 13mm has a rapid fire rate but suffers from poor payload size. Often used to strafe ground troops or annoy low-flying aircraft.",
	Model		= "models/machinegun/machinegun_20mm.mdl",
	Caliber		= 13,
	Mass		= 90,
	Year		= 1935,
	MagSize		= 35,
	MagReload	= 6,
	Cyclic		= 550,
	Round = {
		MaxLength = 22,
		PropMass  = 0.09,
	}
})

ACF.RegisterWeapon("20mmHMG", "HMG", {
	Name		= "20mm Heavy Machinegun",
	Description	= "The 20mm has a rapid fire rate but suffers from poor payload size. Often used to strafe ground troops or annoy low-flying aircraft.",
	Model		= "models/machinegun/machinegun_20mm_compact.mdl",
	Caliber		= 20,
	Mass		= 160,
	Year		= 1935,
	MagSize		= 30,
	MagReload	= 6,
	Cyclic		= 525,
	Round = {
		MaxLength = 30,
		PropMass  = 0.12,
	}
})

ACF.RegisterWeapon("30mmHMG", "HMG", {
	Name		= "30mm Heavy Machinegun",
	Description	= "30mm shell chucker, light and compact. Your average cold war dogfight go-to.",
	Model		= "models/machinegun/machinegun_30mm_compact.mdl",
	Caliber		= 30,
	Mass		= 480,
	Year		= 1941,
	MagSize		= 25,
	MagReload	= 6,
	Cyclic		= 500,
	Round = {
		MaxLength = 37,
		PropMass  = 0.35,
	}
})

ACF.RegisterWeapon("40mmHMG", "HMG", {
	Name		= "40mm Heavy Machinegun",
	Description	= "The heaviest of the heavy machineguns.  Massively powerful with a killer reload and hefty ammunition requirements, it can pop even relatively heavy targets with ease.",
	Model		= "models/machinegun/machinegun_40mm_compact.mdl",
	Caliber		= 40,
	Mass		= 780,
	Year		= 1955,
	MagSize		= 20,
	MagReload	= 8,
	Cyclic		= 475,
	Round = {
		MaxLength = 42,
		PropMass  = 0.9,
	}
})
