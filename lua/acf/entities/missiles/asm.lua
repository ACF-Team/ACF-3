local Missiles = ACF.Classes.Missiles

local Classes = ACF.Classes
Classes.DefineClass("ACF.Missiles.AntiTankGuided", "ACF.Missiles.BaseMissile", function()
	CLASS.ID = "ATGM"
end)

Missiles.Register("ATGM", {
	Name		= "Anti-Tank Guided Missiles",
	Description	= "Missiles specialized on destroying heavily armored vehicles.",
	Sound		= "acf_missiles/missiles/missile_rocket.mp3",
	Effect		= "Rocket Motor ATGM",
	Spread		= 1,
	Blacklist	= { "AP", "APHE", "HP", "FL", "SM" },
	LimitConVar = {
		Name = "_acfm_asm",
		Amount = 8,
		Text = "Maximum number of anti-tank guided missiles that can be loaded at once. Differentiates from the acf_rack limit."
	}
})

Missiles.RegisterItem("AT-3 ASM", "ATGM", {
	Name		= "9M14 Malyutka",
	Description	= "The 9M14 Malyutka (AT-3 Sagger) is a short-range wire-guided anti-tank missile.",
	Model		= "models/missiles/at3.mdl",
	Length		= 86,
	Caliber		= 125,
	Mass		= 11,
	Diameter	= 4.2 * ACF.InchToMm,
	Year		= 1969,
	ReloadTime	= 10,
	ExhaustPos  = Vector(-16),
	Racks		= { ["1xAT3RKS"] = true, ["1xAT3RK"] = true, ["1xRK_small"] = true, ["4xRK"] = true },
	Navigation  = "Chase",
	Guidance	= { Dumb = true, ["Wire (MCLOS)"] = true, ["Wire (SACLOS)"] = true },
	Fuzes		= { Contact = true },
	SkinIndex	= { HEAT = 0, HE = 1 },
	Agility		= 0.0005,
	ArmDelay	= 0.1,
	Round = {
		Model           = "models/missiles/at3.mdl",
		MaxLength       = 86,
		Armor           = 1,
		ProjLength      = 16,
		PropLength      = 26,
		Thrust          = 8020, -- in kg*in/s^2
		FuelConsumption = 0.052, -- in g/s/f
		StarterPercent  = 0.14,
		MaxAgilitySpeed = 100, -- in m/s
		DragCoef        = 0.02,
		FinMul          = 0.1,
		GLimit          = 10,
		TailFinMul      = 0.01,
		PenMul          = 0.905,
		FillerMul       = 12,
		LinerMassMul    = 1.2,
		Standoff        = 22,
		CanDelayLaunch  = true,
		ActualLength    = 34,
		ActualWidth     = 8
	},
	Preview = {
		FOV = 100,
	},
})

Missiles.RegisterItem("BGM-71E ASM", "ATGM", {
	Name		= "BGM-71E TOW",
	Description	= "The BGM-71E TOW is a medium-range wire guided anti-tank missile.",
	Model		= "models/missiles/bgm_71e.mdl",
	Length		= 117,	-- Length not counting the probe
	Caliber		= 152,
	Mass		= 23,
	Year		= 1970,
	ReloadTime	= 20,
	Offset		= Vector(-17.5, 0, 0),
	Racks		= { ["1x BGM-71E"] = true, ["2x BGM-71E"] = true, ["4x BGM-71E"] = true },
	Guidance	= { Dumb = true, ["Wire (SACLOS)"] = true },
	Navigation  = "Chase",
	Fuzes		= { Contact = true },
	Agility		= 0.00024,
	ArmDelay	= 0.1,
	Round = {
		Model           = "models/missiles/bgm_71e.mdl",
		RackModel       = "models/missiles/bgm_71e_round.mdl",
		MaxLength       = 117,
		Armor           = 1,
		ProjLength      = 20,
		PropLength      = 18,
		Thrust          = 34000, -- in kg*in/s^2
		FuelConsumption = 0.032, -- in g/s/f
		StarterPercent  = 0.4,
		MaxAgilitySpeed = 150, -- in m/s
		DragCoef        = 0.005,
		FinMul          = 0.1,
		GLimit          = 10,
		TailFinMul      = 0.01,
		PenMul          = 1.084,
		FillerMul       = 12,
		LinerMassMul    = 1,
		Standoff        = 33.5,
		ActualLength    = 46,
		ActualWidth     = 6
	},
	Preview = {
		FOV = 60,
	},
})

