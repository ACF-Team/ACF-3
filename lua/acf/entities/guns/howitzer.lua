local ACF     = ACF

ACF.Classes.DefineClass("ACF.Guns.Howitzer", "ACF.Guns.BaseScalableGun", function()
	CLASS.Name        	= "Howitzer"
	CLASS.ID 			= "HW"
	CLASS.IsWeapon		= true
	CLASS.Description 	= "#acf.descs.weapons.hw"
	CLASS.Sound       	= "acf_base/weapons/howitzer_new2.mp3"
	CLASS.Model       	= "models/howitzer/howitzer_105mm.mdl"
	CLASS.MuzzleFlash 	= "howie_muzzleflash_noscale"
	CLASS.Mass        	= 860
	CLASS.Spread      	= 0.1
	CLASS.ScaleFactor 	= 0.84 -- Corrective factor to account for improperly scaled base models
	CLASS.TransferMult 	= 4 -- Thermal energy transfer rate
	CLASS.Round 		= {
		MaxLength  = 90,
		PropLength = 90,
		Efficiency = 0.65,
	}
	CLASS.Preview 		= {
		FOV = 65,
	}
	CLASS.CaliberLimits	= {
		Base = 105,
		Min  = 75,
		Max  = 203,
	}
	CLASS.BreechConfigs = {
		MeasuredCaliber = 20.3,
		Locations = {
			{Name = "Breech", LPos = Vector(-47.538, 0, -1.35938), LAng = Angle(0, 0, 0), Width = 7.992125984252, Height = 7.992125984252},
		}
	}
	CLASS.CostScalar	= 0.5
end)

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
