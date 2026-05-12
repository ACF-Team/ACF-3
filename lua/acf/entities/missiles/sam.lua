local Missiles = ACF.Classes.Missiles

Missiles.Register("SAM", {
	Name		= "Surface-To-Air Missiles",
	Description	= "Missiles specialized for surface-to-air operation, and well suited to lower altitude operation against ground attack aircraft.",
	Sound		= "acf_missiles/missiles/missile_rocket.mp3",
	Effect		= "Rocket Motor",
	Spread		= 1,
	Blacklist	= { "AP", "APHE", "HEAT", "HP", "FL", "SM" },
	LimitConVar = {
		Name = "_acfm_sam",
		Amount = 8,
		Text = "Maximum number of surface-to-air missiles that can be loaded at once. Differentiates from the acf_rack limit."
	}
})

Missiles.RegisterItem("FIM-92 SAM", "SAM", {
	Name		= "FIM-92 Stinger",
	Description	= "The FIM-92 Stinger is a lightweight and versatile close-range air defense missile.",
	Model		= "models/missiles/fim_92.mdl",
	Length		= 152,
	Caliber		= 70,
	Mass		= 10,
	Year		= 1978,
	ReloadTime	= 10,
	ExhaustPos  = Vector(-29),
	Racks		= { ["1x FIM-92"] = true, ["2x FIM-92"] = true, ["4x FIM-92"] = true },
	Guidance	= { Dumb = true, Infrared = true, ["Anti-missile"] = true },
	Navigation  = "PN",
	Fuzes		= { Contact = true, Radio = true },
	SeekCone	= 7.5,
	ViewCone	= 30,
	Agility		= 0.0002,
	ArmDelay	= 0.2,
	Round = {
		Model           = "models/missiles/fim_92.mdl",
		RackModel       = "models/missiles/fim_92_folded.mdl",
		MaxLength       = 152,
		Armor           = 2,
		ProjLength      = 60,
		PropLength      = 80,
		Thrust          = 200000, -- in kg*in/s^2
		FuelConsumption = 0.012, -- in g/s/f
		StarterPercent  = 0.1,
		MaxAgilitySpeed = 200, -- in m/s
		DragCoef        = 0.0015,
		FinMul          = 0.03,
		GLimit          = 20,
		TailFinMul      = 0.001,
		ActualLength    = 60,
		ActualWidth     = 5
	},
	Preview = {
		Height = 80,
		FOV    = 60,
	},
})

Missiles.RegisterItem("Strela-1 SAM", "SAM", {
	Name		= "9M31 Strela-1",
	Description	= "The 9M31 Strela-1 (SA-9 Gaskin) is a medium-range homing SAM, best suited to ground vehicles or stationary units.",
	Model		= "models/missiles/9m31.mdl",
	Length		= 180,
	Caliber		= 120,
	Mass		= 30,
	Year		= 1960,
	ReloadTime	= 25,
	ExhaustPos  = Vector(-44),
	Racks		= { ["1x Strela-1"] = true, ["2x Strela-1"] = true, ["4x Strela-1"] = true },
	Guidance	= { Dumb = true, Infrared = true, ["Anti-missile"] = true },
	Navigation  = "APN",
	Fuzes		= { Contact = true, Radio = true },
	SeekCone	= 20,
	ViewCone	= 40,
	Agility		= 0.0006,
	ArmDelay	= 0.2,
	Round = {
		Model           = "models/missiles/9m31.mdl",
		RackModel       = "models/missiles/9m31f.mdl",
		IgnoreRackModel = true, -- Ignore the rack model when determining the size of the round for ammo crates
		MaxLength       = 180,
		Armor           = 2,
		ProjLength      = 60,
		PropLength      = 100,
		Thrust          = 800000, -- in kg*in/s^2
		FuelConsumption = 0.018, -- in g/s/f
		StarterPercent  = 0.1,
		MaxAgilitySpeed = 300, -- in m/s
		DragCoef        = 0.003,
		FinMul          = 0.04,
		GLimit          = 20,
		TailFinMul      = 0.001,
		ActualLength    = 71,
		ActualWidth     = 5
	},
	Preview = {
		Height = 60,
		FOV    = 60,
	},
})
