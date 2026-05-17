local Missiles = ACF.Classes.Missiles

Missiles.Register("ARTY", {
	Name		= "Artillery Rockets",
	Description	= "Artillery rockets provide massive HE delivery over a broad area, with arcing ballistic trajectories and limited guidance.",
	Sound		= "acf_missiles/missiles/missile_rocket.mp3",
	Effect		= "Rocket Motor",
	Spread		= 1,
	Blacklist	= { "AP", "APHE", "HP", "FL", "SM" },
	LimitConVar = {
		Name = "_acfm_arty",
		Amount = 12,
		Text = "Maximum number of artillery rockets that can be loaded at once. Differentiates from the acf_rack limit."
	}
})

Missiles.RegisterItem("Type 63 RA", "ARTY", {
	Name		= "Type 63 Rocket",
	Description	= "A common artillery rocket in the third world, able to be launched from a variety of platforms with a painful whallop and a very arced trajectory.",
	Model		= "models/missiles/glatgm/mgm51.mdl",
	Caliber		= 107,
	Mass		= 19,
	Length		= 80,
	Year		= 1960,
	ReloadTime	= 10,
	ExhaustPos  = Vector(-24),
	Racks		= { ["1xRK_small"] = true, ["1xRK"] = true, ["2xRK"] = true, ["4xRK"] = true, ["6xUARRK"] = true },
	Guidance	= { Dumb = true },
	Navigation  = "Chase",
	Fuzes		= { Contact = true, Timed = true, Optical = true, Altitude = true, Cluster = true },
	ViewCone	= 180,
	Agility		= 0.08,
	ArmDelay	= 0.2,
	Round = {
		Model           = "models/missiles/glatgm/mgm51.mdl",
		MaxLength       = 80,
		Armor           = 2,
		ProjLength      = 35,
		PropLength      = 45,
		Thrust          = 5000, -- in kg*in/s^2
		FuelConsumption = 0.06, -- in g/s/f
		StarterPercent  = 0.9,
		MaxAgilitySpeed = 100, -- in m/s
		DragCoef        = 0.005,
		FinMul          = 0,
		GLimit          = 10,
		TailFinMul      = 20,
		PenMul          = 2,
		CanDelayLaunch  = true,
		ActualLength    = 80,
		ActualWidth     = 10.7
	},
	Preview = {
		Height = 100,
		FOV    = 60,
	},
})

Missiles.RegisterItem("SAKR-10 RA", "ARTY", {
	Name		= "SAKR-10 Rocket",
	Description	= "A short-range but formidable artillery rocket, based upon the Grad. Well suited to the backs of trucks.",
	Model		= "models/missiles/hvar_folded.mdl",
	Caliber		= 122,
	Mass		= 56,
	Length		= 287,
	Year		= 1980,
	ReloadTime	= 20,
	ExhaustPos  = Vector(-44),
	Racks		= { ["1xRK"] = true, ["2xRK"] = true, ["4xRK"] = true, ["6xUARRK"] = true },
	Guidance	= { Dumb = true, Laser = true, ["GPS Guided"] = true },
	Navigation  = "Chase",
	Fuzes		= { Contact = true, Timed = true, Optical = true, Altitude = true },
	Agility		= 0.001,
	ViewCone	= 45,
	ArmDelay	= 0.4,
	Round = {
		Model           = "models/missiles/hvar_folded.mdl",
		RackModel       = "models/missiles/hvar_folded.mdl",
		MaxLength       = 287,
		Armor           = 2,
		ProjLength      = 100,
		PropLength      = 160,
		Thrust          = 800000, -- in kg*in/s^2
		FuelConsumption = 0.020, -- in g/s/f
		StarterPercent  = 0.05,
		MaxAgilitySpeed = 50, -- in m/s
		DragCoef        = 0.2,
		FinMul          = 0.065,
		GLimit          = 10,
		TailFinMul      = 30,
		PenMul          = 1.2,
		CanDelayLaunch  = true,
		ActualLength    = 113,
		ActualWidth     = 4.6
	},
	Preview = {
		Height = 60,
		FOV    = 60,
	},
})

Missiles.RegisterItem("SS-40 RA", "ARTY", {
	Name		= "SS-40 Rocket",
	Description	= "A large, heavy, guided artillery rocket for taking out stationary or dug-in targets. Slow to load, slow to fire, slow to guide, and slow to arrive.",
	Model		= "models/missiles/hvar_folded.mdl",
	Caliber		= 180,
	Mass		= 152,
	Length		= 370,
	Year		= 1983,
	ReloadTime	= 30,
	ExhaustPos  = Vector(-70),
	Racks		= { ["1xRK"] = true, ["2xRK"] = true, ["4xRK"] = true, ["6xUARRK"] = true },
	Guidance	= { Dumb = true, Laser = true, ["GPS Guided"] = true },
	Navigation  = "PN",
	Fuzes		= { Contact = true, Timed = true, Optical = true, Altitude = true },
	Agility		= 0.004,
	ViewCone	= 45,
	ArmDelay	= 0.6,
	Round = {
		Model           = "models/missiles/hvar_folded.mdl",
		RackModel       = "models/missiles/hvar_folded.mdl",
		MaxLength       = 370,
		Armor           = 2,
		ProjLength      = 140,
		PropLength      = 200,
		Thrust          = 2400000, -- in kg*in/s^2
		FuelConsumption = 0.022, -- in g/s/f
		StarterPercent  = 0.05,
		MaxAgilitySpeed = 50, -- in m/s
		DragCoef        = 0.3,
		FinMul          = 0.08,
		GLimit          = 10,
		TailFinMul      = 50,
		PenMul          = 1.4,
		CanDelayLaunch  = true,
		ActualLength    = 146,
		ActualWidth     = 6.75
	},
	Preview = {
		Height = 80,
		FOV    = 60,
	},
})
