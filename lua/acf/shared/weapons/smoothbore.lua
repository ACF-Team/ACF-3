ACF.RegisterWeaponClass("SB", {
	Name        = "Smoothbore Cannon",
	Description = "More modern smoothbore cannons that can only fire munitions that do not rely on spinning for accuracy.",
	Model		= "models/tankgun_old/tankgun_100mm.mdl",
	Sound       = "acf_base/weapons/cannon_new.mp3",
	MuzzleFlash = "cannon_muzzleflash_noscale",
	DefaultAmmo = "APFSDS",
	IsScalable  = true,
	Spread      = 0.08,
	Mass		= 3000,
	Round = {
		MaxLength  = 95,
		PropLength = 40,
	},
	Preview = {
		Height = 60,
		FOV    = 60,
	},
	Caliber	= {
		Base = 100,
		Min  = 100,
		Max  = 140,
	},
})

ACF.RegisterWeapon("105mmSB", "SB", {
	Caliber = 105,
})

ACF.RegisterWeapon("120mmSB", "SB", {
	Caliber = 120,
})

ACF.RegisterWeapon("140mmSB", "SB", {
	Caliber = 140,
})

ACF.SetCustomAttachment("models/tankgun_old/tankgun_100mm.mdl", "muzzle", Vector(135), Angle(0, 0, 90))

ACF.AddHitboxes("models/tankgun_old/tankgun_100mm.mdl", {
	Breech = {
		Pos       = Vector(-46),
		Scale     = Vector(28.5, 17.5, 15),
		Sensitive = true
	},
	Barrel = {
		Pos   = Vector(50),
		Scale = Vector(165, 7.5, 7.5)
	}
})
