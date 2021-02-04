ACF.RegisterWeaponClass("GL", {
	Name        = "Grenade Launcher",
	Description = "Grenade Launchers can fire shells with relatively large payloads at a fast rate, but with very limited velocities and poor accuracy.",
	Sound       = "acf_base/weapons/grenadelauncher.mp3",
	Model       = "models/launcher/40mmgl.mdl",
	MuzzleFlash = "gl_muzzleflash_noscale",
	DefaultAmmo = "HE",
	IsScalable  = true,
	IsBoxed     = true,
	Mass		= 55,
	Spread      = 0.28,
	Caliber	= {
		Base = 40,
		Min  = 25,
		Max  = 40,
	},
	MagSize = {
		Min = 100,
		Max = 60,
	},
	MagReload = {
		Min = 7.5,
		Max = 10,
	},
	Cyclic = {
		Min = 250,
		Max = 200,
	},
	Round = {
		MaxLength = 7.5,
		PropMass  = 0.01,
	},
})

ACF.RegisterWeapon("40mmGL", "GL", {
	Name		= "40mm Grenade Launcher",
	Description	= "The 40mm chews up infantry but is about as useful as tits on a nun for fighting armor. Often found on 4x4s rolling through the third world.",
	Model		= "models/launcher/40mmgl.mdl",
	Caliber		= 40,
	Mass		= 55,
	Year		= 1970,
	MagSize		= 30,
	MagReload	= 7.5,
	Cyclic		= 200,
	Round = {
		MaxLength = 7.5,
		PropMass  = 0.01,
	}
})

ACF.RegisterWeapon("40mmCL", "GL", {
	Caliber = 40,
})

ACF.SetCustomAttachment("models/launcher/40mmgl.mdl", "muzzle", Vector(19), Angle(0, 0, -180))
