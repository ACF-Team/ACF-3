local ACF     = ACF
local Weapons = ACF.Classes.Weapons


Weapons.Register("HW", {
	Name        = "Howitzer",
	Description = "Analog of cannons, except it's intended to fire explosive and chemical rounds where its bigger round size a exceels at.",
	Sound       = "acf_base/weapons/howitzer_new2.mp3",
	Model       = "models/howitzer/howitzer_105mm.mdl",
	MuzzleFlash = "howie_muzzleflash_noscale",
	IsScalable  = true,
	Mass        = 860,
	Spread      = 0.1,
	Round = {
		MaxLength  = 90,
		PropLength = 90,
		Efficiency = 0.65,
	},
	Preview = {
		FOV = 65,
	},
	Caliber	= {
		Base = 105,
		Min  = 75,
		Max  = 203,
	},
})

Weapons.RegisterItem("75mmHW", "HW", {
	Caliber = 75,
})

Weapons.RegisterItem("105mmHW", "HW", {
	Caliber = 105,
})

Weapons.RegisterItem("122mmHW", "HW", {
	Caliber = 122,
})

Weapons.RegisterItem("155mmHW", "HW", {
	Caliber = 155,
})

Weapons.RegisterItem("203mmHW", "HW", {
	Caliber = 203,
})

ACF.SetCustomAttachment("models/howitzer/howitzer_105mm.mdl", "muzzle", Vector(101.08, 0, -1.08))

ACF.AddHitboxes("models/howitzer/howitzer_105mm.mdl", {
	Breech = {
		Pos       = Vector(-8, 0, -0.8),
		Scale     = Vector(47, 11.25, 9.5),
		Sensitive = true
	},
	Barrel = {
		Pos   = Vector(58.5, 0, -0.7),
		Scale = Vector(86, 6, 6)
	}
})
