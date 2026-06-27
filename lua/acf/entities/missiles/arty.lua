local Classes = ACF.Classes
Classes.DefineClass("ACF.Missiles.Artillery", "ACF.Missiles.BaseMissile", function()
	CLASS.Name			= "Artillery Rockets"
	CLASS.ID 			= "ARTY"
	CLASS.Description	= "Artillery rockets provide massive HE delivery over a broad area, with arcing ballistic trajectories and limited guidance."
	CLASS.Sound			= "acf_missiles/missiles/missile_rocket.mp3"
	CLASS.Effect		= "Rocket Motor"
	CLASS.Spread		= 1
	CLASS.Blacklist		= { "ACF.Ammunition.AP", "ACF.Ammunition.APHE", "ACF.Ammunition.HP", "ACF.Ammunition.FL", "ACF.Ammunition.SM" }
	CLASS.LimitConVar 	= {
		Name = "_acfm_arty",
		Amount = 12,
		Text = "Maximum number of artillery rockets that can be loaded at once. Differentiates from the acf_rack limit."
	}
end)

Classes.DefineClass("ACF.Missiles.Artillery.Type63", "ACF.Missiles.Artillery", function()
	CLASS.Name			= "Type 63 Rocket"
	CLASS.Description	= "A common artillery rocket in the third world, able to be launched from a variety of platforms with a painful whallop and a very arced trajectory."
	CLASS.Model			= "models/missiles/glatgm/mgm51.mdl"
	CLASS.Caliber		= 107
	CLASS.Mass			= 19
	CLASS.Length		= 80
	CLASS.Year			= 1960
	CLASS.ReloadTime	= 10
	CLASS.ExhaustPos  	= Vector(-24)
	CLASS.Racks			= { ["ACF.Racks.1xRK_small"] = true, ["ACF.Racks.1xRK"] = true, ["ACF.Racks.2xRK"] = true, ["ACF.Racks.4xRK"] = true, ["ACF.Racks.6xUARRK"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true }
	CLASS.Navigation  	= "Chase"
	CLASS.Fuzes			= { Contact = true, Timed = true, Optical = true, Altitude = true, Cluster = true }
	CLASS.ViewCone		= 180
	CLASS.Agility		= 0.08
	CLASS.ArmDelay		= 0.2
	CLASS.Round 		= {
		Model           	= "models/missiles/glatgm/mgm51.mdl",
		MaxLength       	= 80,
		Armor           	= 1,
		ProjLength      	= 35,
		PropLength      	= 45,
		Thrust          	= 5000, -- in kg*in/s^2
		FuelConsumption 	= 0.06, -- in g/s/f
		StarterPercent  	= 0.9,
		MaxAgilitySpeed 	= 100, -- in m/s
		DragCoef        	= 0.005,
		FinMul          	= 0,
		GLimit          	= 10,
		TailFinMul      	= 20,
		PenMul          	= 2,
		CanDelayLaunch  	= true,
		ActualLength    	= 80,
		ActualWidth     	= 10.7
	}
	CLASS.Preview 		= {
		Height = 100,
		FOV    = 60,
	}
end)

Classes.DefineClass("ACF.Missiles.Artillery.SAKR-10", "ACF.Missiles.Artillery", function()
	CLASS.Name			= "SAKR-10 Rocket"
	CLASS.Description	= "A short-range but formidable artillery rocket, based upon the Grad. Well suited to the backs of trucks."
	CLASS.Model			= "models/missiles/hvar_folded.mdl"
	CLASS.Caliber		= 122
	CLASS.Mass			= 56
	CLASS.Length		= 287
	CLASS.Year			= 1980
	CLASS.ReloadTime	= 20
	CLASS.ExhaustPos  	= Vector(-44)
	CLASS.Racks			= { ["ACF.Racks.1xRK"] = true, ["ACF.Racks.2xRK"] = true, ["ACF.Racks.4xRK"] = true, ["ACF.Racks.6xUARRK"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true, ["ACF.Missiles.Guidance.Laser"] = true, ["ACF.Missiles.Guidance.GPSGuided"] = true }
	CLASS.Navigation  	= "Chase"
	CLASS.Fuzes			= { Contact = true, Timed = true, Optical = true, Altitude = true }
	CLASS.Agility		= 0.001
	CLASS.ViewCone		= 45
	CLASS.ArmDelay		= 0.4
	CLASS.Round 		= {
		Model           	= "models/missiles/hvar_folded.mdl",
		RackModel       	= "models/missiles/hvar_folded.mdl",
		MaxLength       	= 287,
		Armor           	= 1,
		ProjLength      	= 100,
		PropLength      	= 160,
		Thrust          	= 800000, -- in kg*in/s^2
		FuelConsumption 	= 0.020, -- in g/s/f
		StarterPercent  	= 0.05,
		MaxAgilitySpeed 	= 50, -- in m/s
		DragCoef        	= 0.2,
		FinMul          	= 0.065,
		GLimit          	= 10,
		TailFinMul      	= 30,
		PenMul          	= 1.2,
		CanDelayLaunch  	= true,
		ActualLength    	= 113,
		ActualWidth     	= 4.6
	}
	CLASS.Preview 		= {
		Height = 60,
		FOV    = 60,
	}
end)

Classes.DefineClass("ACF.Missiles.Artillery.SS-40", "ACF.Missiles.Artillery", function()
	CLASS.Name			= "SS-40 Rocket"
	CLASS.Description	= "A large, heavy, guided artillery rocket for taking out stationary or dug-in targets. Slow to load, slow to fire, slow to guide, and slow to arrive."
	CLASS.Model			= "models/missiles/hvar_folded.mdl"
	CLASS.Caliber		= 180
	CLASS.Mass			= 152
	CLASS.Length		= 370
	CLASS.Year			= 1983
	CLASS.ReloadTime	= 30
	CLASS.ExhaustPos 	= Vector(-70)
	CLASS.Racks			= { ["ACF.Racks.1xRK"] = true, ["ACF.Racks.2xRK"] = true, ["ACF.Racks.4xRK"] = true, ["ACF.Racks.6xUARRK"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true, ["ACF.Missiles.Guidance.Laser"] = true, ["ACF.Missiles.Guidance.GPSGuided"] = true }
	CLASS.Navigation  	= "PN"
	CLASS.Fuzes			= { Contact = true, Timed = true, Optical = true, Altitude = true }
	CLASS.Agility		= 0.004
	CLASS.ViewCone		= 45
	CLASS.ArmDelay		= 0.6
	CLASS.Round 		= {
		Model           	= "models/missiles/hvar_folded.mdl",
		RackModel       	= "models/missiles/hvar_folded.mdl",
		MaxLength       	= 370,
		Armor           	= 1,
		ProjLength      	= 140,
		PropLength      	= 200,
		Thrust          	= 2400000, -- in kg*in/s^2
		FuelConsumption 	= 0.022, -- in g/s/f
		StarterPercent  	= 0.05,
		MaxAgilitySpeed 	= 50, -- in m/s
		DragCoef        	= 0.3,
		FinMul          	= 0.08,
		GLimit          	= 10,
		TailFinMul      	= 50,
		PenMul          	= 1.4,
		CanDelayLaunch  	= true,
		ActualLength    	= 146,
		ActualWidth     	= 6.75
	}
	CLASS.Preview 		= {
		Height = 80,
		FOV    = 60,
	}
end)