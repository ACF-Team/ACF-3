local Missiles = ACF.Classes.Missiles

Missiles.Register("GBOMB", {
	Name		= "Gliding Bombs",
	Description	= "Similar to regular free falling bombs, gliding bombs are capable of travelling longer distances.",
	Sound		= "acf_missiles/fx/clunk.mp3",
	NoThrust	= true,
	Spread		= 1,
	Blacklist	= { "AP", "APHE", "HP", "FL" },
	LimitConVar = {
		Name = "_acfm_gbomb",
		Amount = 8,
		Text = "Maximum number of gliding bombs that can be loaded at once. Differentiates from the acf_rack limit."
	}
})

Missiles.RegisterItem("100kgGBOMB", "GBOMB", {
	Name		= "100kg Glide Bomb",
	Description	= "A 200-pound bomb, fitted with fins for a longer reach. Well suited to dive bombing, but bulkier and heavier from its fins.",
	Model		= "models/missiles/micro.mdl",
	Length		= 100,
	Caliber		= 250,
	Mass		= 100,
	Year		= 1939,
	Diameter	= 10.8 * ACF.InchToMm, -- in mm
	ReloadTime	= 15,
	Racks		= { ["1xRK_small"] = true, ["1xRK"] = true, ["2xRK"] = true, ["3xRK"] = true, ["4xRK"] = true },
	Guidance	= { Dumb = true },
	Navigation  = "Chase",
	Fuzes		= { Contact = true, Optical = true},
	ArmDelay	= 1,
	Round = {
		Model           = "models/missiles/micro.mdl",
		MaxLength       = 100,
		Armor           = 5,
		ProjLength      = 65,
		PropLength      = 0,
		Thrust          = 1, -- in kg*in/s^2
		FuelConsumption = 0.1, -- in g/s/f
		StarterPercent  = 0.005,
		MaxAgilitySpeed = 1, -- in m/s
		DragCoef        = 0.02,
		FinMul          = 0.2,
		GLimit          = 1,
		TailFinMul      = 5,
		PenMul          = 1,
		FillerRatio     = 0.78,
		ActualLength    = 100,
		ActualWidth     = 25
	},
	Preview = {
		FOV = 65,
	},
})

Missiles.RegisterItem("250kgGBOMB", "GBOMB", {
	Name		= "250kg Glide Bomb",
	Description	= "A heavy 500lb bomb, fitted with fins for a gliding trajectory better suited to striking point targets.",
	Model		= "models/missiles/fab250.mdl",
	Length		= 150,
	Caliber		= 320,
	Mass		= 250,
	Year		= 1941,
	Diameter	= 14.5 * ACF.InchToMm, -- in mm
	ReloadTime	= 25,
	Racks		= { ["1xRK"] = true, ["2xRK"] = true, ["3xRK"] = true, ["4xRK"] = true },
	Guidance	= { Dumb = true },
	Navigation  = "Chase",
	Fuzes		= { Contact = true, Optical = true},
	ArmDelay	= 1,
	Round = {
		Model           = "models/missiles/fab250.mdl",
		MaxLength       = 150,
		Armor           = 5,
		ProjLength      = 100,
		PropLength      = 0,
		Thrust          = 1, -- in kg*in/s^2
		FuelConsumption = 0.1, -- in g/s/f
		StarterPercent  = 0.005,
		MaxAgilitySpeed = 1, -- in m/s
		DragCoef        = 0.02,
		FinMul          = 0.5,
		GLimit          = 1,
		TailFinMul      = 12,
		PenMul          = 1,
		FillerRatio     = 0.79,
		ActualLength    = 150,
		ActualWidth     = 32
	},
	Preview = {
		FOV = 70,
	},
})
