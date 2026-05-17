local Missiles = ACF.Classes.Missiles

Missiles.Register("UAR", {
	Name		= "Unguided Aerial Rockets",
	Description	= "Rockets which fit in racks, useful for rocket artillery.",
	Sound		= "acf_missiles/missiles/missile_rocket.mp3",
	Effect		= "Rocket Motor",
	Spread		= 0.2,
	Blacklist	= { "AP", "APHE", "HP", "FL", "SM" },
	LimitConVar = {
		Name = "_acfm_uam",
		Amount = 20,
		Text = "Maximum number of unguided aerial rockets that can be loaded at once. Differentiates from the acf_rack limit."
	}
})

Missiles.RegisterItem("RS82 ASR", "UAR", {
	Name		= "RS-82 Rocket",
	Description	= "A small, unguided rocket, often used in multiple-launch artillery as well as for attacking pinpoint ground targets.",
	Model		= "models/missiles/rs82.mdl",
	Caliber		= 82,
	Mass		= 7,
	Length		= 60,
	Diameter	= 2.2 * ACF.InchToMm, -- in mm
	ReloadTime	= 5,
	Offset		= Vector(1, 0, 0),
	Year		= 1933,
	ExhaustPos  = Vector(-12),
	Racks		= { ["1xRK_small"] = true, ["1xRK"] = true, ["2xRK"] = true, ["4xRK"] = true },
	Guidance	= { Dumb = true },
	Navigation  = "Chase",
	Fuzes		= { Contact = true, Timed = true },
	Agility     = 1,
	ArmDelay	= 0.3,
	Bodygroups = {
		warhead = {
			DataSource = function(Entity)
				return Entity.BulletData and Entity.BulletData.Type
			end,
			HE = {
				OnRack = "HE.smd",
			},
			HEAT = {
				OnRack = "HEAT.smd",
			}
		}
	},
	Round = {
		Model           = "models/missiles/rs82.mdl",
		MaxLength       = 60,
		Armor           = 2,
		ProjLength      = 25,
		PropLength      = 35,
		Thrust          = 50000, -- in kg*in/s^2
		FuelConsumption = 0.033, -- in g/s/f
		StarterPercent  = 0.15,
		MaxAgilitySpeed = 1, -- in m/s
		DragCoef        = 0.001,
		FinMul          = 0,
		GLimit          = 1,
		TailFinMul      = 0.4,
		PenMul          = 0.8,
		CanDelayLaunch  = true,
		ActualLength    = 24,
		ActualWidth     = 6
	},
	Preview = {
		FOV = 70,
	},
})

Missiles.RegisterItem("HVAR ASR", "UAR", {
	Name		= "HVAR Rocket",
	Description	= "A medium, unguided rocket. More bang than the RS82, at the cost of size and weight.",
	Model		= "models/missiles/hvar.mdl",
	Caliber		= 127,
	Mass		= 64,
	Length		= 173,
	Diameter	= 4 * ACF.InchToMm, -- in mm
	ReloadTime	= 10,
	Offset		= Vector(2, 0, 0),
	Year		= 1933,
	ExhaustPos  = Vector(-33),
	Racks		= { ["1xRK_small"] = true, ["1xRK"] = true, ["2xRK"] = true, ["3xUARRK"] = true, ["4xRK"] = true },
	Guidance	= { Dumb = true },
	Navigation  = "Chase",
	Fuzes		= { Contact = true, Timed = true },
	Agility     = 1,
	ArmDelay	= 0.3,
	Round = {
		Model           = "models/missiles/hvar.mdl",
		RackModel       = "models/missiles/hvar_folded.mdl",
		MaxLength       = 173,
		Armor           = 2,
		ProjLength      = 35.8,
		PropLength      = 120,
		Thrust          = 800000, -- in kg*in/s^2
		FuelConsumption = 0.016, -- in g/s/f
		StarterPercent  = 0.15,
		MaxAgilitySpeed = 1, -- in m/s
		DragCoef        = 0.019,
		FinMul          = 0,
		GLimit          = 1,
		TailFinMul      = 0.844,
		PenMul          = 1.148,
		FillerMul       = 1,
		LinerMassMul    = 1,
		Standoff        = 7,
		CanDelayLaunch  = true,
		ActualLength    = 68,
		ActualWidth     = 5
	},
	Preview = {
		FOV = 60,
	},
})

