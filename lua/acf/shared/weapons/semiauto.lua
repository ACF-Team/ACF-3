ACF.RegisterWeaponClass("SA", {
	Name        = "Semiautomatic Cannon",
	Description = "Semiautomatic cannons are smaller and lighter than their fully automatic counterpart, but they'll constantly reload every few rounds.",
	Model       = "models/autocannon/semiautocannon_45mm.mdl", -- TODO: Properly scale model, atm it's ~60mm
	Sound       = "acf_base/weapons/sa_fire1.mp3",
	MuzzleFlash = "semi_muzzleflash_noscale",
	IsScalable  = true,
	IsBoxed     = true,
	Spread      = 0.12,
	Mass        = 453,
	MagSize     = 5,
	Round = {
		MaxLength  = 36,
		PropLength = 29.25,
	},
	Preview = {
		FOV = 70,
	},
	Caliber	= {
		Base = 45,
		Min  = 20,
		Max  = 76,
	},
	MagReload = {
		Min = 3,
		Max = 10,
	},
	Cyclic = {
		Min = 350,
		Max = 150,
	},
})

ACF.RegisterWeapon("25mmSA", "SA", {
	Caliber = 25,
})

ACF.RegisterWeapon("37mmSA", "SA", {
	Caliber = 37,
})

ACF.RegisterWeapon("45mmSA", "SA", {
	Caliber = 45,
})

ACF.RegisterWeapon("57mmSA", "SA", {
	Caliber = 57,
})

ACF.RegisterWeapon("76mmSA", "SA", {
	Caliber = 76,
})

ACF.SetCustomAttachment("models/autocannon/semiautocannon_45mm.mdl", "muzzle", Vector(79.2), Angle(0, 0, 180))

ACF.AddHitboxes("models/autocannon/semiautocannon_45mm.mdl", {
	Frame = {
		Pos       = Vector(-1.35, 0, 0.45),
		Scale     = Vector(37, 12, 6.75),
		Sensitive = true
	},
	Barrel = {
		Pos   = Vector(48.15),
		Scale = Vector(62.1, 2, 3.8),
		Cylinder = true
	}
})
