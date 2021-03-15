ACF.RegisterFuelTankClass("FTS_6", {
	Name		= "Size 6 Container",
	Description	= "Size 6 fuel containers, required for engines to work.",
})

do
	ACF.RegisterFuelTank("Tank_6x6x1","FTS_6", {
		Name		= "6x6x1 Container",
		Description	= "Got gas?",
		Model		= "models/fueltank/fueltank_6x6x1.mdl",
		SurfaceArea	= 9405.2,
		Volume		= 37278.5,
		Shape       = "Box",
		Preview = {
			Height = 70,
			FOV    = 60,
		},
	})

	ACF.RegisterFuelTank("Tank_6x6x2","FTS_6", {
		Name		= "6x6x2 Container",
		Description	= "Drive across the desert without a fuck to give.",
		Model		= "models/fueltank/fueltank_6x6x2.mdl",
		SurfaceArea	= 11514.5,
		Volume		= 73606.2,
		Shape       = "Box",
		Preview = {
			FOV = 70,
		},
	})

	ACF.RegisterFuelTank("Tank_6x6x4","FTS_6", {
		Name		= "6x6x4 Container",
		Description	= "May contain Mesozoic ghosts.",
		Model		= "models/fueltank/fueltank_6x6x4.mdl",
		SurfaceArea	= 16028.8,
		Volume		= 143269,
		Shape       = "Box",
		Preview = {
			FOV = 100,
		},
	})

	ACF.RegisterFuelTank("Tank_6x8x1","FTS_6", {
		Name		= "6x8x1 Container",
		Description	= "Conformal fuel tank, does what all its friends do.",
		Model		= "models/fueltank/fueltank_6x8x1.mdl",
		SurfaceArea	= 12131.1,
		Volume		= 48480.2,
		Shape       = "Box",
		Preview = {
			Height = 70,
			FOV    = 60,
		},
	})

	ACF.RegisterFuelTank("Tank_6x8x2","FTS_6", {
		Name		= "6x8x2 Container",
		Description	= "Certified 100% dinosaur juice.",
		Model		= "models/fueltank/fueltank_6x8x2.mdl",
		SurfaceArea	= 14403.8,
		Volume		= 95065.5,
		Shape       = "Box",
		Preview = {
			FOV = 60,
		},
	})

	ACF.RegisterFuelTank("Tank_6x8x4","FTS_6", {
		Name		= "6x8x4 Container",
		Description	= "Will last you a while.",
		Model		= "models/fueltank/fueltank_6x8x4.mdl",
		SurfaceArea	= 19592.4,
		Volume		= 187296.4,
		Shape       = "Box",
		Preview = {
			FOV = 95,
		},
	})
end
