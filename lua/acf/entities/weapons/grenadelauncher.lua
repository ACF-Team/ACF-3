local ACF     = ACF
local Weapons = ACF.Classes.Weapons


Weapons.Register("GL", {
	Name        = "Grenade Launcher",
	Description = "#acf.descs.weapons.gl",
	Sound       = "acf_base/weapons/grenadelauncher.mp3",
	Model       = "models/launcher/40mmgl.mdl",
	MuzzleFlash = "gl_muzzleflash_noscale",
	DefaultAmmo = "HE",
	IsScalable  = true,
	IsBelted	= true,
	IsAutomatic = true,
	Mass		= 101,
	Spread      = 0.28,
	Cyclic      = 250,
	ScaleFactor = 0.96, -- Corrective factor to account for improperly scaled base models
	TransferMult = 20, -- Thermal energy transfer rate
	CyclicCeilMult = 2, -- How high above base cyclic the gun can be set to
	Round = {
		MaxLength  = 10,
		PropLength = 1,
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
	LimitConVar = {
		Name = "_acf_grenadelauncher",
		Amount = 4,
		Text = "Maximum amount of ACF grenade launchers a player can create."
	},
	CostScalar	= 0.5
})

Weapons.RegisterItem("40mmGL", "GL", {
	Caliber = 40,
})

Weapons.RegisterItem("40mmCL", "GL", {
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
