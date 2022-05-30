local ACF     = ACF
local Weapons = ACF.Classes.Weapons


Weapons.RegisterGroup("SC", {
	Name        = "Short-Barrelled Cannon",
	Description = "Shorter variant of cannons, limited to shorter round size and therefore worse performance than their full sized counterpart.",
	Model       = "models/tankgun/tankgun_short_100mm.mdl",
	Sound       = "acf_base/weapons/cannon_new.mp3",
	MuzzleFlash = "cannon_muzzleflash_noscale",
	IsScalable  = true,
	Spread      = 0.16,
	Mass        = 1195,
	Round = {
		MaxLength  = 80,
		PropLength = 65,
		Efficiency = 0.8,
	},
	Preview = {
		Height = 70,
		FOV    = 60,
	},
	Caliber	= {
		Base = 100,
		Min  = 20,
		Max  = 170,
	},
	Sounds = {
		[50] = "acf_base/weapons/ac_fire4.mp3",
	},
})

Weapons.Register("37mmSC", "SC", {
	Caliber = 37,
})

Weapons.Register("50mmSC", "SC", {
	Caliber = 50,
})

Weapons.Register("75mmSC", "SC", {
	Caliber = 75,
})

Weapons.Register("100mmSC", "SC", {
	Caliber = 100,
})

Weapons.Register("120mmSC", "SC", {
	Caliber = 120,
})

Weapons.Register("140mmSC", "SC", {
	Caliber = 140,
})

ACF.SetCustomAttachment("models/tankgun/tankgun_short_100mm.mdl", "muzzle", Vector(82.86, -0.01), Angle(0, 0, 90))

ACF.AddHitboxes("models/tankgun/tankgun_short_100mm.mdl", {
	Breech = {
		Pos       = Vector(-14.19),
		Scale     = Vector(28.37, 12.83, 12.83),
		Sensitive = true
	},
	Barrel = {
		Pos   = Vector(41.21),
		Scale = Vector(82.41, 6.76, 6.76)
	}
})
