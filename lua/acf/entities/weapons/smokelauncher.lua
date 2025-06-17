local ACF     = ACF
local Weapons = ACF.Classes.Weapons


Weapons.Register("SL", {
	Name        = "Smoke Launcher",
	Description = "#acf.descs.weapons.sl",
	Sound       = "acf_base/weapons/smoke_launch.mp3",
	Model       = "models/launcher/40mmsl.mdl",
	MuzzleFlash = "gl_muzzleflash_noscale",
	Cleanup     = "acf_smokelauncher",
	DefaultAmmo = "SM",
	IsScalable  = true,
	IsBoxed     = true,
	Spread      = 0.32,
	Mass        = 3.77,
	Cyclic      = 600,
	MagSize     = 1,
	ScaleFactor = 0.96, -- Corrective factor to account for improperly scaled base models
	TransferMult = 4, -- Thermal energy transfer rate
	LimitConVar = {
		Name = "_acf_smokelauncher",
		Amount = 10,
		Text = "Maximum amount of ACF smoke launchers a player can create."
	},
	Round = {
		MaxLength  = 17.5,
		PropLength = 0.05,
	},
	Preview = {
		FOV = 75,
	},
	Caliber	= {
		Base = 40,
		Min  = 40,
		Max  = 81,
	},
	MagReload = {
		Min = 10,
		Max = 15,
	},
	BreechConfigs = {
		MeasuredCaliber = 8.1,
		Locations = {
			{Name = "Breech", LPos = Vector(-7.09631, 0, -0.180664), LAng = Angle(0, 0, 0), Width = 3.1889763779528, Height = 3.1889763779528},
			{Name = "Barrel", LPos = Vector(9.8606, 0, -0.182617), LAng = Angle(180, 0, 0), Width = 3.1889763779528, Height = 3.1889763779528},
		}
	}
})

Weapons.RegisterItem("40mmSL", "SL", {
	Caliber = 40,
})

ACF.SetCustomAttachment("models/launcher/40mmsl.mdl", "muzzle", Vector(5), Angle(0, 0, 180))

ACF.AddHitboxes("models/launcher/40mmsl.mdl", {
	Base = {
		Pos   = Vector(0.7, 0, -0.1),
		Scale = Vector(8, 3, 2)
	}
})
