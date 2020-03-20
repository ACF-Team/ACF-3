ACF.RegisterFuelTankClass("FTS_8", {
	Name		= "Size 8 Container",
	Description	= "Guaranteed to improve engine performance by " .. (ACF.TorqueBoost - 1) * 100 .. "%",
})

do
	ACF.RegisterFuelTank("Tank_8x8x1","FTS_8", {
		Name		= "8x8x1 Container",
		Description	= "Sloshy sloshy!",
		Model		= "models/fueltank/fueltank_8x8x1.mdl",
		SurfaceArea	= 15524.8,
		Volume		= 64794.2,
	})

	ACF.RegisterFuelTank("Tank_8x8x2","FTS_8", {
		Name		= "8x8x2 Container",
		Description	= "What's global warming?",
		Model		= "models/fueltank/fueltank_8x8x2.mdl",
		SurfaceArea	= 18086.4,
		Volume		= 125868.9,
	})

	ACF.RegisterFuelTank("Tank_8x8x4","FTS_8", {
		Name		= "8x8x4 Container",
		Description	= "Tank Tank.",
		Model		= "models/fueltank/fueltank_8x8x4.mdl",
		SurfaceArea	= 23957.6,
		Volume		= 246845.3,
	})
end
