ACF.RegisterFuelTankClass("FTS_1", {
	Name		= "Size 1 Container",
	Description	= "Size 1 fuel containers, required for engines to work.",
})

do
	ACF.RegisterFuelTank("Tank_1x1x1","FTS_1", {
		Name		= "1x1x1 Container",
		Description	= "Seriously consider walking.",
		Model		= "models/fueltank/fueltank_1x1x1.mdl",
		SurfaceArea	= 590.5,
		Volume		= 1019.9,
		Shape       = "Box",
		Preview = {
			FOV = 115,
		},
	})

	ACF.RegisterFuelTank("Tank_1x1x2","FTS_1", {
		Name		= "1x1x2 Container",
		Description	= "Will keep a kart running all day.",
		Model		= "models/fueltank/fueltank_1x1x2.mdl",
		SurfaceArea	= 974,
		Volume		= 1983.1,
		Shape       = "Box",
		Preview = {
			FOV = 125,
		},
	})

	ACF.RegisterFuelTank("Tank_1x1x4","FTS_1", {
		Name		= "1x1x4 Container",
		Description	= "Dinghy",
		Model		= "models/fueltank/fueltank_1x1x4.mdl",
		SurfaceArea	= 1777.4,
		Volume		= 3995.1,
		Shape       = "Box",
		Preview = {
			FOV = 125,
		},
	})

	ACF.RegisterFuelTank("Tank_1x2x1","FTS_1", {
		Name		= "1x2x1 Container",
		Description	= "Will keep a kart running all day.",
		Model		= "models/fueltank/fueltank_1x2x1.mdl",
		SurfaceArea	= 995,
		Volume		= 2062.5,
		Shape       = "Box",
		Preview = {
			FOV = 100,
		},
	})

	ACF.RegisterFuelTank("Tank_1x2x2","FTS_1", {
		Name		= "1x2x2 Container",
		Description	= "Dinghy",
		Model		= "models/fueltank/fueltank_1x2x2.mdl",
		SurfaceArea	= 1590.8,
		Volume		= 4070.9,
		Shape       = "Box",
		Preview = {
			FOV = 120,
		},
	})

	ACF.RegisterFuelTank("Tank_1x2x4","FTS_1", {
		Name		= "1x2x4 Container",
		Description	= "Outboard motor.",
		Model		= "models/fueltank/fueltank_1x2x4.mdl",
		SurfaceArea	= 2796.6,
		Volume		= 8119.2,
		Shape       = "Box",
		Preview = {
			FOV = 125,
		},
	})

	ACF.RegisterFuelTank("Tank_1x4x1","FTS_1", {
		Name		= "1x4x1 Container",
		Description	= "Dinghy",
		Model		= "models/fueltank/fueltank_1x4x1.mdl",
		SurfaceArea	= 1745.6,
		Volume		= 3962,
		Shape       = "Box",
		Preview = {
			FOV = 75,
		},
	})

	ACF.RegisterFuelTank("Tank_1x4x2","FTS_1", {
		Name		= "1x4x2 Container",
		Description	= "Clown car.",
		Model		= "models/fueltank/fueltank_1x4x2.mdl",
		SurfaceArea	= 2753.9,
		Volume		= 8018,
		Shape       = "Box",
		Preview = {
			FOV = 105,
		},
	})

	ACF.RegisterFuelTank("Tank_1x4x4","FTS_1", {
		Name		= "1x4x4 Container",
		Description	= "Fuel pancake.",
		Model		= "models/fueltank/fueltank_1x4x4.mdl",
		SurfaceArea	= 4761,
		Volume		= 16030.4,
		Shape       = "Box",
		Preview = {
			FOV = 125,
		},
	})

	ACF.RegisterFuelTank("Tank_1x6x1","FTS_1", {
		Name		= "1x6x1 Container",
		Description	= "Lawn tractors.",
		Model		= "models/fueltank/fueltank_1x6x1.mdl",
		SurfaceArea	= 2535.3,
		Volume		= 5973.1,
		Shape       = "Box",
		Preview = {
			FOV = 60,
		},
	})

	ACF.RegisterFuelTank("Tank_1x6x2","FTS_1", {
		Name		= "1x6x2 Container",
		Description	= "Small tractor tank.",
		Model		= "models/fueltank/fueltank_1x6x2.mdl",
		SurfaceArea	= 3954.1,
		Volume		= 12100.3,
		Shape       = "Box",
	})

	ACF.RegisterFuelTank("Tank_1x6x4","FTS_1", {
		Name		= "1x6x4 Container",
		Description	= "Fuel. Will keep you going for awhile.",
		Model		= "models/fueltank/fueltank_1x6x4.mdl",
		SurfaceArea	= 6743.3,
		Volume		= 24109.4,
		Shape       = "Box",
		Preview = {
			FOV = 115,
		},
	})

	ACF.RegisterFuelTank("Tank_1x8x1","FTS_1", {
		Name		= "1x8x1 Container",
		Description	= "Clown car.",
		Model		= "models/fueltank/fueltank_1x8x1.mdl",
		SurfaceArea	= 3315.5,
		Volume		= 7962.4,
		Shape       = "Box",
		Preview = {
			Height = 80,
			FOV    = 60,
		},
	})

	ACF.RegisterFuelTank("Tank_1x8x2","FTS_1", {
		Name		= "1x8x2 Container",
		Description	= "Gas stations? We don't need no stinking gas stations!",
		Model		= "models/fueltank/fueltank_1x8x2.mdl",
		SurfaceArea	= 5113.7,
		Volume		= 16026.2,
		Shape       = "Box",
		Preview = {
			FOV = 75,
		},
	})

	ACF.RegisterFuelTank("Tank_1x8x4","FTS_1", {
		Name		= "1x8x4 Container",
		Description	= "Beep beep.",
		Model		= "models/fueltank/fueltank_1x8x4.mdl",
		SurfaceArea	= 8696,
		Volume		= 31871,
		Shape       = "Box",
		Preview = {
			FOV = 110,
		},
	})
end
