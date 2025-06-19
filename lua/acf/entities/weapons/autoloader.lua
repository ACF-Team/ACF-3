local ACF     = ACF
local Weapons = ACF.Classes.Weapons


Weapons.Register("AL", {
	Name        = "Autoloaded Cannon",
	Description = "#acf.descs.weapons.al",
	Model       = "models/tankgun/tankgun_al_100mm.mdl",
	Sound       = "acf_base/weapons/autoloader.mp3",
	MuzzleFlash = "cannon_muzzleflash_noscale",
	IsScalable  = true,
	IsAutomatic = true,
	Mass        = 2985,
	Spread      = 0.08,
	MagSize     = 6,
	ScaleFactor = 1.0, -- Corrective factor to account for improperly scaled base models
	TransferMult = 4, -- Thermal energy transfer rate
	Round = {
		MaxLength  = 80,
		PropLength = 65,
	},
	Preview = {
		Height = 60,
		FOV    = 60,
	},
	Caliber	= {
		Base = 100,
		Min  = 75,
		Max  = 170,
	},
	MagReload = {
		Min = 15,
		Max = 35,
	},
	Cyclic = {
		Min = 15,
		Max = 8,
	},
	BreechConfigs = {
		MeasuredCaliber = 17.0,
		Locations = {
			{Name = "Front of Left Drum", LPos = Vector(-62.9, 27.5, 4.5), LAng = Angle(180, 0, 0), Width = 6.6929133858268, Height = 6.6929133858268},
			{Name = "Front of Right Drum", LPos = Vector(-62.9, -27.5, 4.5), LAng = Angle(180, 0, 0), Width = 6.6929133858268, Height = 6.6929133858268},
			{Name = "Rear of Left Drum", LPos = Vector(-130.7, 27.5, 4.5), LAng = Angle(0, 0, 0), Width = 6.6929133858268, Height = 6.6929133858268},
			{Name = "Rear of Right Drum", LPos = Vector(-130.7, -27.5, 4.5), LAng = Angle(0, 0, 0), Width = 6.6929133858268, Height = 6.6929133858268},
		}
	}
})

Weapons.RegisterItem("75mmAL", "AL", {
	Caliber = 75,
})

Weapons.RegisterItem("100mmAL", "AL", {
	Caliber = 100,
})

Weapons.RegisterItem("120mmAL", "AL", {
	Caliber = 120,
})

Weapons.RegisterItem("140mmAL", "AL", {
	Caliber = 140,
})

ACF.SetCustomAttachment("models/tankgun/tankgun_al_100mm.mdl", "muzzle", Vector(146.2), Angle(0, 0, 90))

ACF.AddHitboxes("models/tankgun/tankgun_al_100mm.mdl", {
	Breech = {
		Pos       = Vector(-35.33),
		Scale     = Vector(84, 16, 12),
		Sensitive = true
	},
	Barrel = {
		Pos   = Vector(76.67),
		Scale = Vector(140, 9, 9)
	},
	LeftDrum = {
		Pos   = Vector(-57.33, 16, 3),
		Scale = Vector(40, 16, 16)
		-- Critical = true
	},
	RightDrum = {
		Pos   = Vector(-57.33, -16, 3),
		Scale = Vector(40, 16, 16)
		-- Critical = true
	}
})
