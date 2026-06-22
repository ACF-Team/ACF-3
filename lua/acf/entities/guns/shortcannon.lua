local ACF     = ACF

ACF.Classes.DefineClass("ACF.Guns.ShortBarrelledCannon", "ACF.Guns.BaseScalableGun", function()
	CLASS.Name       	= "Short-Barrelled Cannon"
	CLASS.ID 			= "SC"
	CLASS.Description 	= "#acf.descs.weapons.sc"
	CLASS.Model       	= "models/tankgun/tankgun_short_100mm.mdl"
	CLASS.Sound       	= "acf_base/weapons/cannon_new.mp3"
	CLASS.MuzzleFlash 	= "cannon_muzzleflash_noscale"
	CLASS.Spread      	= 0.16
	CLASS.Mass        	= 1195
	CLASS.ScaleFactor 	= 1.0 -- Corrective factor to account for improperly scaled base models
	CLASS.TransferMult 	= 4 -- Thermal energy transfer rate
	CLASS.Round 		= {
		MaxLength  = 80,
		PropLength = 65,
		Efficiency = 0.8,
	}
	CLASS.Preview 		= {
		Height = 70,
		FOV    = 60,
	}
	CLASS.CaliberLimits	= {
		Base = 100,
		Min  = 20,
		Max  = 170,
	}
	CLASS.Sounds 		= {
		[50] = "acf_base/weapons/ac_fire4.mp3",
	}
	CLASS.BreechConfigs = {
		MeasuredCaliber = 17.0,
		Locations = {
			{Name = "Breech", LPos = Vector(-40.8958, 0, 0.015625), LAng = Angle(0, 0, 0), Width = 6.6929133858268, Height = 6.6929133858268},
		}
	}
	CLASS.CostScalar	= 0.275
end)

ACF.SetCustomAttachment("models/tankgun/tankgun_short_100mm.mdl", "muzzle", Vector(82.86, -0.01), Angle(0, 0, 90))

ACF.AddHitboxes("models/tankgun/tankgun_short_100mm.mdl", {
	Breech = {
		Pos       = Vector(-14.19),
		Scale     = Vector(28.37, 12.83, 12.83),
		Sensitive = true
	},
	Barrel = {
		Pos   = Vector(41.21),
		Scale = Vector(82.41, 6.76, 6.76)
	}
})
