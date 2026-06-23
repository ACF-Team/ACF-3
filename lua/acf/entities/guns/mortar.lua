local ACF     = ACF
ACF.Classes.DefineClass("ACF.Guns.Mortar", "ACF.Guns.BaseScalableGun", function()
	CLASS.Name        	= "Mortar"
	CLASS.ID 			= "MO"
	CLASS.Description 	= "#acf.descs.weapons.mo"
	CLASS.Sound       	= "acf_base/weapons/mortar_new.mp3"
	CLASS.Model			= "models/mortar/mortar_120mm.mdl"
	CLASS.MuzzleFlash 	= "mortar_muzzleflash_noscale"
	CLASS.DefaultAmmo 	= "ACF.Ammunition.HE"
	CLASS.Spread      	= 0.72
	CLASS.Mass        	= 459
	CLASS.ScaleFactor 	= 0.84 -- Corrective factor to account for improperly scaled base models
	CLASS.TransferMult 	= 4 -- Thermal energy transfer rate
	CLASS.Round = {
		MaxLength  = 40,
		PropLength = 3,
	}
	CLASS.Preview 		= {
		Height = 80,
		FOV    = 65,
	}
	CLASS.CaliberLimits	= {
		Base = 120,
		Min  = 37,
		Max  = 280,
	}
	CLASS.BreechConfigs = {
		MeasuredCaliber = 28.0,
		Locations = {
			{Name = "Breech", LPos = Vector(-97.4919, 0, 0.015625), LAng = Angle(0, 0, 0), Width = 11.023622047244, Height = 11.023622047244},
			{Name = "Barrel", LPos = Vector(37.0706, 0, 0.015625), LAng = Angle(180, 0, 0), Width = 11.023622047244, Height = 11.023622047244},
		}
	}
	CLASS.CostScalar	= 0.35
end)

ACF.SetCustomAttachment("models/mortar/mortar_120mm.mdl", "muzzle", Vector(24.02), Angle(0, 0, 90))

ACF.AddHitboxes("models/mortar/mortar_120mm.mdl", {
	Base = {
		Pos   = Vector(-15.4, 0.3),
		Scale = Vector(69, 10, 9)
	}
})