Missiles.RegisterItem("SPG-9 ASR", "UAR", {
	Name		= "SPG-9 Rocket",
	Description	= "A recoilless rocket launcher similar to an RPG or Grom.",
	Model		= "models/munitions/round_100mm_mortar_shot.mdl",
	Caliber		= 73,
	Mass		= 5,
	Length		= 100,
	Year		= 1962,
	ReloadTime	= 6,
	ExhaustPos  = Vector(-1),
	Racks		= { ["1x SPG9"] = true },
	Guidance	= { Dumb = true },
	Navigation  = "Chase",
	Fuzes		= { Contact = true },
	Agility     = 1,
	ArmDelay	= 0, -- :)
	Round = {
		Model           = "models/missiles/rs82.mdl",
		RackModel       = "models/missiles/rs82.mdl",
		MaxLength       = 128.18,
		Armor           = 2,
		ProjLength      = 20.07,
		PropLength      = 67.8,
		Thrust          = 180000, -- in kg*in/s^2
		FuelConsumption = 0.03, -- in g/s/f
		StarterPercent  = 0.4,
		MaxAgilitySpeed = 1, -- in m/s
		DragCoef        = 0.002,
		FinMul          = 0,
		GLimit          = 1,
		TailFinMul      = 0.06,
		PenMul          = 2.273,
		FillerMul       = 1.06,
		LinerMassMul    = 2.8,
		Standoff        = 33.3,
		ActualLength    = 39,
		ActualWidth     = 3
	},
	Preview = {
		FOV = 60,
	},
})

Missiles.RegisterItem("S-24 ASR", "UAR", {
	Name		= "S-24 Rocket",
	Description	= "A big, unguided rocket. Mostly used by late cold war era attack planes and helicopters.",
	Model		= "models/missiles/s24.mdl",
	Caliber		= 240,
	Mass		= 235,
	Length		= 233,
	Diameter	= 8.3 * ACF.InchToMm, -- in mm
	ReloadTime	= 20,
	Year		= 1960,
	ExhaustPos  = Vector(-43),
	Racks		= { ["1xRK"] = true, ["2xRK"] = true, ["4xRK"] = true },
	Guidance	= { Dumb = true },
	Navigation  = "Chase",
	Fuzes		= { Contact = true, Timed = true },
	SkinIndex	= { HEAT = 0, HE = 1 },
	Agility     = 1,
	ArmDelay	= 0.3,
	Round = {
		Model           = "models/missiles/s24.mdl",
		MaxLength       = 233,
		Armor           = 2,
		ProjLength      = 103,
		PropLength      = 130,
		Thrust          = 2000000, -- in kg*in/s^2
		FuelConsumption = 0.02, -- in g/s/f
		StarterPercent  = 0.15,
		MaxAgilitySpeed = 1, -- in m/s
		DragCoef        = 0.01,
		FinMul          = 0,
		GLimit          = 1,
		TailFinMul      = 0.3,
		PenMul          = 1.05,
		CanDelayLaunch  = true,
		ActualLength    = 92,
		ActualWidth     = 17
	},
	Preview = {
		FOV = 70,
	},
})

Missiles.RegisterItem("RW61 ASR", "UAR", {
	Name		= "Raketenwerfer 61",
	Description	= "A heavy, demolition-oriented rocket-assisted mortar, devastating against field works but takes a very long time to load.",
	Model		= "models/missiles/RW61M.mdl",
	Caliber		= 380,
	Mass		= 476,
	Length		= 150,
	Year		= 1960,
	ReloadTime	= 40,
	ExhaustPos  = Vector(-32.5),
	Racks		= { ["380mmRW61"] = true },
	Guidance	= { Dumb = true },
	Navigation  = "Chase",
	Fuzes		= { Contact = true, Optical = true },
	Agility		= 1,
	ArmDelay	= 0.2,
	Round = {
		Model           = "models/missiles/RW61M.mdl",
		RackModel       = "models/missiles/RW61M.mdl",
		MaxLength       = 150,
		Armor           = 5,
		ProjLength      = 60,
		PropLength      = 90,
		Thrust          = 700000, -- in kg*in/s^2
		FuelConsumption = 0.048, -- in g/s/f
		StarterPercent  = 0.2,
		MaxAgilitySpeed = 1, -- in m/s
		DragCoef        = 0.02,
		FinMul          = 0,
		GLimit          = 1,
		TailFinMul      = 38.25,
		PenMul          = 1.2,
		ActualLength    = 59,
		ActualWidth     = 15
	},
	Preview = {
		FOV = 75,
	},
})
