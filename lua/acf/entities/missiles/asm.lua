local Classes = ACF.Classes
Classes.DefineClass("ACF.Missiles.AntiTankGuided", "ACF.Missiles.BaseMissile", function()
	CLASS.Name			= "Anti-Tank Guided Missiles"
	CLASS.ID			= "ATGM"
	CLASS.Description	= "Missiles specialized on destroying heavily armored vehicles."
	CLASS.Sound			= "acf_missiles/missiles/missile_rocket.mp3"
	CLASS.Effect		= "Rocket Motor ATGM"
	CLASS.Spread		= 1
	CLASS.Blacklist		= { "AP", "APHE", "HP", "FL", "SM" }
	CLASS.LimitConVar	= {
		Name = "_acfm_asm",
		Amount = 8,
		Text = "Maximum number of anti-tank guided missiles that can be loaded at once. Differentiates from the acf_rack limit."
	}
end)

Classes.DefineClass("ACF.Missiles.AntiTankGuided.AT-3", "ACF.Missiles.AntiTankGuided", function()
	CLASS.Name			= "9M14 Malyutka"
	CLASS.Description	= "The 9M14 Malyutka (AT-3 Sagger) is a short-range wire-guided anti-tank missile."
	CLASS.Model			= "models/missiles/at3.mdl"
	CLASS.Length		= 86
	CLASS.Caliber		= 125
	CLASS.Mass			= 11
	CLASS.Diameter		= 4.2 * ACF.InchToMm
	CLASS.Year			= 1969
	CLASS.ReloadTime	= 10
	CLASS.ExhaustPos	= Vector(-16)
	CLASS.Racks			= { ["1xAT3RKS"] = true, ["1xAT3RK"] = true, ["1xRK_small"] = true, ["4xRK"] = true }
	CLASS.Navigation	= "Chase"
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true, ["Wire (MCLOS)"] = true, ["ACF.Missiles.Guidance.WireSACLOS"] = true }
	CLASS.Fuzes			= { Contact = true }
	CLASS.SkinIndex		= { HEAT = 0, HE = 1 }
	CLASS.Agility		= 0.0005
	CLASS.ArmDelay		= 0.1
	CLASS.Round			= {
		Model           	= "models/missiles/at3.mdl",
		MaxLength       	= 86,
		Armor           	= 1,
		ProjLength      	= 16,
		PropLength      	= 26,
		Thrust          	= 8020, -- in kg*in/s^2
		FuelConsumption 	= 0.052, -- in g/s/f
		StarterPercent  	= 0.14,
		MaxAgilitySpeed 	= 100, -- in m/s
		DragCoef        	= 0.02,
		FinMul          	= 0.1,
		GLimit          	= 10,
		TailFinMul      	= 0.01,
		PenMul          	= 0.905,
		FillerMul       	= 12,
		LinerMassMul    	= 1.2,
		Standoff        	= 22,
		CanDelayLaunch  	= true,
		ActualLength    	= 34,
		ActualWidth     	= 8
	}
	CLASS.Preview		= {
		FOV = 100,
	}
end)

