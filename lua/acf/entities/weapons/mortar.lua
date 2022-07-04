local ACF     = ACF
local Weapons = ACF.Classes.Weapons


Weapons.Register("MO", {
	Name        = "Mortar",
	Description = "Intended as short range artillery, mortars are capable of firing explosives and smoke round at a decent rate at poor velocity and accuracy.",
	Sound       = "acf_base/weapons/mortar_new.mp3",
	Model		= "models/mortar/mortar_120mm.mdl",
	MuzzleFlash = "mortar_muzzleflash_noscale",
	DefaultAmmo = "HE",
	IsScalable  = true,
	Spread      = 0.72,
	Mass        = 459,
	Round = {
		MaxLength  = 40,
		PropLength = 3,
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

Weapons.RegisterItem("60mmM", "MO", {
	Caliber = 60,
})

Weapons.RegisterItem("80mmM", "MO", {
	Caliber = 80,
})

Weapons.RegisterItem("120mmM", "MO", {
	Caliber = 120,
})

Weapons.RegisterItem("150mmM", "MO", {
	Caliber = 150,
})

Weapons.RegisterItem("200mmM", "MO", {
	Caliber = 200,
})

ACF.SetCustomAttachment("models/mortar/mortar_120mm.mdl", "muzzle", Vector(24.02), Angle(0, 0, 90))

ACF.AddHitboxes("models/mortar/mortar_120mm.mdl", {
	Base = {
		Pos   = Vector(-15.4, 0.3),
		Scale = Vector(69, 10, 9)
	}
})
