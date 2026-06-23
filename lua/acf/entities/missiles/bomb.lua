local Classes = ACF.Classes
Classes.DefineClass("ACF.Missiles.FreeFallingBomb", "ACF.Missiles.BaseMissile", function()
	CLASS.Name			= "Free Falling Bombs"
	CLASS.ID			= "BOMB"
	CLASS.Description	= "Despite their lack of guidance and sophistication, they are exceptionally destructive on impact relative to their weight."
	CLASS.Sound			= "acf_missiles/fx/clunk.mp3"
	CLASS.NoThrust		= true
	CLASS.Spread		= 1
	CLASS.Blacklist		= { "ACF.Ammunition.AP", "ACF.Ammunition.APHE", "ACF.Ammunition.HP", "ACF.Ammunition.FL" }
	CLASS.LimitConVar	= {
		Name = "_acfm_bomb",
		Amount = 8,
		Text = "Maximum number of free-falling bombs that can be loaded at once. Differentiates from the acf_rack limit."
	}
end)

Classes.DefineClass("ACF.Missiles.FreeFallingBomb.50kg", "ACF.Missiles.FreeFallingBomb", function()
	CLASS.Name			= "50kg Free Falling Bomb"
	CLASS.Description	= "Old WW2 100lb bomb, most effective vs exposed infantry and light trucks."
	CLASS.Model			= "models/bombs/fab50.mdl"
	CLASS.Length		= 109
	CLASS.Caliber		= 200
	CLASS.Mass			= 50
	CLASS.Year			= 1936
	CLASS.Diameter		= 8.35 * ACF.InchToMm -- in mm
	CLASS.ReloadTime	= 10
	CLASS.Offset		= Vector(-6, 0, 0)
	CLASS.Racks			= { ["1xRK_small"] = true, ["1xRK"] = true, ["2xRK"] = true, ["4xRK"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true }
	CLASS.Navigation	= "Chase"
	CLASS.Fuzes			= { Contact = true, Optical = true}
	CLASS.Agility		= 1
	CLASS.ArmDelay		= 0.5
	CLASS.Round			= {
		Model           	= "models/bombs/fab50.mdl",
		MaxLength       	= 109,
		Armor           	= 1,
		ProjLength      	= 50,
		PropLength      	= 0,
		Thrust          	= 1, -- in kg*in/s^2
		FuelConsumption 	= 0.1, -- in g/s/f
		StarterPercent  	= 0.01,
		MaxAgilitySpeed 	= 1, -- in m/s
		DragCoef        	= 0.01,
		FinMul          	= 0.001,
		GLimit          	= 1,
		TailFinMul      	= 10,
		PenMul          	= 1,
		FillerRatio     	= 0.78,
		ActualLength    	= 43,
		ActualWidth     	= 8
	}
	CLASS.Preview		= {
		FOV = 75,
	}
end)

Classes.DefineClass("ACF.Missiles.FreeFallingBomb.100kg", "ACF.Missiles.FreeFallingBomb", function()
	CLASS.Name			= "100kg Free Falling Bomb"
	CLASS.Description	= "An old 250lb WW2 bomb, as used by Soviet bombers to destroy enemies of the Motherland."
	CLASS.Model			= "models/bombs/fab100.mdl"
	CLASS.Length		= 106
	CLASS.Caliber		= 273
	CLASS.Mass			= 100
	CLASS.Year			= 1939
	CLASS.Diameter		= 10.5 * ACF.InchToMm -- in mm
	CLASS.ReloadTime	= 15
	CLASS.Offset		= Vector(-6, 0, 0)
	CLASS.Racks			= { ["1xRK_small"] = true, ["1xRK"] = true, ["2xRK"] = true, ["4xRK"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true }
	CLASS.Navigation	= "Chase"
	CLASS.Fuzes			= { Contact = true, Optical = true}
	CLASS.Agility		= 1
	CLASS.ArmDelay		= 1
	CLASS.Round			= {
		Model           	= "models/bombs/fab100.mdl",
		MaxLength       	= 106,
		Armor           	= 2,
		ProjLength      	= 55,
		PropLength      	= 0,
		Thrust          	= 1, -- in kg*in/s^2
		FuelConsumption 	= 0.1, -- in g/s/f
		StarterPercent  	= 0.005,
		MaxAgilitySpeed 	= 1, -- in m/s
		DragCoef        	= 0.02,
		FinMul          	= 0.002,
		GLimit          	= 1,
		TailFinMul      	= 30,
		PenMul          	= 1,
		FillerRatio     	= 0.78,
		ActualLength    	= 42,
		ActualWidth     	= 11
	}
	CLASS.Preview		= {
		FOV = 80,
	}
end)

Classes.DefineClass("ACF.Missiles.FreeFallingBomb.250kg", "ACF.Missiles.FreeFallingBomb", function()
	CLASS.Name			= "250kg Free Falling Bomb"
	CLASS.Description	= "A heavy 500lb bomb, widely used as a tank buster on various WW2 aircraft."
	CLASS.Model			= "models/bombs/fab250.mdl"
	CLASS.Length		= 145
	CLASS.Caliber		= 325
	CLASS.Mass			= 250
	CLASS.Year			= 1941
	CLASS.Diameter		= 12.7 * ACF.InchToMm -- in mm
	CLASS.ReloadTime	= 25
	CLASS.Offset		= Vector(-14, 0, 0)
	CLASS.Racks			= { ["1xRK"] = true, ["2xRK"] = true, ["3xRK"] = true, ["4xRK"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true }
	CLASS.Navigation	= "Chase"
	CLASS.Fuzes			= { Contact = true, Optical = true}
	CLASS.Agility		= 1
	CLASS.ArmDelay		= 1
	CLASS.Round			= {
		Model           	= "models/bombs/fab250.mdl",
		MaxLength       	= 145,
		Armor           	= 2,
		ProjLength      	= 100,
		PropLength      	= 0,
		Thrust          	= 1, -- in kg*in/s^2
		FuelConsumption 	= 0.1, -- in g/s/f
		StarterPercent  	= 0.005,
		MaxAgilitySpeed 	= 1, -- in m/s
		DragCoef        	= 0.03,
		FinMul          	= 0.003,
		GLimit          	= 1,
		TailFinMul      	= 50,
		PenMul          	= 1,
		FillerRatio     	= 0.8,
		ActualLength    	= 57,
		ActualWidth     	= 13
	}
	CLASS.Preview		= {
		FOV = 70,
	}
end)

Classes.DefineClass("ACF.Missiles.FreeFallingBomb.500kg", "ACF.Missiles.FreeFallingBomb", function()
	CLASS.Name			= "500kg Free Falling Bomb"
	CLASS.Description	= "A 1000lb bomb, as found in the heavy bombers of late WW2. Best used against fortifications or immobile targets."
	CLASS.Model			= "models/bombs/fab500.mdl"
	CLASS.Length		= 240
	CLASS.Caliber		= 400
	CLASS.Mass			= 500
	CLASS.Year			= 1943
	CLASS.Diameter		= 15.25 * ACF.InchToMm -- in mm
	CLASS.ReloadTime	= 40
	CLASS.Offset		= Vector(-14, 0, 0)
	CLASS.Racks			= { ["1xRK"] = true, ["2xRK"] = true, ["4xRK"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true }
	CLASS.Navigation	= "Chase"
	CLASS.Fuzes			= { Contact = true, Optical = true}
	CLASS.Agility		= 1
	CLASS.ArmDelay		= 2
	CLASS.Round			= {
		Model           	= "models/bombs/fab500.mdl",
		MaxLength       	= 240,
		Armor           	= 3,
		ProjLength      	= 130,
		PropLength      	= 0,
		Thrust          	= 1, -- in kg*in/s^2
		FuelConsumption 	= 0.1, -- in g/s/f
		StarterPercent  	= 0.005,
		MaxAgilitySpeed 	= 1, -- in m/s
		DragCoef        	= 0.05,
		FinMul          	= 0.005,
		GLimit          	= 1,
		TailFinMul      	= 70,
		PenMul          	= 1,
		FillerRatio     	= 0.79,
		ActualLength    	= 94,
		ActualWidth     	= 16
	}
	CLASS.Preview		= {
		FOV = 70,
	}
end)

Classes.DefineClass("ACF.Missiles.FreeFallingBomb.1000kg", "ACF.Missiles.FreeFallingBomb", function()
	CLASS.Name			= "1000kg Free Falling Bomb"
	CLASS.Description	= "A 2000lb bomb. As close to a nuke as you can get in ACF, this munition will turn everything it touches to ashes. Handle with care."
	CLASS.Model			= "models/bombs/an_m66.mdl"
	CLASS.Length		= 270
	CLASS.Caliber		= 500
	CLASS.Mass			= 1000
	CLASS.Year			= 1945
	CLASS.Diameter		= 22 * ACF.InchToMm -- in mm
	CLASS.ReloadTime	= 60
	CLASS.Offset		= Vector(-10, 0, 0)
	CLASS.Racks			= { ["1xRK"] = true, ["2xRK"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true }
	CLASS.Navigation	= "Chase"
	CLASS.Fuzes			= { Contact = true, Optical = true}
	CLASS.Agility		= 1
	CLASS.ArmDelay		= 3
	CLASS.Round			= {
		Model           	= "models/bombs/an_m66.mdl",
		MaxLength       	= 270,
		Armor           	= 3,
		ProjLength      	= 190,
		PropLength      	= 0,
		Thrust          	= 1, -- in kg*in/s^2
		FuelConsumption 	= 0.1, -- in g/s/f
		StarterPercent  	= 0.005,
		MaxAgilitySpeed 	= 1, -- in m/s
		DragCoef        	= 0.1,
		FinMul          	= 0.01,
		GLimit          	= 1,
		TailFinMul      	= 200,
		PenMul          	= 1,
		FillerRatio     	= 0.85,
		ActualLength    	= 106,
		ActualWidth     	= 32
	}
	CLASS.Preview		= {
		FOV = 80,
	}
end)