local ACF     = ACF

ACF.Classes.DefineClass("ACF.Guns.SemiautomaticCannon", "ACF.Guns.BaseScalableGun", function()
	CLASS.Name        	= "Semiautomatic Cannon"
	CLASS.ID 			= "SA"
	CLASS.IsWeapon		= true
	CLASS.Description 	= "#acf.descs.weapons.sa"
	CLASS.Model       	= "models/autocannon/semiautocannon_45mm.mdl"
	CLASS.Sound       	= "acf_base/weapons/sa_fire1.mp3"
	CLASS.MuzzleFlash 	= "semi_muzzleflash_noscale"
	CLASS.IsBoxed     	= true
	CLASS.Spread      	= 0.12
	CLASS.Mass        	= 453
	CLASS.MagSize     	= 5
	CLASS.ScaleFactor 	= 1.0 -- Corrective factor to account for improperly scaled base models
	CLASS.ReloadMod 	= 0.5 -- Load time multiplier. Represents the ease of manipulating the weapon's ammunition
	CLASS.TransferMult 	= 4 -- Thermal energy transfer rate
	CLASS.Round = {
		MaxLength  		= 36,
		PropLength 		= 29.25,
	}
	CLASS.Preview 		= {
		FOV = 70,
	}
	CLASS.CaliberLimits	= {
		Base = 45,
		Min  = 20,
		Max  = 76,
	}
	CLASS.MagReload 	= {
		Min = 3,
		Max = 10,
	}
	CLASS.Cyclic 		= {
		Min = 240,
		Max = 100,
	}
	CLASS.BreechConfigs = {
		MeasuredCaliber = 7.6,
		Locations = {
			{Name = "Vertical Magazine", LPos = Vector(18.8166, -0, 12.2373), LAng = Angle(0, 0, 0), Width = 5.0628, Height = 16.6836},
			{Name = "Horizontal Magazine", LPos = Vector(18.8166, -13.6, 0), LAng = Angle(0, 0, 0), Width = 17.563, Height = 5.563},
		}
	}
	CLASS.CostScalar	= 0.55
end)

ACF.SetCustomAttachment("models/autocannon/semiautocannon_45mm.mdl", "muzzle", Vector(79.2), Angle(0, 0, 180))

ACF.AddHitboxes("models/autocannon/semiautocannon_45mm.mdl", {
	Breech = {
		Pos       = Vector(-1.35, 0, 0.45),
		Scale     = Vector(37.8, 12.6, 6.75),
		Sensitive = true
	},
	Barrel = {
		Pos   = Vector(48.15),
		Scale = Vector(62.1, 3.6, 3.6)
	}
})
