local ACF     = ACF
local Weapons = ACF.Classes.Weapons


Weapons.Register("AC", {
	Name        = "Autocannon",
	Description = "Despite being the heaviest piece of automatic weaponry, they offer high magazine capacity with a decent firerate and reload speed.",
	Model       = "models/autocannon/autocannon_50mm.mdl",
	Sound       = "acf_base/weapons/ac_fire4.mp3",
	MuzzleFlash = "auto_muzzleflash_noscale",
	IsScalable  = true,
	Mass        = 1953, -- Relative to the model's volume
	Spread      = 0.2,
	Round = {
		MaxLength  = 40, -- Relative to the Base caliber, in cm
		PropLength = 32.5, -- Relative to the Base caliber, in cm
	},
	Preview = {
		Height = 80,
		FOV    = 60,
	},
	Caliber	= {
		Base = 50,
		Min  = 20,
		Max  = 60,
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
		Min = 250,
		Max = 150,
	},
})

Weapons.RegisterItem("20mmAC", "AC", {
	Caliber = 20,
})

Weapons.RegisterItem("30mmAC", "AC", {
	Caliber = 30,
})

Weapons.RegisterItem("40mmAC", "AC", {
	Caliber = 40,
})

Weapons.RegisterItem("50mmAC", "AC", {
	Caliber = 50,
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
