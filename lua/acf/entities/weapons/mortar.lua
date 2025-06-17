local ACF     = ACF
local Weapons = ACF.Classes.Weapons


Weapons.Register("MO", {
	Name        = "Mortar",
	Description = "#acf.descs.weapons.mo",
	Sound       = "acf_base/weapons/mortar_new.mp3",
	Model		= "models/mortar/mortar_120mm.mdl",
	MuzzleFlash = "mortar_muzzleflash_noscale",
	DefaultAmmo = "HE",
	IsScalable  = true,
	Spread      = 0.72,
	Mass        = 459,
	ScaleFactor = 0.84, -- Corrective factor to account for improperly scaled base models
	TransferMult = 4, -- Thermal energy transfer rate
	Round = {
		MaxLength  = 40,
		PropLength = 3,
	},
	Preview = {
		Height = 80,
		FOV    = 65,
	},
	Caliber	= {
		Base = 120,
		Min  = 37,
		Max  = 280,
	},
	BreechConfigs = {
		MeasuredCaliber = 28.0,
		Locations = {
			{Name = "Breech", LPos = Vector(-97.4919, 0, 0.015625), LAng = Angle(0, 0, 0), Width = 11.023622047244, Height = 11.023622047244},
			{Name = "Barrel", LPos = Vector(37.0706, 0, 0.015625), LAng = Angle(180, 0, 0), Width = 11.023622047244, Height = 11.023622047244},
		}
	}
})

Weapons.RegisterItem("60mmM", "MO", {
	Caliber = 60,
})

Weapons.RegisterItem("80mmM", "MO", {
	Caliber = 80,
})

Weapons.RegisterItem("120mmM", "MO", {
	Caliber = 120,
})

Weapons.RegisterItem("150mmM", "MO", {
	Caliber = 150,
})

Weapons.RegisterItem("200mmM", "MO", {
	Caliber = 200,
})

ACF.SetCustomAttachment("models/mortar/mortar_120mm.mdl", "muzzle", Vector(24.02), Angle(0, 0, 90))

ACF.AddHitboxes("models/mortar/mortar_120mm.mdl", {
	Base = {
		Pos   = Vector(-15.4, 0.3),
		Scale = Vector(69, 10, 9)
	}
})
