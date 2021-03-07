ACF.RegisterWeaponClass("SL", {
	Name        = "Smoke Launcher",
	Description = "Smoke launcher to block an attacker's line of sight.",
	Sound       = "acf_base/weapons/smoke_launch.mp3",
	Model       = "models/launcher/40mmsl.mdl",
	MuzzleFlash = "gl_muzzleflash_noscale",
	Cleanup     = "acf_smokelauncher",
	DefaultAmmo = "SM",
	IsScalable  = true,
	IsBoxed     = true,
	Spread      = 0.32,
	Mass        = 2,
	Caliber	= {
		Base = 40,
		Min  = 40,
		Max  = 81,
	},
	MagSize = {
		Min = 1,
		Max = 1,
	},
	MagReload = {
		Min = 20,
		Max = 30,
	},
	Cyclic = {
		Min = 600,
		Max = 600,
	},
	Round = {
		MaxLength = 17.5,
		PropMass  = 0.000075,
	},
	LimitConVar = {
		Name = "_acf_smokelauncher",
		Amount = 10,
		Text = "Maximum amount of ACF smoke launchers a player can create."
	},
	Preview = {
		FOV = 60,
	},
})

ACF.RegisterWeapon("40mmSL", "SL", {
	Name		= "40mm Smoke Launcher",
	Description	= "",
	Model		= "models/launcher/40mmsl.mdl",
	Caliber		= 40,
	Mass		= 1,
	Year		= 1941,
	MagSize		= 1,
	MagReload	= 30,
	Cyclic		= 600,
	Round = {
		MaxLength = 17.5,
		PropMass  = 0.000075,
	}
})

ACF.SetCustomAttachment("models/launcher/40mmsl.mdl", "muzzle", Vector(5), Angle(0, 0, 180))

ACF.AddHitboxes("models/launcher/40mmsl.mdl", {
	Base = {
		Pos   = Vector(0.7, 0, -0.1),
		Scale = Vector(8, 3, 2)
	}
})
