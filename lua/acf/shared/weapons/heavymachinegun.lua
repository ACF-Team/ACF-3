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
	Caliber = 13,
})

ACF.RegisterWeapon("20mmHMG", "HMG", {
	Caliber = 20,
})

ACF.RegisterWeapon("30mmHMG", "HMG", {
	Caliber = 30,
})

ACF.RegisterWeapon("40mmHMG", "HMG", {
	Caliber = 40,
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