Classes.DefineClass("ACF.Missiles.AntiTankGuided.BGM-71E", "ACF.Missiles.AntiTankGuided", function()
	CLASS.Name			= "BGM-71E TOW"
	CLASS.Description	= "The BGM-71E TOW is a medium-range wire guided anti-tank missile."
	CLASS.Model			= "models/missiles/bgm_71e.mdl"
	CLASS.Length		= 117	-- Length not counting the probe
	CLASS.Caliber		= 152
	CLASS.Mass			= 23
	CLASS.Year			= 1970
	CLASS.ReloadTime	= 20
	CLASS.Offset		= Vector(-17.5, 0, 0)
	CLASS.Racks			= { ["1x BGM-71E"] = true, ["2x BGM-71E"] = true, ["4x BGM-71E"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true, ["ACF.Missiles.Guidance.WireSACLOS"] = true }
	CLASS.Navigation	= "Chase"
	CLASS.Fuzes			= { Contact = true }
	CLASS.Agility		= 0.00024
	CLASS.ArmDelay		= 0.1
	CLASS.Round			= {
		Model           	= "models/missiles/bgm_71e.mdl",
		RackModel       	= "models/missiles/bgm_71e_round.mdl",
		MaxLength       	= 117,
		Armor           	= 1,
		ProjLength      	= 20,
		PropLength      	= 18,
		Thrust          	= 34000, -- in kg*in/s^2
		FuelConsumption 	= 0.032, -- in g/s/f
		StarterPercent  	= 0.4,
		MaxAgilitySpeed 	= 150, -- in m/s
		DragCoef        	= 0.005,
		FinMul          	= 0.1,
		GLimit          	= 10,
		TailFinMul      	= 0.01,
		PenMul          	= 1.084,
		FillerMul       	= 12,
		LinerMassMul    	= 1,
		Standoff        	= 33.5,
		ActualLength    	= 46,
		ActualWidth     	= 6
	}
	CLASS.Preview		= {
		FOV = 60,
	}
end)

Classes.DefineClass("ACF.Missiles.AntiTankGuided.AGM-114", "ACF.Missiles.AntiTankGuided", function()
	CLASS.Name			= "AGM-114 Hellfire"
	CLASS.Description	= "The AGM-114 Hellfire is a heavy air-to-surface missile, used often by American aircraft."
	CLASS.Model			= "models/missiles/agm_114.mdl"
	CLASS.Length		= 160
	CLASS.Caliber		= 180
	CLASS.Mass			= 49
	CLASS.Diameter		= 6.5 * ACF.InchToMm -- in mm
	CLASS.Year			= 1984
	CLASS.ReloadTime	= 30
	CLASS.ExhaustPos	= Vector(-29)
	CLASS.Racks			= { ["1xRK"] = true, ["1xRK_small"] = true, ["2x AGM-114"] = true, ["4x AGM-114"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true, ["ACF.Missiles.Guidance.Laser"] = true }
	CLASS.Navigation	= "PN"
	CLASS.Fuzes			= { Contact = true }
	CLASS.ViewCone		= 40
	CLASS.SeekCone		= 10
	CLASS.Agility		= 0.0008
	CLASS.ArmDelay		= 0.5
	CLASS.Bodygroups	= {
		guidance = {
			DataSource = function(Entity)
				return Entity.GuidanceData and Entity.GuidanceData.Name
			end,
			Laser = {
				OnRack = "laser.smd",
			},
			["Active Radar"] = {
				OnRack = "radar.smd",
			}
		}
	}
	CLASS.Round			= {
		Model           	= "models/missiles/agm_114.mdl",
		MaxLength       	= 160,
		Armor           	= 1,
		ProjLength      	= 30,
		PropLength      	= 56,
		Thrust          	= 210000, -- in kg*in/s^2
		FuelConsumption 	= 0.03, -- in g/s/f
		StarterPercent  	= 0.12,
		MaxAgilitySpeed 	= 40, -- in m/s
		DragCoef        	= 0.005,
		FinMul          	= 0.1,
		GLimit          	= 14,
		TailFinMul      	= 0.01,
		PenMul          	= 1,
		FillerMul       	= 12,
		LinerMassMul    	= 1,
		Standoff        	= 51,
		CanDelayLaunch  	= true,
		ActualLength    	= 64,
		ActualWidth     	= 10
	}
	CLASS.Preview		= {
		Height = 90,
		FOV    = 60,
	}
end)

Classes.DefineClass("ACF.Missiles.AntiTankGuided.Ataka", "ACF.Missiles.AntiTankGuided", function()
	CLASS.Name			= "9M120 Ataka"
	CLASS.Description	= "The 9M120 Ataka (AT-9 Spiral-2) is a heavy air-to-surface missile, used often by soviet helicopters and ground vehicles."
	CLASS.Model			= "models/missiles/9m120.mdl"
	CLASS.Length		= 183
	CLASS.Caliber		= 130
	CLASS.Mass			= 50
	CLASS.Diameter		= 10.9 * ACF.InchToMm -- in mm
	CLASS.Year			= 1984
	CLASS.ReloadTime	= 25
	CLASS.ExhaustPos	= Vector(-40)
	CLASS.Racks			= { ["1x Ataka"] = true, ["1xRK"] = true, ["2xRK"] = true, ["4xRK"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true, ["ACF.Missiles.Guidance.RadioSACLOS"] = true }
	CLASS.Navigation	= "Chase"
	CLASS.Fuzes			= { Contact = true }
	CLASS.ViewCone		= 45
	CLASS.Agility		= 0.00072
	CLASS.ArmDelay		= 0.1
	CLASS.NoDamage		= true
	CLASS.Round			= {
		Model           	= "models/missiles/9m120.mdl",
		RackModel       	= "models/missiles/9m120_rk1.mdl",
		MaxLength       	= 183,
		Armor           	= 1,
		ProjLength      	= 17.5,
		PropLength      	= 68,
		Thrust          	= 230000, -- in kg*in/s^2
		FuelConsumption 	= 0.03, -- in g/s/f
		StarterPercent  	= 0.2,
		MaxAgilitySpeed 	= 200, -- in m/s
		DragCoef        	= 0.024,
		FinMul          	= 0.1,
		GLimit          	= 13.8,
		TailFinMul      	= 0.01,
		PenMul          	= 1.378,
		FillerMul       	= 5,
		LinerMassMul    	= 1.2,
		Standoff        	= 56,
		ActualLength    	= 72,
		ActualWidth     	= 5
	}
	CLASS.Preview		= {
		Height = 90,
		FOV    = 60,
	}
end)

Classes.DefineClass("ACF.Missiles.AntiTankGuided.9M133", "ACF.Missiles.AntiTankGuided", function()
	CLASS.Name			= "9M133 Kornet"
	CLASS.Description	= "The 9M133 Kornet (AT-14 Spriggan) is an extremely powerful antitank missile."
	CLASS.Model			= "models/kali/weapons/kornet/parts/9m133 kornet missile.mdl"
	CLASS.Length		= 120
	CLASS.Caliber		= 152
	CLASS.Mass			= 27
	CLASS.Year			= 1994
	CLASS.ReloadTime	= 25
	CLASS.ExhaustPos	= Vector(-29.1, 0, 0)
	CLASS.Racks			= { ["1x Kornet"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true, ["ACF.Missiles.Guidance.Laser"] = true }
	CLASS.Navigation	= "PN"
	CLASS.Fuzes			= { Contact = true }
	CLASS.ViewCone		= 20
	CLASS.Agility		= 0.0004
	CLASS.ArmDelay		= 0.1
	CLASS.Bodygroups	= {
		fins = {
			DataSource = function()
				return "Fins"
			end,
			Fins = {
				OnRack = "Fins_Stowed",
				OnLaunch = "Fins_Deployed",
			},
		}
	}
	CLASS.Round			= {
		Model           	= "models/kali/weapons/kornet/parts/9m133 kornet missile.mdl",
		RackModel       	= "models/kali/weapons/kornet/parts/9m133 kornet tube.mdl",
		MaxLength       	= 120,
		Armor           	= 1,
		ProjLength      	= 21,
		PropLength      	= 30,
		Thrust          	= 40000,   -- in kg*in/s^2
		FuelConsumption 	= 0.04,    -- in g/s/f
		StarterPercent  	= 0.15,
		MaxAgilitySpeed 	= 120,      -- in m/s
		DragCoef        	= 0.013,
		FinMul          	= 0.1,
		GLimit          	= 8,
		TailFinMul      	= 0.01,
		PenMul          	= 1.036,
		FillerMul       	= 10,
		LinerMassMul    	= 1.2,
		Standoff        	= 64,
		ActualLength    	= 47,
		ActualWidth     	= 6
	}
	CLASS.Preview		= {
		Height = 90,
		FOV    = 60,
	}
end)

Classes.DefineClass("ACF.Missiles.AntiTankGuided.AT-2", "ACF.Missiles.AntiTankGuided", function()
	CLASS.Name			= "9M17 Fleyta"
	CLASS.Description	= "The 9M17 Fleyta (AT-2 Sagger) is a powerful radio command medium-range antitank missile, intended for use on helicopters and anti tank vehicles. It has a more powerful warhead and longer range than the AT-3 at the cost of weight and agility."
	CLASS.Model			= "models/missiles/at2.mdl"
	CLASS.Length		= 116
	CLASS.Caliber		= 148
	CLASS.Mass			= 27
	CLASS.Year			= 1969
	CLASS.Diameter		= 5.5 * ACF.InchToMm
	CLASS.ReloadTime	= 15
	CLASS.ExhaustPos	= Vector(-22)
	CLASS.Racks			= { ["1xRK_small"] = true, ["1xRK"] = true, ["2xRK"] = true }
	CLASS.Guidance		= { ["ACF.Missiles.Guidance.Dumb"] = true, ["ACF.Missiles.Guidance.RadioMCLOS"] = true, ["ACF.Missiles.Guidance.RadioSACLOS"] = true }
	CLASS.Navigation	= "Chase"
	CLASS.Fuzes			= { Contact = true }
	CLASS.ViewCone		= 90
	CLASS.Agility		= 0.00035
	CLASS.ArmDelay		= 0.1
	CLASS.Round			= {
		Model           	= "models/missiles/at2.mdl",
		MaxLength       	= 116,
		Armor           	= 1,
		ProjLength      	= 23,
		PropLength      	= 26,
		Thrust          	= 68000, -- in kg*in/s^2
		FuelConsumption 	= 0.048, -- in g/s/f
		StarterPercent  	= 0.08,
		MaxAgilitySpeed 	= 80, -- in m/s
		DragCoef        	= 0.005,
		FinMul          	= 0.1,
		GLimit          	= 10,
		TailFinMul      	= 0.01,
		PenMul          	= 2.5753,
		FillerMul       	= 4,
		LinerMassMul    	= 2,
		Standoff        	= 5.7,
		CanDelayLaunch  	= true,
		ActualLength    	= 46,
		ActualWidth     	= 27
	}
	CLASS.Preview		= {
		FOV = 80,
	}
end)