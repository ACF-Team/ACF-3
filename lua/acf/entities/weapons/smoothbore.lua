local Weapons = ACF.Classes.Weapons

Weapons.Register("SB", {
	Name        = "Smoothbore Cannon",
	Description = "A direct improvement over regular cannons, these can only fire modern munitions.",
	Model		= "models/tankgun_new/tankgun_100mm.mdl",
	Sound       = "acf_base/weapons/cannon_new.mp3",
	MuzzleFlash = "cannon_muzzleflash_noscale",
	DefaultAmmo = "APFSDS",
	IsScalable  = true,
	Spread      = 0.08,
	Mass		= 2031,
	Round = {
		MaxLength  = 80,
		PropLength = 58,
	},
	Preview = {
		Height = 60,
		FOV    = 60,
	},
	Caliber	= {
		Base = 100,
		Min  = 100,
		Max  = 155,
	},
})

Weapons.RegisterItem("105mmSB", "SB", {
	Caliber = 105,
})

Weapons.RegisterItem("120mmSB", "SB", {
	Caliber = 120,
})

Weapons.RegisterItem("140mmSB", "SB", {
	Caliber = 140,
})
