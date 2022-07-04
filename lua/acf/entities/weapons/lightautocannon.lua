local ACF     = ACF
local Weapons = ACF.Classes.Weapons


Weapons.Register("LAC", {
	Name        = "Light Autocannon",
	Description = "Compact variation of autocannons, they offer higher firerates at the cost of smaller magazine size.",
	Model       = "models/machinegun/machinegun_40mm_compact.mdl",
	Sound       = "acf_base/weapons/mg_fire3.mp3",
	MuzzleFlash = "mg_muzzleflash_noscale",
	IsScalable  = true,
	Mass        = 301,
	Spread      = 0.48,
	Round = {
		MaxLength  = 32,
		PropLength = 26,
	},
	LongBarrel = {
		Index    = 2,
		Submodel = 4,
		NewPos   = "muzzle2",
	},
	Preview = {
		Height = 100,
		FOV    = 60,
	},
	Caliber	= {
		Base = 40,
		Min  = 20,
		Max  = 40,
	},
	MagSize = {
		Min = 250,
		Max = 100,
	},
	MagReload = {
		Min = 6,
		Max = 12,
	},
	Cyclic = {
		Min = 600,
		Max = 400,
	},
})

Weapons.RegisterItem("20mmHMG", "LAC", {
	Caliber = 20,
})

Weapons.RegisterItem("30mmHMG", "LAC", {
	Caliber = 30,
})

Weapons.RegisterItem("40mmHMG", "LAC", {
	Caliber = 40,
})

ACF.SetCustomAttachments("models/machinegun/machinegun_40mm_compact.mdl", {
	{ Name = "muzzle", Pos = Vector(51.04, -0.03), Ang = Angle(0, 0, 90) },
	{ Name = "muzzle2", Pos = Vector(115.39, -0.25), Ang = Angle(0, 0, 90) },
})

ACF.AddHitboxes("models/machinegun/machinegun_40mm_compact.mdl", {
	Base = {
		Pos   = Vector(17.5),
		Scale = Vector(68, 5, 10)
	}
})
