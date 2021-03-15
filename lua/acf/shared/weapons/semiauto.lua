ACF.RegisterWeaponClass("SA", {
	Name        = "Semiautomatic Cannon",
	Description = "Semiautomatic cannons offer light weight, small size, and high rates of fire at the cost of often reloading and low accuracy.",
	Model       = "models/autocannon/semiautocannon_45mm.mdl", -- TODO: Properly scale model, atm it's ~60mm
	Sound       = "acf_base/weapons/sa_fire1.mp3",
	MuzzleFlash = "semi_muzzleflash_noscale",
	IsScalable  = true,
	IsBoxed     = true,
	Spread      = 0.12,
	Mass        = 585, -- Approx 800kg @ 50mm
	MagSize     = 5,
	Round = {
		MaxLength  = 40,
		PropLength = 32,
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
		Min = 325,
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
	Breech = {
		Pos       = Vector(-1.35, 0, 0.45),
		Scale     = Vector(37.8, 12.6, 6.75),
		Sensitive = true
	},
	Barrel = {
		Pos   = Vector(48.15),
		Scale = Vector(62.1, 3.6, 3.6)
	}
})
