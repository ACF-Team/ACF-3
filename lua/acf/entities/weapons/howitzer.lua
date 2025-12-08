local ACF     = ACF
local Weapons = ACF.Classes.Weapons


Weapons.Register("HW", {
	Name        = "Howitzer",
	Description = "#acf.descs.weapons.hw",
	Sound       = "acf_base/weapons/howitzer_new2.mp3",
	Model       = "models/howitzer/howitzer_105mm.mdl",
	MuzzleFlash = "howie_muzzleflash_noscale",
	IsScalable  = true,
	Mass        = 860,
	Spread      = 0.1,
	ScaleFactor = 0.84, -- Corrective factor to account for improperly scaled base models
	TransferMult = 4, -- Thermal energy transfer rate
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
	BreechConfigs = {
		MeasuredCaliber = 20.3,
		Locations = {
			{Name = "Breech", LPos = Vector(-47.538, 0, -1.35938), LAng = Angle(0, 0, 0), Width = 7.992125984252, Height = 7.992125984252},
		}
	},
	CostScalar	= 0.5
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
