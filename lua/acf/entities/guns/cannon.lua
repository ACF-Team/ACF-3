local ACF = ACF

ACF.Classes.DefineClass("ACF.Guns.Cannon", "ACF.Guns.BaseScalableGun", function(CLASS)
	CLASS.Name        	= "Cannon"
	CLASS.ID		  	= "C"
	CLASS.IsWeapon		= true
	CLASS.Description 	= "#acf.descs.weapons.c"
	CLASS.Model       	= "models/tankgun_new/tankgun_100mm.mdl"
	CLASS.MassCenter    = Vector(0, 0, 0)
	CLASS.Sound       	= "acf_base/weapons/cannon_new.mp3"
	CLASS.MuzzleFlash 	= "cannon_muzzleflash_noscale"
	CLASS.Mass        	= 1229
	CLASS.Spread      	= 0.08
	CLASS.ScaleFactor 	= 0.84 -- Corrective factor to account for improperly scaled base models
	CLASS.Round 		= {
		-- 80 was short enough that real case lengths at this scale (76.2mm M62, 90mm M77/M82, 37mm M51,
		-- 155mm T43) exceeded the slider ceiling by 7.8-16.8%; 95 covers all of them with some headroom.
		-- PropLength keeps the same ~0.62 ratio to MaxLength so the default propellant fraction is unchanged.
		MaxLength  = 95,
		PropLength = 59,
		CaseScale  = 1.33, -- 120x570mm (M256): 160mm case over a 120mm projectile
	}
	CLASS.Preview 		= {
		Height = 50,
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
			{Name = "Breech", LPos = Vector(-58.9363, 0, 0), LAng = Angle(0, 0, 0), Width = 6.6929133858268, Height = 6.6929133858268},
		}
	}
	CLASS.CostScalar	= 0.48
end)

ACF.SetCustomAttachment("models/tankgun_new/tankgun_100mm.mdl", "muzzle", Vector(175), Angle(0, 0, 90))

ACF.AddHitboxes("models/tankgun_new/tankgun_100mm.mdl", {
	Breech = {
		Pos       = Vector(-13),
		Scale     = Vector(36, 12.5, 12.5),
		Sensitive = true
	},
	Barrel = {
		Pos   = Vector(90),
		Scale = Vector(170, 7.5, 7.5)
	}
})
