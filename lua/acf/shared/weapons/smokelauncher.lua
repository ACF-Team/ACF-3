ACF.RegisterWeaponClass("SL", {
	Name		  = "Smoke Launcher",
	Description	  = "Smoke launcher to block an attacker's line of sight.",
	MuzzleFlash	  = "gl_muzzleflash_noscale",
	Spread		  = 0.32,
	Sound		  = "acf_base/weapons/smoke_launch.mp3",
	IsBoxed		  = true,
	LimitConVar = {
		Name = "_acf_smokelauncher",
		Amount = 10,
		Text = "Maximum amount of ACF smoke launchers a player can create."
	},
	Caliber	= {
		Min = 40,
		Max = 81,
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
