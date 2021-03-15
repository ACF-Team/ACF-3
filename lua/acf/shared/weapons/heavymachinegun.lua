ACF.RegisterWeaponClass("HMG", {
	Name        = "Heavy Machinegun",
	Description = "Designed as autocannons for aircraft, HMGs are rapid firing, lightweight, and compact but sacrifice accuracy, magazine size, and reload times.",
	Model       = "models/machinegun/machinegun_40mm_compact.mdl",-- TODO: Properly scale model, atm it's ~60mm
	Sound       = "acf_base/weapons/mg_fire3.mp3",
	MuzzleFlash = "mg_muzzleflash_noscale",
	IsScalable  = true,
	Mass        = 200,
	Spread      = 0.48,
	Round = {
		MaxLength  = 25,
		PropLength = 17.5,
	},
	LongBarrel = {
		Index    = 2,
		Submodel = 4,
		NewPos   = "muzzle2",
	},
	Preview = {
		Height = 100,
		FOV    = 60,
	},
	Caliber	= {
		Base = 40,
		Min  = 13,
		Max  = 40,
	},
	MagSize = {
		Min = 250,
		Max = 100,
	},
	MagReload = {
		Min = 6,
		Max = 12,
	},
	Cyclic = {
		Min = 600,
		Max = 400,
	},
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
	Description	= "The heaviest of the heavy machineguns. Massively powerful with a killer reload and hefty ammunition requirements, it can pop even relatively heavy targets with ease.",
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

ACF.SetCustomAttachments("models/machinegun/machinegun_40mm_compact.mdl", {
	{ Name = "muzzle", Pos = Vector(51.04, -0.03), Ang = Angle(0, 0, 90) },
	{ Name = "muzzle2", Pos = Vector(115.39, -0.25), Ang = Angle(0, 0, 90) },
})

ACF.AddHitboxes("models/machinegun/machinegun_40mm_compact.mdl", {
	Base = {
		Pos   = Vector(17.5),
		Scale = Vector(68, 5, 10)
	}
})
