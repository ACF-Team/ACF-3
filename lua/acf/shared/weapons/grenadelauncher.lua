ACF.RegisterWeaponClass("GL", {
	Name        = "Grenade Launcher",
	Description = "Grenade Launchers can fire shells with relatively large payloads at a fast rate, but with very limited velocities and poor accuracy.",
	Sound       = "acf_base/weapons/grenadelauncher.mp3",
	Model       = "models/launcher/40mmgl.mdl",
	MuzzleFlash = "gl_muzzleflash_noscale",
	DefaultAmmo = "HE",
	IsScalable  = true,
	IsBoxed     = true,
	Mass		= 80,
	Spread      = 0.28,
	Cyclic      = 250,
	Round = {
		MaxLength  = 10,
		PropLength = 0.5,
	},
	Preview = {
		FOV = 75,
	},
	Caliber	= {
		Base = 40,
		Min  = 25,
		Max  = 40,
	},
	MagSize = {
		Min = 80,
		Max = 50,
	},
	MagReload = {
		Min = 7.5,
		Max = 10,
	},
})

ACF.RegisterWeapon("40mmGL", "GL", {
	Caliber = 40,
})

ACF.RegisterWeapon("40mmCL", "GL", {
	Caliber = 40,
})

ACF.SetCustomAttachment("models/launcher/40mmgl.mdl", "muzzle", Vector(19), Angle(0, 0, -180))

ACF.AddHitboxes("models/launcher/40mmgl.mdl", {
	Breech = {
		Pos       = Vector(0, 0, -1.25),
		Scale     = Vector(20, 5, 6),
		Sensitive = true
	},
	Barrel = {
		Pos   = Vector(14, 0, 0.1),
		Scale = Vector(12, 2, 2)
	}
})
