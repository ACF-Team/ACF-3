local ACF = ACF

ACF.Classes.DefineClass("ACF.Guns.Autocannon", "ACF.Guns.BaseScalableGun", function()
	CLASS.Name        		= "Autocannon"
	Class.ID		 	 	= "AC"
	CLASS.Description 		= "#acf.descs.weapons.ac"
	CLASS.Model       		= "models/autocannon/autocannon_50mm.mdl"
	CLASS.Sound       		= "acf_base/weapons/ac_fire4.mp3"
	CLASS.MuzzleFlash 		= "auto_muzzleflash_noscale"
	CLASS.IsAutomatic 		= true
	CLASS.IsBelted			= true
	CLASS.Mass        		= 1953 -- Relative to the model's volume
	CLASS.Spread      		= 0.2
	CLASS.ScaleFactor 		= 0.86 -- Corrective factor to account for improperly scaled base models
	CLASS.ReloadMod 		= 0.5 -- Load time multiplier. Represents the ease of manipulating the weapon's ammunition
	CLASS.TransferMult 		= 20 -- Thermal energy transfer rate
	CLASS.CyclicCeilMult 	= 2 -- How high above base cyclic the gun can be set to
	CLASS.Round 			= {
		MaxLength  = 40, -- Relative to the Base caliber, in cm
		PropLength = 32.5, -- Relative to the Base caliber, in cm
	}
	CLASS.Preview			= {
		Height = 80,
		FOV    = 60,
	}
	CLASS.CaliberLimits		= {
		Base = 50,
		Min  = 20,
		Max  = 60,
	}
	CLASS.MagSize 			= {
		Min = 500,
		Max = 200,
	}
	CLASS.MagReload 		= {
		Min = 10,
		Max = 20,
	}
	CLASS.Cyclic 			= {
		Min = 250,
		Max = 150,
	}
	CLASS.LimitConVar 		= {
		Name = "_acf_autocannon",
		Amount = 4,
		Text = "Maximum amount of ACF auto cannons a player can create."
	}
	CLASS.CostScalar		= 0.75
end)

ACF.SetCustomAttachment("models/autocannon/autocannon_50mm.mdl", "muzzle", Vector(120), Angle(0, 0, 180))

ACF.AddHitboxes("models/autocannon/autocannon_50mm.mdl", {
	Breech = {
		Pos       = Vector(-3, 0, -1.6),
		Scale     = Vector(52, 15, 19),
		Sensitive = true,
	},
	Barrel = {
		Pos   = Vector(65),
		Scale = Vector(83, 5, 5),
	}
})
