ACF.RegisterWeaponClass("GL", {
	Name		  = "Grenade Launcher",
	Description	  = "Grenade Launchers can fire shells with relatively large payloads at a fast rate, but with very limited velocities and poor accuracy.",
	MuzzleFlash	  = "gl_muzzleflash_noscale",
	Spread		  = 0.28,
	Sound		  = "acf_base/weapons/grenadelauncher.mp3",
	IsBoxed		  = true,
	Caliber	= {
		Min = 25,
		Max = 40,
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
