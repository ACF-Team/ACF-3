local Classes = ACF.Classes
Classes.DefineClass("ACF.Missiles.AirToAir", "ACF.Missiles.BaseMissile", function()
	CLASS.Name			= "Air-To-Air Missiles"
	CLASS.ID 			= "AAM"
	CLASS.Description	= "Missiles specialized for air-to-air flight. They have varying range, but are agile, can be radar-guided, and withstand difficult launch angles well."
	CLASS.Sound			= "acf_missiles/missiles/missile_rocket.mp3"
	CLASS.Effect		= "Rocket Motor"
	CLASS.Spread		= 1
	CLASS.Blacklist		= { "ACF.Ammunition.AP", "ACF.Ammunition.APHE", "ACF.Ammunition.HEAT", "ACF.Ammunition.HP", "ACF.Ammunition.FL", "ACF.Ammunition.SM" }
	CLASS.LimitConVar 	= {
		Name = "_acfm_aam",
		Amount = 8,
		Text = "Maximum number of air-to-air missiles that can be loaded at once. Differentiates from the acf_rack limit."
	}
end)

Classes.DefineClass("ACF.Missiles.AirToAir.AIM-9", "ACF.Missiles.AirToAir", function()
	CLASS.Name			= "AIM-9 Sidewinder"
	CLASS.Description	= "Agile and reliable with a rather underwhelming effective range, this homing missile is the weapon of choice for dogfights."
	CLASS.Model			= "models/missiles/aim9m.mdl"
	CLASS.Length		= 289
	CLASS.Caliber		= 127
	CLASS.Mass			= 85
	CLASS.Year			= 1953
	CLASS.Diameter		= 101.6 -- in mm
	CLASS.ReloadTime	= 10
	CLASS.ExhaustPos  	= Vector(-42)
	CLASS.Racks			= { ["ACF.Racks.1xRK_small"] = true, ["ACF.Racks.1xRK"] = true, ["ACF.Racks.2xRK"] = true, ["ACF.Racks.4xRK"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true, ["ACF.Missiles.Guidance.Infrared"] = true, ["ACF.Missiles.Guidance.SemiActiveRadar"] = true }
	CLASS.Navigation  	= "APN"
	CLASS.Fuzes			= { Contact = true, Radio = true }
	CLASS.SeekCone		= 10
	CLASS.ViewCone		= 30
	CLASS.Agility		= 0.0017
	CLASS.ArmDelay		= 0.2
	CLASS.Round 		= {
		Model           	= "models/missiles/aim9m.mdl",
		MaxLength       	= 289,
		ProjLength      	= 68,
		Armor           	= 1,
		PropLength      	= 160,
		Thrust          	= 800000, -- in kg*in/s^2
		FuelConsumption 	= 0.02, -- in g/s/f
		StarterPercent  	= 0.05,
		MaxAgilitySpeed 	= 300, -- in m/s
		DragCoef        	= 0.005,
		FinMul          	= 0.1,
		GLimit          	= 20,
		TailFinMul      	= 0.001,
		CanDelayLaunch  	= true,
		ActualLength    	= 119,
		ActualWidth     	= 18
	}
	Preview 			= {
		Height = 100,
		FOV    = 60,
	}
end)

Classes.DefineClass("ACF.Missiles.AirToAir.AIM-120", "ACF.Missiles.AirToAir", function()
	CLASS.Name			= "AIM-120 AMRAAM"
	CLASS.Description	= "Burns hot and fast, with a good reach, but harder to lock with. This long-range missile is sure to deliver one heck of a blast upon impact."
	CLASS.Model			= "models/missiles/aim120c.mdl"
	CLASS.Length		= 370
	CLASS.Caliber		= 180
	CLASS.Mass			= 152
	CLASS.Year			= 1991
	CLASS.Diameter		= 154.5 -- in mm
	CLASS.ReloadTime	= 25
	CLASS.ExhaustPos  	= Vector(-66)
	CLASS.Racks			= { ["ACF.Racks.1xRK"] = true, ["ACF.Racks.2xRK"] = true, ["ACF.Racks.4xRK"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true, ["ACF.Missiles.Guidance.SemiActiveRadar"] = true, ["ACF.Missiles.Guidance.ActiveRadar"] = true }
	CLASS.Navigation  	= "APN"
	CLASS.Fuzes			= { Contact = true, Radio = true }
	CLASS.SeekCone		= 10
	CLASS.ViewCone		= 30
	CLASS.Agility		= 0.006
	CLASS.ArmDelay		= 0.2
	CLASS.Round 		= {
		Model           	= "models/missiles/aim120c.mdl",
		MaxLength       	= 370,
		Armor           	= 1,
		ProjLength      	= 70,
		PropLength      	= 200,
		Thrust          	= 1500000, -- in kg*in/s^2
		FuelConsumption 	= 0.02, -- in g/s/f
		StarterPercent  	= 0.05,
		MaxAgilitySpeed 	= 350, -- in m/s
		DragCoef        	= 0.01,
		FinMul          	= 0.2,
		GLimit          	= 20,
		TailFinMul      	= 0.001,
		CanDelayLaunch  	= true,
		ActualLength    	= 144,
		ActualWidth     	= 15
	}
	Preview 			= {
		Height = 60,
		FOV    = 60,
	}
end)

Classes.DefineClass("ACF.Missiles.AirToAir.AIM-7", "ACF.Missiles.AirToAir", function()
	CLASS.Name        	= "AIM-7 Sparrow"
	CLASS.Description 	= "This well-aged early BVR missile has been worn on the hip of every raging fighter since '53. But don't be mislead, this ain't your granddaddy's Sparrow"
	CLASS.Model       	= "models/missiles/aim7f.mdl"
	CLASS.Length      	= 370
	CLASS.Caliber     	= 200
	CLASS.Mass        	= 231
	CLASS.Year        	= 1953
	CLASS.Diameter    	= 203.2 -- in mm
	CLASS.ReloadTime  	= 28
	CLASS.ExhaustPos  	= Vector(-70)
	CLASS.Racks       	= { ["ACF.Racks.1xRK"] = true, ["ACF.Racks.2xRK"] = true }
	CLASS.Guidance    	= { ["ACF.Missiles.Guidance.Dumb"] = true, ["ACF.Missiles.Guidance.SemiActiveRadar"] = true, ["ACF.Missiles.Guidance.RadioMCLOS"] = true }
	CLASS.Navigation  	= "APN"
	CLASS.Fuzes       	= { Contact = true, Radio = true }
	CLASS.SeekCone    	= 10
	CLASS.ViewCone    	= 20
	CLASS.Agility     	= 0.02
	CLASS.ArmDelay    	= 0.3
	CLASS.Round 		= {
		Model           	= "models/missiles/aim7f.mdl",
		MaxLength       	= 370,
		Armor           	= 1,
		ProjLength      	= 70,
		PropLength      	= 200,
		Thrust          	= 3000000, -- in kg*in/s^2
		FuelConsumption 	= 0.03, -- in g/s/f
		StarterPercent  	= 0.05,
		MaxAgilitySpeed 	= 300, -- in m/s
		DragCoef        	= 0.02,
		FinMul          	= 0.25,
		GLimit          	= 12,
		TailFinMul      	= 0.001,
		CanDelayLaunch  	= true,
		ActualLength    	= 144,
		ActualWidth     	= 29
	}
	CLASS.Preview 		= {
		Height = 100,
		FOV    = 60,
	}
end)

Classes.DefineClass("ACF.Missiles.AirToAir.AIM-54", "ACF.Missiles.AirToAir", function()
	CLASS.Name			= "AIM-54 Phoenix"
	CLASS.Description	= "A BEEFY god-tier anti-bomber weapon, made with Jimmy Carter's repressed rage. Getting hit with one of these is a significant emotional event that is hard to avoid if you're flying high."
	CLASS.Model			= "models/missiles/aim54a.mdl"
	CLASS.Length		= 400
	CLASS.Caliber		= 380
	CLASS.Mass			= 453
	CLASS.Year			= 1974
	CLASS.Diameter		= 330 -- in mm
	CLASS.ReloadTime	= 40
	CLASS.ExhaustPos  	= Vector(-60)
	CLASS.Racks			= { ["ACF.Racks.1xRK"] = true, ["ACF.Racks.2xRK"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true, ["ACF.Missiles.Guidance.SemiActiveRadar"] = true, ["ACF.Missiles.Guidance.ActiveRadar"] = true }
	CLASS.Navigation  	= "APN"
	CLASS.Fuzes			= { Contact = true, Radio = true }
	CLASS.SeekCone		= 10
	CLASS.ViewCone		= 20
	CLASS.Agility		= 0.02
	CLASS.ArmDelay		= 0.4
	CLASS.Round 		= {
		Model           	= "models/missiles/aim54a.mdl",
		MaxLength       	= 400,
		Armor           	= 1,
		ProjLength      	= 60,
		PropLength      	= 220,
		Thrust          	= 4000000, -- in kg*in/s^2
		FuelConsumption 	= 0.04, -- in g/s/f
		StarterPercent  	= 0.05,
		MaxAgilitySpeed 	= 300, -- in m/s
		DragCoef        	= 0.03,
		FinMul          	= 0.3,
		GLimit          	= 12,
		TailFinMul      	= 0.001,
		CanDelayLaunch  	= true,
		ActualLength    	= 156,
		ActualWidth     	= 26
	}
	CLASS.Preview 		= {
		Height = 100,
		FOV    = 60,
	}
end)