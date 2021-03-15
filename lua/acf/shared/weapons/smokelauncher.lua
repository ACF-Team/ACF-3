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
	Cyclic      = 600,
	MagSize     = 1,
	LimitConVar = {
		Name = "_acf_smokelauncher",
		Amount = 10,
		Text = "Maximum amount of ACF smoke launchers a player can create."
	},
	Round = {
		MaxLength  = 17.5,
		PropLength = 0.05,
	},
	Preview = {
		FOV = 75,
	},
	Caliber	= {
		Base = 40,
		Min  = 40,
		Max  = 81,
	},
	MagReload = {
		Min = 10,
		Max = 15,
	},
})

ACF.RegisterWeapon("40mmSL", "SL", {
	Caliber = 40,
})

ACF.SetCustomAttachment("models/launcher/40mmsl.mdl", "muzzle", Vector(5), Angle(0, 0, 180))

ACF.AddHitboxes("models/launcher/40mmsl.mdl", {
	Base = {
		Pos   = Vector(0.7, 0, -0.1),
		Scale = Vector(8, 3, 2)
	}
})
