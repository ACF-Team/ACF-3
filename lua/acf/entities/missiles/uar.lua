local Classes = ACF.Classes
Classes.DefineClass("ACF.Missiles.UnguidedRocket", "ACF.Missiles.BaseMissile", function()
	CLASS.Name			= "Unguided Aerial Rockets"
	CLASS.ID			= "UAR"
	CLASS.Description	= "Rockets which fit in racks, useful for rocket artillery."
	CLASS.Sound			= "acf_missiles/missiles/missile_rocket.mp3"
	CLASS.Effect		= "Rocket Motor"
	CLASS.Spread		= 0.2
	CLASS.Blacklist		= { "ACF.Ammunition.AP", "ACF.Ammunition.APHE", "ACF.Ammunition.HP", "ACF.Ammunition.FL", "ACF.Ammunition.SM" }
	CLASS.LimitConVar	= {
		Name = "_acfm_uam",
		Amount = 20,
		Text = "Maximum number of unguided aerial rockets that can be loaded at once. Differentiates from the acf_rack limit."
	}
end)

Classes.DefineClass("ACF.Missiles.UnguidedRocket.RS82", "ACF.Missiles.UnguidedRocket", function()
	CLASS.Name			= "RS-82 Rocket"
	CLASS.Description	= "A small, unguided rocket, often used in multiple-launch artillery as well as for attacking pinpoint ground targets."
	CLASS.Model			= "models/missiles/rs82.mdl"
	CLASS.Caliber		= 82
	CLASS.Mass			= 7
	CLASS.Length		= 60
	CLASS.Diameter		= 2.2 * ACF.InchToMm -- in mm
	CLASS.ReloadTime	= 5
	CLASS.Offset		= Vector(1, 0, 0)
	CLASS.Year			= 1933
	CLASS.ExhaustPos	= Vector(-12)
	CLASS.Racks			= { ["ACF.Racks.1xRK_small"] = true, ["ACF.Racks.1xRK"] = true, ["ACF.Racks.2xRK"] = true, ["ACF.Racks.4xRK"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true }
	CLASS.Navigation	= "Chase"
	CLASS.Fuzes			= { Contact = true, Timed = true }
	CLASS.Agility		= 1
	CLASS.ArmDelay		= 0.3
	CLASS.Bodygroups	= {
		warhead = {
			DataSource = function(Entity)
				return Entity.BulletData and Entity.BulletData.AmmoType
			end,
			HE = {
				OnRack = "HE.smd",
			},
			HEAT = {
				OnRack = "HEAT.smd",
			}
		}
	}
	CLASS.Round			= {
		Model           	= "models/missiles/rs82.mdl",
		MaxLength       	= 60,
		Armor           	= 1,
		ProjLength      	= 25,
		PropLength      	= 35,
		Thrust          	= 50000, -- in kg*in/s^2
		FuelConsumption 	= 0.033, -- in g/s/f
		StarterPercent  	= 0.15,
		MaxAgilitySpeed 	= 1, -- in m/s
		DragCoef        	= 0.001,
		FinMul          	= 0,
		GLimit          	= 1,
		TailFinMul      	= 0.4,
		PenMul          	= 0.8,
		CanDelayLaunch  	= true,
		ActualLength    	= 24,
		ActualWidth     	= 6
	}
	CLASS.Preview		= {
		FOV = 70,
	}
end)

Classes.DefineClass("ACF.Missiles.UnguidedRocket.HVAR", "ACF.Missiles.UnguidedRocket", function()
	CLASS.Name			= "HVAR Rocket"
	CLASS.Description	= "A medium, unguided rocket. More bang than the RS82, at the cost of size and weight."
	CLASS.Model			= "models/missiles/hvar.mdl"
	CLASS.Caliber		= 127
	CLASS.Mass			= 64
	CLASS.Length		= 173
	CLASS.Diameter		= 4 * ACF.InchToMm -- in mm
	CLASS.ReloadTime	= 10
	CLASS.Offset		= Vector(2, 0, 0)
	CLASS.Year			= 1933
	CLASS.ExhaustPos	= Vector(-33)
	CLASS.Racks			= { ["ACF.Racks.1xRK_small"] = true, ["ACF.Racks.1xRK"] = true, ["ACF.Racks.2xRK"] = true, ["ACF.Racks.3xUARRK"] = true, ["ACF.Racks.4xRK"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true }
	CLASS.Navigation	= "Chase"
	CLASS.Fuzes			= { Contact = true, Timed = true }
	CLASS.Agility		= 1
	CLASS.ArmDelay		= 0.3
	CLASS.Round			= {
		Model           	= "models/missiles/hvar.mdl",
		RackModel       	= "models/missiles/hvar_folded.mdl",
		MaxLength       	= 173,
		Armor           	= 1,
		ProjLength      	= 35.8,
		PropLength      	= 120,
		Thrust          	= 800000, -- in kg*in/s^2
		FuelConsumption 	= 0.016, -- in g/s/f
		StarterPercent  	= 0.15,
		MaxAgilitySpeed 	= 1, -- in m/s
		DragCoef        	= 0.019,
		FinMul          	= 0,
		GLimit          	= 1,
		TailFinMul      	= 0.844,
		PenMul          	= 1.148,
		FillerMul       	= 1,
		LinerMassMul    	= 1,
		Standoff        	= 7,
		CanDelayLaunch  	= true,
		ActualLength    	= 68,
		ActualWidth     	= 5
	}
	CLASS.Preview		= {
		FOV = 60,
	}
end)

Classes.DefineClass("ACF.Missiles.UnguidedRocket.SPG-9", "ACF.Missiles.UnguidedRocket", function()
	CLASS.Name			= "SPG-9 Rocket"
	CLASS.Description	= "A recoilless rocket launcher similar to an RPG or Grom."
	CLASS.Model			= "models/munitions/round_100mm_mortar_shot.mdl"
	CLASS.Caliber		= 73
	CLASS.Mass			= 5
	CLASS.Length		= 100
	CLASS.Year			= 1962
	CLASS.ReloadTime	= 6
	CLASS.ExhaustPos	= Vector(-1)
	CLASS.Racks			= { ["ACF.Racks.1xSPG9"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true }
	CLASS.Navigation	= "Chase"
	CLASS.Fuzes			= { Contact = true }
	CLASS.Agility		= 1
	CLASS.ArmDelay		= 0 -- :)
	CLASS.Round			= {
		Model           	= "models/missiles/rs82.mdl",
		RackModel       	= "models/missiles/rs82.mdl",
		MaxLength       	= 128.18,
		Armor           	= 1,
		ProjLength      	= 20.07,
		PropLength      	= 67.8,
		Thrust          	= 180000, -- in kg*in/s^2
		FuelConsumption 	= 0.03, -- in g/s/f
		StarterPercent  	= 0.4,
		MaxAgilitySpeed 	= 1, -- in m/s
		DragCoef        	= 0.002,
		FinMul          	= 0,
		GLimit          	= 1,
		TailFinMul      	= 0.06,
		PenMul          	= 2.273,
		FillerMul       	= 1.06,
		LinerMassMul    	= 2.8,
		Standoff        	= 33.3,
		ActualLength    	= 39,
		ActualWidth     	= 3
	}
	CLASS.Preview		= {
		FOV = 60,
	}
end)

Classes.DefineClass("ACF.Missiles.UnguidedRocket.S-24", "ACF.Missiles.UnguidedRocket", function()
	CLASS.Name			= "S-24 Rocket"
	CLASS.Description	= "A big, unguided rocket. Mostly used by late cold war era attack planes and helicopters."
	CLASS.Model			= "models/missiles/s24.mdl"
	CLASS.Caliber		= 240
	CLASS.Mass			= 235
	CLASS.Length		= 233
	CLASS.Diameter		= 8.3 * ACF.InchToMm -- in mm
	CLASS.ReloadTime	= 20
	CLASS.Year			= 1960
	CLASS.ExhaustPos	= Vector(-43)
	CLASS.Racks			= { ["ACF.Racks.1xRK"] = true, ["ACF.Racks.2xRK"] = true, ["ACF.Racks.4xRK"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true }
	CLASS.Navigation	= "Chase"
	CLASS.Fuzes			= { Contact = true, Timed = true }
	CLASS.SkinIndex		= { HEAT = 0, HE = 1 }
	CLASS.Agility		= 1
	CLASS.ArmDelay		= 0.3
	CLASS.Round			= {
		Model           	= "models/missiles/s24.mdl",
		MaxLength       	= 233,
		Armor           	= 1,
		ProjLength      	= 103,
		PropLength      	= 130,
		Thrust          	= 2000000, -- in kg*in/s^2
		FuelConsumption 	= 0.02, -- in g/s/f
		StarterPercent  	= 0.15,
		MaxAgilitySpeed 	= 1, -- in m/s
		DragCoef        	= 0.01,
		FinMul          	= 0,
		GLimit          	= 1,
		TailFinMul      	= 0.3,
		PenMul          	= 1.05,
		CanDelayLaunch  	= true,
		ActualLength    	= 92,
		ActualWidth     	= 17
	}
	CLASS.Preview		= {
		FOV = 70,
	}
end)

Classes.DefineClass("ACF.Missiles.UnguidedRocket.RW61", "ACF.Missiles.UnguidedRocket", function()
	CLASS.Name			= "Raketenwerfer 61"
	CLASS.Description	= "A heavy, demolition-oriented rocket-assisted mortar, devastating against field works but takes a very long time to load."
	CLASS.Model			= "models/missiles/RW61M.mdl"
	CLASS.Caliber		= 380
	CLASS.Mass			= 476
	CLASS.Length		= 150
	CLASS.Year			= 1960
	CLASS.ReloadTime	= 40
	CLASS.ExhaustPos	= Vector(-32.5)
	CLASS.Racks			= { ["ACF.Racks.380mmRW61"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true }
	CLASS.Navigation	= "Chase"
	CLASS.Fuzes			= { Contact = true, Optical = true }
	CLASS.Agility		= 1
	CLASS.ArmDelay		= 0.2
	CLASS.Round			= {
		Model           	= "models/missiles/RW61M.mdl",
		RackModel       	= "models/missiles/RW61M.mdl",
		MaxLength       	= 150,
		Armor           	= 2,
		ProjLength      	= 60,
		PropLength      	= 90,
		Thrust          	= 700000, -- in kg*in/s^2
		FuelConsumption 	= 0.048, -- in g/s/f
		StarterPercent  	= 0.2,
		MaxAgilitySpeed 	= 1, -- in m/s
		DragCoef        	= 0.02,
		FinMul          	= 0,
		GLimit          	= 1,
		TailFinMul      	= 38.25,
		PenMul          	= 1.2,
		ActualLength    	= 59,
		ActualWidth     	= 15
	}
	CLASS.Preview		= {
		FOV = 75,
	}
end)