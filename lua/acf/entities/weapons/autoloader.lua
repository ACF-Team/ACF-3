local ACF     = ACF
local Weapons = ACF.Classes.Weapons


Weapons.Register("AL", {
	Name        = "Autoloaded Cannon",
	Description = "An improvement over cannons that allows you fire multiple rounds in succesion at the cost of internal volume, mass and reload speed.",
	Model       = "models/tankgun/tankgun_al_100mm.mdl",
	Sound       = "acf_base/weapons/autoloader.mp3",
	MuzzleFlash = "cannon_muzzleflash_noscale",
	IsScalable  = true,
	Mass        = 2985,
	Spread      = 0.08,
	MagSize     = 10,
	Round = {
		MaxLength  = 80,
		PropLength = 65,
	},
	Preview = {
		Height = 60,
		FOV    = 60,
	},
	Caliber	= {
		Base = 100,
		Min  = 75,
		Max  = 170,
	},
	MagReload = {
		Min = 15,
		Max = 35,
	},
	Cyclic = {
		Min = 28,
		Max = 13,
	},
})

Weapons.RegisterItem("75mmAL", "AL", {
	Caliber = 75,
})

Weapons.RegisterItem("100mmAL", "AL", {
	Caliber = 100,
})

Weapons.RegisterItem("120mmAL", "AL", {
	Caliber = 120,
})

Weapons.RegisterItem("140mmAL", "AL", {
	Caliber = 140,
})

ACF.SetCustomAttachment("models/tankgun/tankgun_al_100mm.mdl", "muzzle", Vector(146.2), Angle(0, 0, 90))

ACF.AddHitboxes("models/tankgun/tankgun_al_100mm.mdl", {
	Breech = {
		Pos       = Vector(-35.33),
		Scale     = Vector(84, 16, 12),
		Sensitive = true
	},
	Barrel = {
		Pos   = Vector(76.67),
		Scale = Vector(140, 9, 9)
	},
	LeftDrum = {
		Pos   = Vector(-57.33, 16, 3),
		Scale = Vector(40, 16, 16)
		-- Critical = true
	},
	RightDrum = {
		Pos   = Vector(-57.33, -16, 3),
		Scale = Vector(40, 16, 16)
		-- Critical = true
	}
})
