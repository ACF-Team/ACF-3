local ACF     = ACF
local Weapons = ACF.Classes.Weapons


Weapons.Register("LAC", {
	Name        = "Light Autocannon",
	Description = "#acf.descs.weapons.lac",
	Model       = "models/machinegun/machinegun_40mm_compact.mdl",
	Sound       = "acf_base/weapons/mg_fire3.mp3",
	MuzzleFlash = "mg_muzzleflash_noscale",
	IsScalable  = true,
	IsAutomatic = true,
	IsBelted	= true,
	Mass        = 301,
	Spread      = 0.48,
	ScaleFactor = 0.81, -- Corrective factor to account for improperly scaled base models
	ReloadMod 	= 0.5, -- Load time multiplier. Represents the ease of manipulating the weapon's ammunition
	TransferMult = 20, -- Thermal energy transfer rate
	CyclicCeilMult = 2, -- How high above base cyclic the gun can be set to
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
