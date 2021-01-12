ACF.RegisterPiledriverClass("PD", {
	Name        = "Piledriver",
	Description = "Formerly a piece of construction equipment, it was modified to be used in close-quarters combat. Doesn't actually drive piles.",
	Model       = "models/piledriver/piledriver_100mm.mdl",
	IsScalable  = true,
	Mass        = 1200, -- Relative to the Base caliber
	MagSize     = 15,
	Cyclic      = 60,
	ChargeRate  = 0.5,
	Caliber = {
		Base = 100,
		Min  = 50,
		Max  = 300,
	},
	Round = {
		MaxLength = 114.3, -- Relative to the Base caliber, in cm
		PropMass  = 0,
	},
	Preview = {
		Position = Vector(0, 0, -5),
		Offset = Vector(45, 45, 20),
		Height = 120,
	},
})

ACF.RegisterPiledriver("75mmPD", "PD", {
	Caliber = 75
})

ACF.RegisterPiledriver("100mmPD", "PD", {
	Caliber = 100
})

ACF.RegisterPiledriver("150mmPD", "PD", {
	Caliber = 150
})

ACF.SetCustomAttachments("models/piledriver/piledriver_100mm.mdl", {
	{ Name = "muzzle", Pos = Vector(20), Ang = Angle() },
	{ Name = "tip", Pos = Vector(65), Ang = Angle() },
})
