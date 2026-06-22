local Classes = ACF.Classes
Classes.DefineClass("ACF.Missiles.SurfaceToAir", "ACF.Missiles.BaseMissile", function()
	CLASS.Name			= "Surface-To-Air Missiles"
	CLASS.ID			= "SAM"
	CLASS.Description	= "Missiles specialized for surface-to-air operation, and well suited to lower altitude operation against ground attack aircraft."
	CLASS.Sound			= "acf_missiles/missiles/missile_rocket.mp3"
	CLASS.Effect		= "Rocket Motor"
	CLASS.Spread		= 1
	CLASS.Blacklist		= { "AP", "APHE", "HEAT", "HP", "FL", "SM" }
	CLASS.LimitConVar	= {
		Name = "_acfm_sam",
		Amount = 8,
		Text = "Maximum number of surface-to-air missiles that can be loaded at once. Differentiates from the acf_rack limit."
	}
end)

Classes.DefineClass("ACF.Missiles.SurfaceToAir.FIM-92", "ACF.Missiles.SurfaceToAir", function()
	CLASS.Name			= "FIM-92 Stinger"
	CLASS.Description	= "The FIM-92 Stinger is a lightweight and versatile close-range air defense missile."
	CLASS.Model			= "models/missiles/fim_92.mdl"
	CLASS.Length		= 152
	CLASS.Caliber		= 70
	CLASS.Mass			= 10
	CLASS.Year			= 1978
	CLASS.ReloadTime	= 10
	CLASS.ExhaustPos	= Vector(-29)
	CLASS.Racks			= { ["1x FIM-92"] = true, ["2x FIM-92"] = true, ["4x FIM-92"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true, ["ACF.Missiles.Guidance.Infrared"] = true, ["Anti-missile"] = true }
	CLASS.Navigation	= "PN"
	CLASS.Fuzes			= { Contact = true, Radio = true }
	CLASS.SeekCone		= 7.5
	CLASS.ViewCone		= 30
	CLASS.Agility		= 0.0002
	CLASS.ArmDelay		= 0.2
	CLASS.Round			= {
		Model           	= "models/missiles/fim_92.mdl",
		RackModel       	= "models/missiles/fim_92_folded.mdl",
		MaxLength       	= 152,
		Armor           	= 1,
		ProjLength      	= 60,
		PropLength      	= 80,
		Thrust          	= 200000, -- in kg*in/s^2
		FuelConsumption 	= 0.012, -- in g/s/f
		StarterPercent  	= 0.1,
		MaxAgilitySpeed 	= 200, -- in m/s
		DragCoef        	= 0.0015,
		FinMul          	= 0.03,
		GLimit          	= 20,
		TailFinMul      	= 0.001,
		ActualLength    	= 60,
		ActualWidth     	= 5
	}
	CLASS.Preview		= {
		Height = 80,
		FOV    = 60,
	}
end)

Classes.DefineClass("ACF.Missiles.SurfaceToAir.Strela-1", "ACF.Missiles.SurfaceToAir", function()
	CLASS.Name			= "9M31 Strela-1"
	CLASS.Description	= "The 9M31 Strela-1 (SA-9 Gaskin) is a medium-range homing SAM, best suited to ground vehicles or stationary units."
	CLASS.Model			= "models/missiles/9m31.mdl"
	CLASS.Length		= 180
	CLASS.Caliber		= 120
	CLASS.Mass			= 30
	CLASS.Year			= 1960
	CLASS.ReloadTime	= 25
	CLASS.ExhaustPos	= Vector(-44)
	CLASS.Racks			= { ["1x Strela-1"] = true, ["2x Strela-1"] = true, ["4x Strela-1"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true, ["ACF.Missiles.Guidance.Infrared"] = true, ["Anti-missile"] = true }
	CLASS.Navigation	= "APN"
	CLASS.Fuzes			= { Contact = true, Radio = true }
	CLASS.SeekCone		= 20
	CLASS.ViewCone		= 40
	CLASS.Agility		= 0.0006
	CLASS.ArmDelay		= 0.2
	CLASS.Round			= {
		Model           	= "models/missiles/9m31.mdl",
		RackModel       	= "models/missiles/9m31f.mdl",
		IgnoreRackModel 	= true, -- Ignore the rack model when determining the size of the round for ammo crates
		MaxLength       	= 180,
		Armor           	= 1,
		ProjLength      	= 60,
		PropLength      	= 100,
		Thrust          	= 800000, -- in kg*in/s^2
		FuelConsumption 	= 0.018, -- in g/s/f
		StarterPercent  	= 0.1,
		MaxAgilitySpeed 	= 300, -- in m/s
		DragCoef        	= 0.003,
		FinMul          	= 0.04,
		GLimit          	= 20,
		TailFinMul      	= 0.001,
		ActualLength    	= 71,
		ActualWidth     	= 5
	}
	CLASS.Preview		= {
		Height = 60,
		FOV    = 60,
	}
end)