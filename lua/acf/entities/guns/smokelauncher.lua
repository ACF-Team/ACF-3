local ACF     = ACF

ACF.Classes.DefineClass("ACF.Guns.SmokeLauncher", "ACF.Guns.BaseScalableGun", function()
	CLASS.Name        	= "Smoke Launcher"
	CLASS.ID 			= "SL"
	CLASS.Description 	= "#acf.descs.weapons.sl"
	CLASS.Sound       	= "acf_base/weapons/smoke_launch.mp3"
	CLASS.Model       	= "models/launcher/40mmsl.mdl"
	CLASS.MuzzleFlash 	= "gl_muzzleflash_noscale"
	CLASS.Cleanup     	= "acf_smokelauncher"
	CLASS.DefaultAmmo 	= "ACF.Ammunition.SM"
	CLASS.IsBoxed     	= true
	CLASS.Spread      	= 0.32
	CLASS.Mass        	= 3.77
	CLASS.Cyclic      	= 600
	CLASS.MagSize     	= 1
	CLASS.ScaleFactor 	= 0.96 -- Corrective factor to account for improperly scaled base models
	CLASS.TransferMult 	= 4 -- Thermal energy transfer rate
	CLASS.LimitConVar 	= {
		Name = "_acf_smokelauncher",
		Amount = 10,
		Text = "Maximum amount of ACF smoke launchers a player can create."
	}
	CLASS.Round 		= {
		MaxLength  = 17.5,
		PropLength = 0.05,
	}
	CLASS.Preview 		= {
		FOV = 75,
	}
	CLASS.CaliberLimits	= {
		Base = 40,
		Min  = 40,
		Max  = 81,
	}
	CLASS.MagReload 	= {
		Min = 10,
		Max = 15,
	}
	CLASS.BreechConfigs = {
		MeasuredCaliber = 8.1,
		Locations = {
			{Name = "Breech", LPos = Vector(-7.09631, 0, -0.180664), LAng = Angle(0, 0, 0), Width = 3.1889763779528, Height = 3.1889763779528},
			{Name = "Barrel", LPos = Vector(9.8606, 0, -0.182617), LAng = Angle(180, 0, 0), Width = 3.1889763779528, Height = 3.1889763779528},
		}
	}
	CLASS.CostScalar	= 0.02
end)

ACF.SetCustomAttachment("models/launcher/40mmsl.mdl", "muzzle", Vector(5), Angle(0, 0, 180))

ACF.AddHitboxes("models/launcher/40mmsl.mdl", {
	Base = {
		Pos   = Vector(0.7, 0, -0.1),
		Scale = Vector(8, 3, 2)
	}
})