Missiles.RegisterItem("AGM-114 ASM", "ATGM", {
	Name		= "AGM-114 Hellfire",
	Description	= "The AGM-114 Hellfire is a heavy air-to-surface missile, used often by American aircraft.",
	Model		= "models/missiles/agm_114.mdl",
	Length		= 160,
	Caliber		= 180,
	Mass		= 49,
	Diameter	= 6.5 * ACF.InchToMm, -- in mm
	Year		= 1984,
	ReloadTime	= 30,
	ExhaustPos  = Vector(-29),
	Racks		= { ["1xRK"] = true, ["1xRK_small"] = true, ["2x AGM-114"] = true, ["4x AGM-114"] = true },
	Guidance	= { Dumb = true, Laser = true },
	Navigation  = "PN",
	Fuzes		= { Contact = true },
	ViewCone	= 40,
	SeekCone	= 10,
	Agility		= 0.0008,
	ArmDelay	= 0.5,
	Bodygroups = {
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
	},
	Round = {
		Model           = "models/missiles/agm_114.mdl",
		MaxLength       = 160,
		Armor           = 1,
		ProjLength      = 30,
		PropLength      = 56,
		Thrust          = 210000, -- in kg*in/s^2
		FuelConsumption = 0.03, -- in g/s/f
		StarterPercent  = 0.12,
		MaxAgilitySpeed = 40, -- in m/s
		DragCoef        = 0.005,
		FinMul          = 0.1,
		GLimit          = 14,
		TailFinMul      = 0.01,
		PenMul          = 1,
		FillerMul       = 12,
		LinerMassMul    = 1,
		Standoff        = 51,
		CanDelayLaunch  = true,
		ActualLength    = 64,
		ActualWidth     = 10
	},
	Preview = {
		Height = 90,
		FOV    = 60,
	},
})

Missiles.RegisterItem("Ataka ASM", "ATGM", {
	Name		= "9M120 Ataka",
	Description	= "The 9M120 Ataka (AT-9 Spiral-2) is a heavy air-to-surface missile, used often by soviet helicopters and ground vehicles.",
	Model		= "models/missiles/9m120.mdl",
	Length		= 183,
	Caliber		= 130,
	Mass		= 50,
	Diameter	= 10.9 * ACF.InchToMm, -- in mm
	Year		= 1984,
	ReloadTime	= 25,
	ExhaustPos  = Vector(-40),
	Racks		= { ["1x Ataka"] = true, ["1xRK"] = true, ["2xRK"] = true, ["4xRK"] = true },
	Guidance	= { Dumb = true, ["Radio (SACLOS)"] = true },
	Navigation  = "Chase",
	Fuzes		= { Contact = true },
	ViewCone	= 45,
	Agility		= 0.00072,
	ArmDelay	= 0.1,
	NoDamage    = true,
	Round = {
		Model           = "models/missiles/9m120.mdl",
		RackModel       = "models/missiles/9m120_rk1.mdl",
		MaxLength       = 183,
		Armor           = 1,
		ProjLength      = 17.5,
		PropLength      = 68,
		Thrust          = 230000, -- in kg*in/s^2
		FuelConsumption = 0.03, -- in g/s/f
		StarterPercent  = 0.2,
		MaxAgilitySpeed = 200, -- in m/s
		DragCoef        = 0.024,
		FinMul          = 0.1,
		GLimit          = 13.8,
		TailFinMul      = 0.01,
		PenMul          = 1.378,
		FillerMul       = 5,
		LinerMassMul    = 1.2,
		Standoff        = 56,
		ActualLength    = 72,
		ActualWidth     = 5
	},
	Preview = {
		Height = 90,
		FOV    = 60,
	},
})

