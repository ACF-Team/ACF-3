ACF.RegisterWeaponClass("MO", {
	Name        = "Mortar",
	Description = "Mortars are able to fire shells with usefull payloads from a light weight gun, at the price of limited velocities.",
	Sound       = "acf_base/weapons/mortar_new.mp3",
	Model		= "models/mortar/mortar_120mm.mdl",
	MuzzleFlash = "mortar_muzzleflash_noscale",
	DefaultAmmo = "HE",
	IsScalable  = true,
	Spread      = 0.72,
	Mass        = 640,
	Caliber	= {
		Base = 120,
		Min  = 37,
		Max  = 280,
	},
	Round = {
		MaxLength = 45,
		PropMass  = 0.175,
	},
})

ACF.RegisterWeapon("60mmM", "MO", {
	Name		= "60mm Mortar",
	Description	= "The 60mm is a common light infantry support weapon, with a high rate of fire but a puny payload.",
	Model		= "models/mortar/mortar_60mm.mdl",
	Caliber		= 60,
	Mass		= 60,
	Year		= 1930,
	Round = {
		MaxLength = 20,
		PropMass  = 0.037,
	}
})

ACF.RegisterWeapon("80mmM", "MO", {
	Name		= "80mm Mortar",
	Description	= "The 80mm is a common infantry support weapon, with a good bit more boom than its little cousin.",
	Model		= "models/mortar/mortar_80mm.mdl",
	Caliber		= 80,
	Mass		= 120,
	Year		= 1930,
	Round = {
		MaxLength = 28,
		PropMass  = 0.055,
	}
})

ACF.RegisterWeapon("120mmM", "MO", {
	Name		= "120mm Mortar",
	Description	= "The versatile 120 is sometimes vehicle-mounted to provide quick boomsplat to support the infantry. Carries more boom in its boomsplat, has good HEAT performance, and is more accurate in high-angle firing.",
	Model		= "models/mortar/mortar_120mm.mdl",
	Caliber		= 120,
	Mass		= 640,
	Year		= 1935,
	Round = {
		MaxLength = 45,
		PropMass  = 0.175,
	}
})

ACF.RegisterWeapon("150mmM", "MO", {
	Name		= "150mm Mortar",
	Description	= "The perfect balance between the 120mm and the 200mm. Can prove a worthy main gun weapon, as well as a mighty good mortar emplacement",
	Model		= "models/mortar/mortar_150mm.mdl",
	Caliber		= 150,
	Mass		= 1255,
	Year		= 1945,
	Round = {
		MaxLength = 58,
		PropMass  = 0.235,
	}
})

ACF.RegisterWeapon("200mmM", "MO", {
	Name		= "200mm Mortar",
	Description	= "The 200mm is a beast, often used against fortifications. Though enormously powerful, feel free to take a nap while it reloads",
	Model		= "models/mortar/mortar_200mm.mdl",
	Caliber		= 200,
	Mass		= 2850,
	Year		= 1940,
	Round = {
		MaxLength = 80,
		PropMass  = 0.330,
	}
})

ACF.SetCustomAttachment("models/mortar/mortar_120mm.mdl", "muzzle", Vector(24.02), Angle(0, 0, 90))

ACF.AddHitboxes("models/mortar/mortar_120mm.mdl", {
	Base = {
		Pos   = Vector(-15.4, 0.3),
		Scale = Vector(69, 10, 9)
	}
})
