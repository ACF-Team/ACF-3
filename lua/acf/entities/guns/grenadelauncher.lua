local ACF     = ACF

ACF.Classes.DefineClass("ACF.Guns.GrenadeLauncher", "ACF.Guns.BaseScalableGun", function(CLASS)
	CLASS.Name       		= "Grenade Launcher"
	CLASS.ID				= "GL"
	CLASS.IsWeapon			= true
	CLASS.Description 		= "#acf.descs.weapons.gl"
	CLASS.Sound       		= "acf_base/weapons/grenadelauncher.mp3"
	CLASS.Model       		= "models/launcher/40mmgl.mdl"
	CLASS.MuzzleFlash 		= "gl_muzzleflash_noscale"
	CLASS.DefaultAmmo 		= "ACF.Ammunition.HE"
	CLASS.IsBelted			= true
	CLASS.IsAutomatic 		= true
	CLASS.Mass				= 101
	CLASS.Spread      		= 0.28
	CLASS.Cyclic      		= 250
	CLASS.ScaleFactor 		= 0.96 -- Corrective factor to account for improperly scaled base models
	CLASS.CyclicCeilMult 	= 2 -- How high above base cyclic the gun can be set to
	CLASS.Round 			= {
		MaxLength  = 10,
		PropLength = 1,
		CaseScale  = 1, -- Straight-walled, case diameter is roughly the projectile diameter
	}
	CLASS.Preview 			= {
		FOV = 75,
	}
	CLASS.Caliber			= {
		Base = 40,
		Min  = 25,
		Max  = 40,
	}
	CLASS.LimitConVar 		= {
		Name = "_acf_grenadelauncher",
		Amount = 4,
		Text = "Maximum amount of ACF grenade launchers a player can create."
	}
	CLASS.CostScalar		= 0.38
end)

ACF.SetCustomAttachment("models/launcher/40mmgl.mdl", "muzzle", Vector(19), Angle(0, 0, -180))

ACF.AddHitboxes("models/launcher/40mmgl.mdl", {
	Breech = {
		Pos       = Vector(0, 0, -1.25),
		Scale     = Vector(20, 5, 6),
		Sensitive = true
	},
	Barrel = {
		Pos   = Vector(14, 0, 0.1),
		Scale = Vector(12, 2, 2)
	}
})
