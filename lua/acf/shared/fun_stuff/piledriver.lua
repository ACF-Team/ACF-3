ACF.RegisterPiledriverClass("PD", {
	Name        = "Piledriver",
	Description = "Formerly a piece of construction equipment, it was modified to be used in close-quarters combat. Doesn't actually drive piles.",
	Model       = "models/piledriver/piledriver_100mm.mdl",
	IsScalable  = true,
	Caliber = {
		Base = 100,
		Min  = 50,
		Max  = 300,
	},
	Round = {
		MaxLength = 45,
		PropMass  = 0,
	}
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
