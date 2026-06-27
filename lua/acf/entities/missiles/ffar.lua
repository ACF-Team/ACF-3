local Classes = ACF.Classes
Classes.DefineClass("ACF.Missiles.FoldingFinRocket", "ACF.Missiles.BaseMissile", function()
	CLASS.Name			= "Folding-Fin Aerial Rockets"
	CLASS.ID			= "FFAR"
	CLASS.Description	= "Small rockets which fit in tubes or pods. Rapid-firing and versatile."
	CLASS.Sound			= "acf_missiles/missiles/missile_rocket.mp3"
	CLASS.Effect		= "Rocket Motor"
	CLASS.Spread		= 1
	CLASS.Blacklist		= { "ACF.Ammunition.AP", "ACF.Ammunition.APHE", "ACF.Ammunition.HP", "ACF.Ammunition.FL" }
	CLASS.LimitConVar	= {
		Name = "_acfm_ffar",
		Amount = 64,
		Text = "Maximum number of folding-fin aerial rockets missiles that can be loaded at once. Differentiates from the acf_rack limit."
	}
end)

Classes.DefineClass("ACF.Missiles.FoldingFinRocket.40mm", "ACF.Missiles.FoldingFinRocket", function()
	CLASS.Name			= "40mm Pod Rocket"
	CLASS.Description	= "A tiny, unguided rocket. Useful for anti-infantry, smoke and suppression. Folding fins allow the rocket to be stored in pods, which defend them from damage."
	CLASS.Model			= "models/missiles/ffar_40mm.mdl"
	CLASS.Caliber		= 40
	CLASS.Mass			= 4
	CLASS.Length		= 60
	CLASS.Year			= 1960
	CLASS.ReloadTime	= 2
	CLASS.ExhaustPos	= Vector(-12)
	CLASS.Racks			= { ["ACF.Racks.40mm7xPOD"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true }
	CLASS.Navigation	= "Chase"
	CLASS.Fuzes			= { Contact = true, Timed = true }
	CLASS.Agility		= 1
	CLASS.ArmDelay		= 0.1
	CLASS.Round			= {
		Model           	= "models/missiles/ffar_40mm.mdl",
		RackModel       	= "models/missiles/ffar_40mm_closed.mdl",
		MaxLength       	= 60,
		Armor           	= 1,
		ProjLength      	= 25,
		PropLength      	= 35,
		Thrust          	= 150000, -- in kg*in/s^2
		FuelConsumption 	= 0.015, -- in g/s/f
		StarterPercent  	= 0.1,
		MaxAgilitySpeed 	= 1, -- in m/s
		DragCoef        	= 0.004,
		FinMul          	= 0,
		GLimit          	= 1,
		TailFinMul      	= 0.05,
		PenMul          	= 0.91,
		ActualLength    	= 24,
		ActualWidth     	= 2
	}
	CLASS.Preview		= {
		Height = 100,
		FOV    = 60,
	}
end)

Classes.DefineClass("ACF.Missiles.FoldingFinRocket.57mm", "ACF.Missiles.FoldingFinRocket", function()
	CLASS.Name			= "57mm Pod Rocket"
	CLASS.Description	= "A small, spammy rocket with light anti-armor capabilities. Works well on technicals."
	CLASS.Model			= "models/missiles/ffar_40mm.mdl"
	CLASS.Caliber		= 57
	CLASS.Mass			= 4
	CLASS.Length		= 85
	CLASS.Year			= 1956
	CLASS.ReloadTime	= 2
	CLASS.ExhaustPos	= Vector(-12)
	CLASS.Racks			= { ["ACF.Racks.57mm32xPOD"] = true , ["ACF.Racks.57mm16xPOD"] = true}
	CLASS.Navigation	= "Chase"
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true }
	CLASS.Fuzes			= { Contact = true, Timed = true }
	CLASS.Agility		= 1
	CLASS.ArmDelay		= 0.1
	CLASS.Round			= {
		Model           	= "models/missiles/ffar_70mm.mdl",
		RackModel       	= "models/missiles/ffar_70mm_closed.mdl",
		MaxLength       	= 85,
		Armor           	= 1,
		ProjLength      	= 35,
		PropLength      	= 50,
		Thrust          	= 113000, -- in kg*in/s^2
		FuelConsumption	= 0.0095, -- S5 rocket motors burn for 1.1 seconds not 0.333
		StarterPercent  	= 0.2,
		MaxAgilitySpeed	= 1,
		DragCoef        	= 0.007,
		FinMul          	= 0.003,
		GLimit          	= 1,
		TailFinMul      	= 0.005,
		PenMul          	= 1.3,
		ActualLength    	= 40,
		ActualWidth     	= 3,
	}
	CLASS.Preview		= {
		Height = 100,
		FOV    = 60,
	}
end)

