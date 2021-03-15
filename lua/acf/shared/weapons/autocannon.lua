ACF.RegisterWeaponClass("AC", {
	Name        = "Autocannon",
	Description = "Autocannons have a rather high weight and bulk for the ammo they fire, but they can fire it extremely fast.",
	Model       = "models/autocannon/autocannon_50mm.mdl", -- TODO: Properly scale model, atm it's ~70mm
	Sound       = "acf_base/weapons/ac_fire4.mp3",
	MuzzleFlash = "auto_muzzleflash_noscale",
	IsScalable  = true,
	Mass        = 1200, -- Relative to the model's volume
	Spread      = 0.2,
	Round = {
		MaxLength  = 45, -- Relative to the Base caliber, in cm
		PropLength = 35, -- Relative to the Base caliber, in cm
	},
	Preview = {
		Height = 80,
		FOV    = 60,
	},
	Caliber	= {
		Base = 50,
		Min  = 20,
		Max  = 50,
	},
	MagSize = {
		Min = 500,
		Max = 200,
	},
	MagReload = {
		Min = 10,
		Max = 20,
	},
	Cyclic = {
		Min = 200,
		Max = 150,
	},
})

ACF.RegisterWeapon("20mmAC", "AC", {
	Name		= "20mm Autocannon",
	Description	= "The 20mm autocannon is the smallest of the family; having a good rate of fire but a tiny shell.",
	Model		= "models/autocannon/autocannon_20mm.mdl",
	Caliber		= 20,
	Mass		= 500,
	Year		= 1930,
	MagSize		= 100,
	MagReload	= 15,
	Cyclic		= 250,
	Round = {
		MaxLength = 32,
		PropMass  = 0.13,
	}
})

ACF.RegisterWeapon("30mmAC", "AC", {
	Name		= "30mm Autocannon",
	Description	= "The 30mm autocannon can fire shells with sufficient space for a small payload, and has modest anti-armor capability",
	Model		= "models/autocannon/autocannon_30mm.mdl",
	Caliber		= 30,
	Mass		= 1000,
	Year		= 1935,
	MagSize		= 75,
	MagReload	= 20,
	Cyclic		= 225,
	Round = {
		MaxLength = 39,
		PropMass  = 0.350,
	}
})

ACF.RegisterWeapon("40mmAC", "AC", {
	Name		= "40mm Autocannon",
	Description	= "The 40mm autocannon can fire shells with sufficient space for a useful payload, and can get decent penetration with proper rounds.",
	Model		= "models/autocannon/autocannon_40mm.mdl",
	Caliber		= 40,
	Mass		= 1500,
	Year		= 1940,
	MagSize		= 30,
	MagReload	= 25,
	Cyclic		= 200,
	Round = {
		MaxLength = 45,
		PropMass  = 0.9,
	}
})

ACF.RegisterWeapon("50mmAC", "AC", {
	Name		= "50mm Autocannon",
	Description	= "The 50mm autocannon fires shells comparable with the 50mm Cannon, making it capable of destroying light armour quite quickly.",
	Model		= "models/autocannon/autocannon_50mm.mdl",
	Caliber		= 50,
	Mass		= 2000,
	Year		= 1965,
	MagSize		= 25,
	MagReload	= 30,
	Cyclic		= 175,
	Round = {
		MaxLength = 52,
		PropMass  = 1.2,
	}
})

ACF.SetCustomAttachment("models/autocannon/autocannon_50mm.mdl", "muzzle", Vector(120), Angle(0, 0, 180))

ACF.AddHitboxes("models/autocannon/autocannon_50mm.mdl", {
	Breech = {
		Pos       = Vector(-3, 0, -1.6),
		Scale     = Vector(52, 15, 19),
		Sensitive = true,
	},
	Barrel = {
		Pos   = Vector(65),
		Scale = Vector(83, 5, 5),
	}
})
