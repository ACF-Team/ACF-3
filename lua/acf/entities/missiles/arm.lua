local Missiles = ACF.Classes.Missiles

Missiles.Register("ARM", {
	Name		= "Anti-Radiation Missiles",
	Description	= "Missiles specialized for Suppression of Enemy Air Defenses.",
	Sound		= "acf_missiles/missiles/missile_rocket.mp3",
	Effect		= "Rocket Motor ATGM",
	Spread		= 1,
	Blacklist	= { "AP", "APHE", "HEAT", "HP", "FL", "SM" },
	LimitConVar = {
		Name = "_acfm_arm",
		Amount = 8,
		Text = "Maximum number of anti-radiation missiles that can be loaded at once. Differentiates from the acf_rack limit."
	}
})

Missiles.RegisterItem("AGM-122 ASM", "ARM", {
	Name		= "AGM-122 Sidearm",
	Description	= "A refurbished early-model AIM-9, for attacking ground targets.",
	Model		= "models/missiles/aim9.mdl",
	Length		= 287,
	Caliber		= 127,
	Mass		= 89,
	Diameter	= 3.5 * ACF.InchToMm, -- in mm
	Offset		= Vector(-6, 0, 0),
	Year		= 1986,
	ReloadTime	= 10,
	ExhaustPos  = Vector(-30),
	Racks		= { ["1xRK_small"] = true, ["1xRK"] = true, ["2xRK"] = true, ["4xRK"] = true },
	Guidance	= { Dumb = true, ["Anti-radiation"] = true },
	Navigation  = "Chase",
	Fuzes		= { Contact = true, Optical = true },
	SeekCone	= 10,
	ViewCone	= 20,
	Agility		= 0.0018,
	ArmDelay	= 0.2,
	Round = {
		Model           = "models/missiles/aim9.mdl",
		MaxLength       = 287,
		Armor           = 2,
		ProjLength      = 68,
		PropLength      = 160,
		Thrust          = 800000, -- in kg*in/s^2
		FuelConsumption = 0.02, -- in g/s/f
		StarterPercent  = 0.05,
		MaxAgilitySpeed = 350, -- in m/s
		DragCoef        = 0.015,
		FinMul          = 0.1,
		GLimit          = 20,
		TailFinMul      = 0.001,
		CanDelayLaunch  = true,
		ActualLength    = 113,
		ActualWidth     = 18
	},
	Preview = {
		FOV = 60,
	},
})

Missiles.RegisterItem("AGM-45 ASM", "ARM", {
	Name		= "AGM-45 Shrike",
	Description	= "Long range anti-SAM missile, built on the body of an AIM-7 Sparrow.",
	Model		= "models/missiles/aim120.mdl",
	Length		= 305,
	Caliber		= 203,
	Mass		= 177,
	Diameter	= 6.75 * ACF.InchToMm, -- in mm
	Year		= 1969,
	ReloadTime	= 25,
	ExhaustPos  = Vector(-70),
	Racks		= { ["1xRK"] = true, ["2xRK"] = true, ["4xRK"] = true },
	Guidance	= { Dumb = true, ["Anti-radiation"] = true },
	Navigation  = "Chase",
	Fuzes		= { Contact = true, Timed = true },
	SeekCone	= 5,
	ViewCone	= 10,
	Agility		= 0.012,
	ArmDelay	= 0.3,
	Round = {
		Model           = "models/missiles/aim120.mdl",
		MaxLength       = 305,
		Armor           = 2,
		ProjLength      = 70,
		PropLength      = 200,
		Thrust          = 1500000, -- in kg*in/s^2
		FuelConsumption = 0.020, -- in g/s/f
		StarterPercent  = 0.05,
		MaxAgilitySpeed = 350, -- in m/s
		DragCoef        = 0.02,
		FinMul          = 0.2,
		GLimit          = 20,
		TailFinMul      = 0.001,
		CanDelayLaunch  = true,
		ActualLength    = 120,
		ActualWidth     = 26
	},
	Preview = {
		Height = 80,
		FOV    = 60,
	},
})
