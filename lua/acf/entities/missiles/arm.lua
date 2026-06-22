local Classes = ACF.Classes
Classes.DefineClass("ACF.Missiles.AntiRadiation", "ACF.Missiles.BaseMissile", function()
	CLASS.Name			= "Anti-Radiation Missiles"
	CLASS.ID 			= "ARM"
	CLASS.Description	= "Missiles specialized for Suppression of Enemy Air Defenses."
	CLASS.Sound			= "acf_missiles/missiles/missile_rocket.mp3"
	CLASS.Effect		= "Rocket Motor ATGM"
	CLASS.Spread		= 1
	CLASS.Blacklist		= { "AP", "APHE", "HP", "FL", "SM" }
	CLASS.LimitConVar 	= {
		Name = "_acfm_arm",
		Amount = 8,
		Text = "Maximum number of anti-radiation missiles that can be loaded at once. Differentiates from the acf_rack limit."
	}
end)

Classes.DefineClass("ACF.Missiles.AntiRadiation.AGM-122", "ACF.Missiles.AntiRadiation", function()
	CLASS.Name			= "AGM-122 Sidearm"
	CLASS.Description	= "A refurbished early-model AIM-9, for attacking ground targets."
	CLASS.Model			= "models/missiles/aim9.mdl"
	CLASS.Length		= 287
	CLASS.Caliber		= 127
	CLASS.Mass			= 89
	CLASS.Diameter		= 3.5 * ACF.InchToMm -- in mm
	CLASS.Offset		= Vector(-6, 0, 0)
	CLASS.Year			= 1986
	CLASS.ReloadTime	= 10
	CLASS.ExhaustPos  	= Vector(-30)
	CLASS.Racks			= { ["1xRK_small"] = true, ["1xRK"] = true, ["2xRK"] = true, ["4xRK"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true, ["ACF.Missiles.Guidance.AntiRadiation"] = true }
	CLASS.Navigation  	= "Chase"
	CLASS.Fuzes			= { Contact = true, Optical = true }
	CLASS.SeekCone		= 10
	CLASS.ViewCone		= 20
	CLASS.Agility		= 0.0018
	CLASS.ArmDelay		= 0.2
	CLASS.Round 		= {
		Model           	= "models/missiles/aim9.mdl",
		MaxLength       	= 287,
		Armor           	= 1,
		ProjLength      	= 68,
		PropLength      	= 160,
		Thrust          	= 800000, -- in kg*in/s^2
		FuelConsumption 	= 0.02, -- in g/s/f
		StarterPercent  	= 0.05,
		MaxAgilitySpeed 	= 350, -- in m/s
		DragCoef        	= 0.015,
		FinMul          	= 0.1,
		GLimit          	= 20,
		TailFinMul      	= 0.001,
		CanDelayLaunch  	= true,
		ActualLength    	= 113,
		ActualWidth     	= 18
	}
	CLASS.Preview 		= {
		FOV = 60,
	}
end)

Classes.DefineClass("ACF.Missiles.AntiRadiation.AGM-45", "ACF.Missiles.AntiRadiation", function()
	CLASS.Name		= "AGM-45 Shrike"
	CLASS.Description	= "Long range anti-SAM missile, built on the body of an AIM-7 Sparrow."
	CLASS.Model		= "models/missiles/aim120.mdl"
	CLASS.Length		= 305
	CLASS.Caliber		= 203
	CLASS.Mass		= 177
	CLASS.Diameter	= 6.75 * ACF.InchToMm -- in mm
	CLASS.Year		= 1969
	CLASS.ReloadTime	= 25
	CLASS.ExhaustPos  = Vector(-70)
	CLASS.Racks		= { ["1xRK"] = true, ["2xRK"] = true, ["4xRK"] = true }
	CLASS.Guidance	= { ["ACF.Missiles.Guidance.Dumb"] = true, ["ACF.Missiles.Guidance.AntiRadiation"] = true }
	CLASS.Navigation  = "Chase"
	CLASS.Fuzes		= { Contact = true, Timed = true }
	CLASS.SeekCone	= 5
	CLASS.ViewCone	= 10
	CLASS.Agility		= 0.012
	CLASS.ArmDelay	= 0.3
	CLASS.Round = {
		Model           	= "models/missiles/aim120.mdl",
		MaxLength       	= 305,
		Armor           	= 1,
		ProjLength      	= 70,
		PropLength      	= 200,
		Thrust          	= 1500000, -- in kg*in/s^2
		FuelConsumption 	= 0.020, -- in g/s/f
		StarterPercent  	= 0.05,
		MaxAgilitySpeed 	= 350, -- in m/s
		DragCoef        	= 0.02,
		FinMul          	= 0.2,
		GLimit          	= 20,
		TailFinMul      	= 0.001,
		CanDelayLaunch  	= true,
		ActualLength    	= 120,
		ActualWidth     	= 26
	}
	Preview = {
		Height = 80,
		FOV    = 60,
	}
end)