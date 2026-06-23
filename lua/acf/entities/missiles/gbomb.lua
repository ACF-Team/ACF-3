local Classes = ACF.Classes
Classes.DefineClass("ACF.Missiles.GlidingBomb", "ACF.Missiles.BaseMissile", function()
	CLASS.Name			= "Gliding Bombs"
	CLASS.ID			= "GBOMB"
	CLASS.Description	= "Similar to regular free falling bombs, gliding bombs are capable of travelling longer distances."
	CLASS.Sound			= "acf_missiles/fx/clunk.mp3"
	CLASS.NoThrust		= true
	CLASS.Spread		= 1
	CLASS.Blacklist		= { "ACF.Ammunition.AP", "ACF.Ammunition.APHE", "ACF.Ammunition.HP", "ACF.Ammunition.FL" }
	CLASS.LimitConVar	= {
		Name = "_acfm_gbomb",
		Amount = 8,
		Text = "Maximum number of gliding bombs that can be loaded at once. Differentiates from the acf_rack limit."
	}
end)

Classes.DefineClass("ACF.Missiles.GlidingBomb.100kg", "ACF.Missiles.GlidingBomb", function()
	CLASS.Name			= "100kg Glide Bomb"
	CLASS.Description	= "A 200-pound bomb, fitted with fins for a longer reach. Well suited to dive bombing, but bulkier and heavier from its fins."
	CLASS.Model			= "models/missiles/micro.mdl"
	CLASS.Length		= 100
	CLASS.Caliber		= 250
	CLASS.Mass			= 100
	CLASS.Year			= 1939
	CLASS.Diameter		= 10.8 * ACF.InchToMm -- in mm
	CLASS.ReloadTime	= 15
	CLASS.Racks			= { ["1xRK_small"] = true, ["1xRK"] = true, ["2xRK"] = true, ["3xRK"] = true, ["4xRK"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true }
	CLASS.Navigation	= "Chase"
	CLASS.Fuzes			= { Contact = true, Optical = true}
	CLASS.ArmDelay		= 1
	CLASS.Round			= {
		Model           	= "models/missiles/micro.mdl",
		MaxLength       	= 100,
		Armor           	= 2,
		ProjLength      	= 65,
		PropLength      	= 0,
		Thrust          	= 1, -- in kg*in/s^2
		FuelConsumption 	= 0.1, -- in g/s/f
		StarterPercent  	= 0.005,
		MaxAgilitySpeed 	= 1, -- in m/s
		DragCoef        	= 0.02,
		FinMul          	= 0.2,
		GLimit          	= 1,
		TailFinMul      	= 5,
		PenMul          	= 1,
		FillerRatio     	= 0.78,
		ActualLength    	= 100,
		ActualWidth     	= 25
	}
	CLASS.Preview		= {
		FOV = 65,
	}
end)

Classes.DefineClass("ACF.Missiles.GlidingBomb.250kg", "ACF.Missiles.GlidingBomb", function()
	CLASS.Name			= "250kg Glide Bomb"
	CLASS.Description	= "A heavy 500lb bomb, fitted with fins for a gliding trajectory better suited to striking point targets."
	CLASS.Model			= "models/missiles/fab250.mdl"
	CLASS.Length		= 150
	CLASS.Caliber		= 320
	CLASS.Mass			= 250
	CLASS.Year			= 1941
	CLASS.Diameter		= 14.5 * ACF.InchToMm -- in mm
	CLASS.ReloadTime	= 25
	CLASS.Racks			= { ["1xRK"] = true, ["2xRK"] = true, ["3xRK"] = true, ["4xRK"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true }
	CLASS.Navigation	= "Chase"
	CLASS.Fuzes			= { Contact = true, Optical = true}
	CLASS.ArmDelay		= 1
	CLASS.Round			= {
		Model           	= "models/missiles/fab250.mdl",
		MaxLength       	= 150,
		Armor           	= 2,
		ProjLength      	= 100,
		PropLength      	= 0,
		Thrust          	= 1, -- in kg*in/s^2
		FuelConsumption 	= 0.1, -- in g/s/f
		StarterPercent  	= 0.005,
		MaxAgilitySpeed 	= 1, -- in m/s
		DragCoef        	= 0.02,
		FinMul          	= 0.5,
		GLimit          	= 1,
		TailFinMul      	= 12,
		PenMul          	= 1,
		FillerRatio     	= 0.79,
		ActualLength    	= 150,
		ActualWidth     	= 32
	}
	CLASS.Preview		= {
		FOV = 70,
	}
end)