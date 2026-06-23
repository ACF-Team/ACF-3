local Classes = ACF.Classes
Classes.DefineClass("ACF.Missiles.GuidedBomb", "ACF.Missiles.BaseMissile", function()
	CLASS.Name			= "Guided Bomb Units"
	CLASS.ID			= "GBU"
	CLASS.Description	= "Similar to a regular bomb, but able to be guided in flight to a vector coordinate. Most useful versus hard, unmoving targets."
	CLASS.Sound			= "acf_missiles/fx/clunk.mp3"
	CLASS.NoThrust		= true
	CLASS.Spread		= 1
	CLASS.Blacklist		= {"ACF.Ammunition.AP", "ACF.Ammunition.APHE", "ACF.Ammunition.HP", "ACF.Ammunition.FL"}
	CLASS.LimitConVar	= {
		Name = "_acfm_gbu",
		Amount = 8,
		Text = "Maximum number of guided bomb units that can be loaded at once. Differentiates from the acf_rack limit."
	}
end)

Classes.DefineClass("ACF.Missiles.GuidedBomb.Walleye", "ACF.Missiles.GuidedBomb", function()
	CLASS.Name			= "AGM-62 Walleye"
	CLASS.Description	= "An early TV guided bomb, used over Vietnam by American strike aircraft."
	CLASS.Model			= "models/bombs/gbu/agm62.mdl"
	CLASS.Length		= 345
	CLASS.Caliber		= 318
	CLASS.Mass			= 510
	CLASS.Year			= 1967
	CLASS.Diameter		= 16.4 * ACF.InchToMm -- in mm
	CLASS.ReloadTime	= 30
	CLASS.Racks			= { ["1xRK"] = true, ["2xRK"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true, ["ACF.Missiles.Guidance.RadioMCLOS"] = true }
	CLASS.Navigation	= "Chase"
	CLASS.Fuzes			= { Contact = true, Timed = true, Optical = true, Altitude = true }
	CLASS.SeekCone		= 90
	CLASS.ViewCone		= 120
	CLASS.Agility		= 0.04
	CLASS.ArmDelay		= 1
	CLASS.Round			= {
		Model           	= "models/bombs/gbu/agm62.mdl",
		MaxLength       	= 345,
		Armor           	= 2,
		ProjLength      	= 155,
		PropLength      	= 0,
		Thrust          	= 1, -- in kg*in/s^2
		FuelConsumption 	= 0.1, -- in g/s/f
		StarterPercent  	= 0.005,
		MaxAgilitySpeed 	= 50, -- in m/s
		DragCoef        	= 0.06,
		FinMul          	= 0.3,
		GLimit          	= 3,
		TailFinMul      	= 1,
		PenMul          	= 1,
		FillerRatio     	= 0.63,
		ActualLength    	= 136,
		ActualWidth     	= 32
	}
	CLASS.Preview		= {
		FOV = 75,
	}
end)

Classes.DefineClass("ACF.Missiles.GuidedBomb.227kg", "ACF.Missiles.GuidedBomb", function()
	CLASS.Name			= "227kg GBU-12 Paveway II"
	CLASS.Description	= "Based on the Mk 82 500-pound general-purpose bomb, but with the addition of a nose-mounted laser seeker and fins for guidance."
	CLASS.Model			= "models/bombs/gbu/gbu12.mdl"
	CLASS.Length		= 327
	CLASS.Caliber		= 273
	CLASS.Mass			= 227
	CLASS.Year			= 1976
	CLASS.Diameter		= 10 * ACF.InchToMm -- in mm
	CLASS.ReloadTime	= 25
	CLASS.Offset		= Vector(12, 0, 0)
	CLASS.Racks			= { ["1xRK"] = true, ["2xRK"] = true, ["3xRK"] = true, ["4xRK"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true, ["ACF.Missiles.Guidance.Laser"] = true, ["ACF.Missiles.Guidance.GPSGuided"] = true }
	CLASS.Navigation	= "PN"
	CLASS.Fuzes			= { Contact = true, Timed = true, Optical = true, Altitude = true }
	CLASS.SeekCone		= 60
	CLASS.ViewCone		= 80
	CLASS.Agility		= 0.015
	CLASS.ArmDelay		= 1
	CLASS.Bodygroups	= {
		guidance = {
			DataSource = function(Entity)
				return Entity.GuidanceData and Entity.GuidanceData.Name
			end,
			Laser = {
				OnRack = "laser.smd",
				OnLaunch = "laser_f.smd",
			},
			["GPS Guided"] = {
				OnRack = "laser.smd",
				OnLaunch = "laser_f.smd",
			}
		}
	}
	CLASS.Round			= {
		Model           	= "models/bombs/gbu/gbu12_fold.mdl",
		RackModel       	= "models/bombs/gbu/gbu12.mdl",
		MaxLength       	= 220,
		Armor           	= 2,
		ProjLength      	= 155,
		PropLength      	= 0,
		Thrust          	= 1, -- in kg*in/s^2
		FuelConsumption 	= 0.1, -- in g/s/f
		StarterPercent  	= 0.005,
		MaxAgilitySpeed 	= 50, -- in m/s
		DragCoef        	= 0.03,
		FinMul          	= 0.15,
		GLimit          	= 3,
		TailFinMul      	= 0.5,
		PenMul          	= 1,
		FillerRatio     	= 0.89,
		ActualLength    	= 129,
		ActualWidth     	= 16
	}
	CLASS.Preview		= {
		Height = 90,
		FOV    = 60,
	}
end)

Classes.DefineClass("ACF.Missiles.GuidedBomb.454kg", "ACF.Missiles.GuidedBomb", function()
	CLASS.Name			= "454kg GBU-16 Paveway II"
	CLASS.Description	= "Based on the Mk 83 general-purpose bomb, but with laser seeker and wings for guidance."
	CLASS.Model			= "models/bombs/gbu/gbu16.mdl"
	CLASS.Length		= 370
	CLASS.Caliber		= 360
	CLASS.Mass			= 454
	CLASS.Year			= 1976
	CLASS.Diameter		= 11.5 * ACF.InchToMm -- in mm
	CLASS.ReloadTime	= 40
	CLASS.Racks			= { ["1xRK"] = true, ["2xRK"] = true, ["3xRK"] = true, ["4xRK"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true, ["ACF.Missiles.Guidance.Laser"] = true, ["ACF.Missiles.Guidance.GPSGuided"] = true }
	CLASS.Navigation	= "PN"
	CLASS.Fuzes			= { Contact = true, Timed = true, Optical = true, Altitude = true }
	CLASS.SeekCone		= 60
	CLASS.ViewCone		= 80
	CLASS.Agility		= 0.03
	CLASS.ArmDelay		= 1
	CLASS.Bodygroups	= {
		guidance = {
			DataSource = function(Entity)
				return Entity.GuidanceData and Entity.GuidanceData.Name
			end,
			Laser = {
				OnRack = "laser.smd",
				OnLaunch = "laser_f.smd",
			},
			["GPS Guided"] = {
				OnRack = "laser.smd",
				OnLaunch = "laser_f.smd",
			}
		}
	}
	CLASS.Round			= {
		Model           	= "models/bombs/gbu/gbu16_fold.mdl",
		RackModel       	= "models/bombs/gbu/gbu16.mdl",
		MaxLength       	= 250,
		Armor           	= 2,
		ProjLength      	= 170,
		PropLength      	= 0,
		Thrust          	= 1, -- in kg*in/s^2
		FuelConsumption 	= 0.1, -- in g/s/f
		StarterPercent  	= 0.005,
		MaxAgilitySpeed 	= 50, -- in m/s
		DragCoef        	= 0.04,
		FinMul          	= 0.3,
		GLimit          	= 3,
		TailFinMul      	= 2,
		PenMul          	= 1,
		FillerRatio     	= 0.82,
		ActualLength    	= 146,
		ActualWidth     	= 20
	}
	CLASS.Preview		= {
		FOV = 65,
	}
end)

Classes.DefineClass("ACF.Missiles.GuidedBomb.909kg", "ACF.Missiles.GuidedBomb", function()
	CLASS.Name			= "909kg GBU-10 Paveway II"
	CLASS.Description	= "Based on the Mk 84 general-purpose bomb, but with laser seeker and wings for guidance."
	CLASS.Model			= "models/bombs/gbu/gbu10.mdl"
	CLASS.Length		= 434
	CLASS.Caliber		= 460
	CLASS.Mass			= 909
	CLASS.Year			= 1976
	CLASS.Diameter		= 17 * ACF.InchToMm -- in mm
	CLASS.ReloadTime	= 60
	CLASS.Offset		= Vector(15, 0, 0)
	CLASS.Racks			= { ["1xRK"] = true, ["2xRK"] = true, ["4xRK"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true, ["ACF.Missiles.Guidance.Laser"] = true, ["ACF.Missiles.Guidance.GPSGuided"] = true }
	CLASS.Navigation	= "PN"
	CLASS.Fuzes			= { Contact = true, Timed = true, Optical = true, Altitude = true }
	CLASS.SeekCone		= 60
	CLASS.ViewCone		= 80
	CLASS.Agility		= 0.05
	CLASS.ArmDelay		= 3
	CLASS.Bodygroups	= {
		guidance = {
			DataSource = function(Entity)
				return Entity.GuidanceData and Entity.GuidanceData.Name
			end,
			Laser = {
				OnRack = "laser.smd",
				OnLaunch = "laser_f.smd",
			},
			["GPS Guided"] = {
				OnRack = "laser.smd",
				OnLaunch = "laser_f.smd",
			}
		}
	}
	CLASS.Round			= {
		Model           	= "models/bombs/gbu/gbu10_fold.mdl",
		RackModel       	= "models/bombs/gbu/gbu10.mdl",
		MaxLength       	= 320,
		Armor           	= 2,
		ProjLength      	= 205,
		PropLength      	= 0,
		Thrust          	= 1, -- in kg*in/s^2
		FuelConsumption 	= 0.1, -- in g/s/f
		StarterPercent  	= 0.005,
		MaxAgilitySpeed 	= 50, -- in m/s
		DragCoef        	= 0.5,
		FinMul          	= 0.5,
		GLimit          	= 3,
		TailFinMul      	= 4,
		PenMul          	= 1,
		FillerRatio     	= 0.85,
		ActualLength    	= 171,
		ActualWidth     	= 26
	}
	CLASS.Preview		= {
		FOV = 70,
	}
end)