Missiles.RegisterItem("9M133 ASM", "ATGM", {
	Name		= "9M133 Kornet",
	Description	= "The 9M133 Kornet (AT-14 Spriggan) is an extremely powerful antitank missile.",
	Model		= "models/kali/weapons/kornet/parts/9m133 kornet missile.mdl",
	Length		= 120,
	Caliber		= 152,
	Mass		= 27,
	Year		= 1994,
	ReloadTime	= 25,
	ExhaustPos  = Vector(-29.1, 0, 0),
	Racks		= { ["1x Kornet"] = true },
	Guidance	= { Dumb = true, Laser = true },
	Navigation  = "PN",
	Fuzes		= { Contact = true },
	ViewCone	= 20,
	Agility		= 0.0004,
	ArmDelay	= 0.1,
	Bodygroups = {
		fins = {
			DataSource = function()
				return "Fins"
			end,
			Fins = {
				OnRack = "Fins_Stowed",
				OnLaunch = "Fins_Deployed",
			},
		}
	},
	Round = {
		Model           = "models/kali/weapons/kornet/parts/9m133 kornet missile.mdl",
		RackModel       = "models/kali/weapons/kornet/parts/9m133 kornet tube.mdl",
		MaxLength       = 120,
		Armor           = 1,
		ProjLength      = 21,
		PropLength      = 30,
		Thrust          = 40000,   -- in kg*in/s^2
		FuelConsumption = 0.04,    -- in g/s/f
		StarterPercent  = 0.15,
		MaxAgilitySpeed = 120,      -- in m/s
		DragCoef        = 0.013,
		FinMul          = 0.1,
		GLimit          = 8,
		TailFinMul      = 0.01,
		PenMul          = 1.036,
		FillerMul       = 10,
		LinerMassMul    = 1.2,
		Standoff        = 64,
		ActualLength    = 47,
		ActualWidth     = 6
	},
	Preview = {
		Height = 90,
		FOV    = 60,
	},
})

-- TODO: This is the ONLY use of the alias system in Missiles. I would guess its for ACF2 -> ACF3 compatibility? hopefully...
-- Missiles.AddItemAlias("ATGM", "9M133 ASM", "9M113 ASM")

Missiles.RegisterItem("AT-2 ASM", "ATGM", {
	Name		= "9M17 Fleyta",
	Description	= "The 9M17 Fleyta (AT-2 Sagger) is a powerful radio command medium-range antitank missile, intended for use on helicopters and anti tank vehicles. It has a more powerful warhead and longer range than the AT-3 at the cost of weight and agility.",
	Model		= "models/missiles/at2.mdl",
	Length		= 116,
	Caliber		= 148,
	Mass		= 27,
	Year		= 1969,
	Diameter	= 5.5 * ACF.InchToMm,
	ReloadTime	= 15,
	ExhaustPos  = Vector(-22),
	Racks		= { ["1xRK_small"] = true, ["1xRK"] = true, ["2xRK"] = true },
	Guidance	= { Dumb = true, ["Radio (MCLOS)"] = true, ["Radio (SACLOS)"] = true },
	Navigation  = "Chase",
	Fuzes		= { Contact = true },
	ViewCone	= 90,
	Agility		= 0.00035,
	ArmDelay	= 0.1,
	Round = {
		Model           = "models/missiles/at2.mdl",
		MaxLength       = 116,
		Armor           = 1,
		ProjLength      = 23,
		PropLength      = 26,
		Thrust          = 68000, -- in kg*in/s^2
		FuelConsumption = 0.048, -- in g/s/f
		StarterPercent  = 0.08,
		MaxAgilitySpeed = 80, -- in m/s
		DragCoef        = 0.005,
		FinMul          = 0.1,
		GLimit          = 10,
		TailFinMul      = 0.01,
		PenMul          = 2.5753,
		FillerMul       = 4,
		LinerMassMul    = 2,
		Standoff        = 5.7,
		CanDelayLaunch  = true,
		ActualLength    = 46,
		ActualWidth     = 27
	},
	Preview = {
		FOV = 80,
	},
})
