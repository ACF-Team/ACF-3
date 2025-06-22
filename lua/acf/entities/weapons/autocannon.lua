local ACF     = ACF
local Weapons = ACF.Classes.Weapons


Weapons.Register("AC", {
	Name        = "Autocannon",
	Description = "#acf.descs.weapons.ac",
	Model       = "models/autocannon/autocannon_50mm.mdl",
	Sound       = "acf_base/weapons/ac_fire4.mp3",
	MuzzleFlash = "auto_muzzleflash_noscale",
	IsScalable  = true,
	IsAutomatic = true,
	IsBelted	= true,
	Mass        = 1953, -- Relative to the model's volume
	Spread      = 0.2,
	ScaleFactor = 0.86, -- Corrective factor to account for improperly scaled base models
	ReloadMod 	= 0.5, -- Load time multiplier. Represents the ease of manipulating the weapon's ammunition
	TransferMult = 20, -- Thermal energy transfer rate
	CyclicCeilMult = 2, -- How high above base cyclic the gun can be set to
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
