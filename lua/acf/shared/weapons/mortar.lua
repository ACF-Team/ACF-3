ACF.RegisterWeaponClass("MO", {
	Name        = "Mortar",
	Description = "Mortars are able to fire shells with usefull payloads from a light weight gun, at the price of limited velocities.",
	Sound       = "acf_base/weapons/mortar_new.mp3",
	Model		= "models/mortar/mortar_120mm.mdl",
	MuzzleFlash = "mortar_muzzleflash_noscale",
	DefaultAmmo = "HE",
	IsScalable  = true,
	Spread      = 0.72,
	Mass        = 300,
	Round = {
		MaxLength  = 40,
		PropLength = 2,
	},
	Preview = {
		Height = 80,
		FOV    = 65,
	},
	Caliber	= {
		Base = 120,
		Min  = 37,
		Max  = 280,
	},
})

ACF.RegisterWeapon("60mmM", "MO", {
	Caliber = 60,
})

ACF.RegisterWeapon("80mmM", "MO", {
	Caliber = 80,
})

ACF.RegisterWeapon("120mmM", "MO", {
	Caliber = 120,
})

ACF.RegisterWeapon("150mmM", "MO", {
	Caliber = 150,
})

ACF.RegisterWeapon("200mmM", "MO", {
	Caliber = 200,
})

ACF.SetCustomAttachment("models/mortar/mortar_120mm.mdl", "muzzle", Vector(24.02), Angle(0, 0, 90))

ACF.AddHitboxes("models/mortar/mortar_120mm.mdl", {
	Base = {
		Pos   = Vector(-15.4, 0.3),
		Scale = Vector(69, 10, 9)
	}
})