Classes.DefineClass("ACF.Missiles.FoldingFinRocket.70mm", "ACF.Missiles.FoldingFinRocket", function()
	CLASS.Name			= "70mm Pod Rocket"
	CLASS.Description	= "A small, unguided rocket. Useful against light vehicles and infantry. Folding fins allow the rocket to be stored in pods, which defend them from damage."
	CLASS.Model			= "models/missiles/ffar_70mm.mdl"
	CLASS.Caliber		= 70
	CLASS.Mass			= 6
	CLASS.Length		= 106
	CLASS.Year			= 1960
	CLASS.ReloadTime	= 5
	CLASS.ExhaustPos	= Vector(-21)
	CLASS.Racks			= { ["ACF.Racks.70mm7xPOD"] = true, ["ACF.Racks.70mm19xPOD"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true }
	CLASS.Navigation	= "Chase"
	CLASS.Fuzes			= { Contact = true, Timed = true }
	CLASS.Agility		= 0.05
	CLASS.ArmDelay		= 0.1
	CLASS.Round			= {
		Model           	= "models/missiles/ffar_70mm.mdl",
		RackModel       	= "models/missiles/ffar_70mm_closed.mdl",
		MaxLength       	= 106,
		Armor           	= 1,
		ProjLength      	= 66,
		PropLength      	= 40,
		Thrust          	= 128500, -- in kg*in/s^2 -- Why was old thrust 1565m/s
		FuelConsumption 	= 0.005, -- in g/s/f
		StarterPercent  	= 0.1,
		MaxAgilitySpeed 	= 1, -- in m/s
		DragCoef        	= 0.004,
		FinMul          	= 0,
		GLimit          	= 1,
		TailFinMul      	= 0.04,
		PenMul          	= 0.85,
		ActualLength    	= 42,
		ActualWidth     	= 3
	}
	CLASS.Preview		= {
		Height = 100,
		FOV    = 60,
	}
end)

Classes.DefineClass("ACF.Missiles.FoldingFinRocket.80mm", "ACF.Missiles.FoldingFinRocket", function()
	CLASS.Name			= "80mm Rocket Pod"
	CLASS.Description	= "A large aerial rocket designed for use against ground targets. Good HEAT performance."
	CLASS.Model			= "models/missiles/ffar_70mm.mdl"
	CLASS.Caliber		= 80
	CLASS.Mass			= 6
	CLASS.Length		= 127
	CLASS.Year			= 1960
	CLASS.ReloadTime	= 5
	CLASS.ExhaustPos	= Vector(-21)
	CLASS.Racks			= { ["ACF.Racks.80mm20xPOD"] = true }
	CLASS.Navigation	= "Chase"
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true }
	CLASS.Fuzes			= { Contact = true, Timed = true }
	CLASS.Agility		= 0.05
	CLASS.ArmDelay		= 0.1
	CLASS.Round			= {
		Model           	= "models/missiles/ffar_70mm.mdl",
		RackModel       	= "models/missiles/ffar_70mm_closed.mdl",
		MaxLength       	= 127,
		Armor           	= 1,
		ProjLength      	= 76,
		PropLength      	= 51,
		Thrust          	= 290000, -- in kg*in/s^2
		FuelConsumption 	= 0.0044, -- in g/s/f -- 1.55 not 0.53
		StarterPercent  	= 0.191,
		MaxAgilitySpeed 	= 1, -- in m/s
		DragCoef        	= 0.023,
		FinMul          	= 0.003,
		GLimit          	= 1,
		TailFinMul      	= 0.08,
		PenMul          	= 0.85,
		ActualLength    	= 60,
		ActualWidth     	= 4
	}
	CLASS.Preview		= {
		Height = 100,
		FOV    = 60,
	}
end)

Classes.DefineClass("ACF.Missiles.FoldingFinRocket.Zuni", "ACF.Missiles.FoldingFinRocket", function()
	CLASS.Name			= "127mm Pod Rocket"
	CLASS.Description	= "A heavy 5in air to surface unguided rocket, able to provide heavy suppressive fire in a single pass."
	CLASS.Model			= "models/ghosteh/zuni.mdl"
	CLASS.Caliber		= 127
	CLASS.Mass			= 45
	CLASS.Length		= 200
	CLASS.Year			= 1957
	CLASS.ReloadTime	= 5
	CLASS.ExhaustPos	= Vector(-45)
	CLASS.Racks			= { ["ACF.Racks.127mm4xPOD"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true }
	CLASS.Navigation	= "Chase"
	CLASS.Fuzes			= { Contact = true, Timed = true, Optical = true, Radio = true, Altitude = true }
	CLASS.Agility		= 0.05
	CLASS.ArmDelay		= 0.1
	CLASS.Round			= {
		Model           	= "models/ghosteh/zuni.mdl",
		RackModel       	= "models/ghosteh/zuni_folded.mdl",
		MaxLength       	= 200,
		Armor           	= 1,
		ProjLength      	= 90,
		PropLength      	= 110,
		Thrust          	= 663000, -- in kg*in/s^2
		FuelConsumption 	= 0.0098, -- in g/s/f
		StarterPercent  	= 0.235,
		MaxAgilitySpeed 	= 1, -- in m/s
		DragCoef        	= 0.002,
		FinMul          	= 0.002,
		GLimit          	= 1,
		TailFinMul      	= 0.08,
		PenMul          	= 1,
		ActualLength    	= 77,
		ActualWidth     	= 5
	}
	CLASS.Preview		= {
		Height = 100,
		FOV    = 60,
	}
end)