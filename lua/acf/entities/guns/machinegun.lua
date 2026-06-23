local ACF     = ACF

ACF.Classes.DefineClass("ACF.Guns.Machinegun", "ACF.Guns.BaseScalableGun", function()
	CLASS.Name        		= "Machinegun"
	CLASS.ID		  		= "MG"
	CLASS.IsWeapon			= true
	CLASS.Description 		= "#acf.descs.weapons.mg"
	CLASS.Model       		= "models/machinegun/machinegun_20mm.mdl"
	CLASS.Sound       		= "acf_base/weapons/mg_fire4.mp3"
	CLASS.MuzzleFlash 		= "mg_muzzleflash_noscale"
	CLASS.IsAutomatic 		= true
	CLASS.IsBelted			= true
	CLASS.Spread      		= 0.16
	CLASS.Mass        		= 53
	CLASS.ScaleFactor 		= 1.0 -- Corrective factor to account for improperly scaled base models
	CLASS.TransferMult 		= 20 -- Thermal energy transfer rate
	CLASS.CyclicCeilMult 	= 2 -- How high above base cyclic the gun can be set to
	CLASS.Round 			= {
		MaxLength  = 16,
		PropLength = 13,
	}
	CLASS.Preview 			= {
		Height = 60,
		FOV    = 60,
	}
	CLASS.CaliberLimits		= {
		Base = 20,
		Min  = 5.56,
		Max  = 20,
	}
	CLASS.MagSize 			= {
		Min = 400,
		Max = 100,
	}
	CLASS.MagReload 		= {
		Min = 5,
		Max = 12,
	}
	CLASS.Cyclic 			= {
		Min = 900,
		Max = 600,
	}
	CLASS.LimitConVar 		= {
		Name = "_acf_machinegun",
		Amount = 4,
		Text = "Maximum amount of ACF machine guns a player can create."
	}
	CLASS.CostScalar		= 0.25
end)

ACF.SetCustomAttachment("models/machinegun/machinegun_20mm.mdl", "muzzle", Vector(53.05, 0, -0.11), Angle(0, 0, 90))

ACF.AddHitboxes("models/machinegun/machinegun_20mm.mdl", {
	Base = {
		Pos   = Vector(20.1, 0.2, -1.5),
		Scale = Vector(68, 2, 6),
	}
})
