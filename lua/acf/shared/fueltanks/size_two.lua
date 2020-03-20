ACF.RegisterFuelTankClass("FTS_2", {
	Name		= "Size 2 Container",
	Description	= "Guaranteed to improve engine performance by " .. (ACF.TorqueBoost - 1) * 100 .. "%",
})

do
	ACF.RegisterFuelTank("Tank_2x2x1","FTS_2", {
		Name		= "2x2x1 Container",
		Description	= "Dinghy",
		Model		= "models/fueltank/fueltank_2x2x1.mdl",
		SurfaceArea	= 1592.2,
		Volume		= 4285.2,
	})

	ACF.RegisterFuelTank("Tank_2x2x2","FTS_2", {
		Name		= "2x2x2 Container",
		Description	= "Clown car.",
		Model		= "models/fueltank/fueltank_2x2x2.mdl",
		SurfaceArea	= 2360.4,
		Volume		= 8212.9,
	})

	ACF.RegisterFuelTank("Tank_2x2x4","FTS_2", {
		Name		= "2x2x4 Container",
		Description	= "Mini Cooper.",
		Model		= "models/fueltank/fueltank_2x2x4.mdl",
		SurfaceArea	= 3988.6,
		Volume		= 16362,
	})

	ACF.RegisterFuelTank("Tank_2x4x1","FTS_2", {
		Name		= "2x4x1 Container",
		Description	= "Good bit of go-juice.",
		Model		= "models/fueltank/fueltank_2x4x1.mdl",
		SurfaceArea	= 2808.8,
		Volume		= 8628,
	})

	ACF.RegisterFuelTank("Tank_2x4x2","FTS_2", {
		Name		= "2x4x2 Container",
		Description	= "Mini Cooper.",
		Model		= "models/fueltank/fueltank_2x4x2.mdl",
		SurfaceArea	= 3996.1,
		Volume		= 16761.4,
	})

	ACF.RegisterFuelTank("Tank_2x4x4","FTS_2", {
		Name		= "2x4x4 Container",
		Description	= "Land boat.",
		Model		= "models/fueltank/fueltank_2x4x4.mdl",
		SurfaceArea	= 6397.3,
		Volume		= 32854.4,
	})

	ACF.RegisterFuelTank("Tank_2x6x1","FTS_2", {
		Name		= "2x6x1 Container",
		Description	= "Conformal fuel tank, fits narrow spaces.",
		Model		= "models/fueltank/fueltank_2x6x1.mdl",
		SurfaceArea	= 3861.4,
		Volume		= 12389.9,
	})

	ACF.RegisterFuelTank("Tank_2x6x2","FTS_2", {
		Name		= "2x6x2 Container",
		Description	= "Compact car.",
		Model		= "models/fueltank/fueltank_2x6x2.mdl",
		SurfaceArea	= 5388,
		Volume		= 24127.7,
	})

	ACF.RegisterFuelTank("Tank_2x6x4","FTS_2", {
		Name		= "2x6x4 Container",
		Description	= "Sedan.",
		Model		= "models/fueltank/fueltank_2x6x4.mdl",
		SurfaceArea	= 8485.6,
		Volume		= 47537.2,
	})

	ACF.RegisterFuelTank("Tank_2x8x1","FTS_2", {
		Name		= "2x8x1 Container",
		Description	= "Conformal fuel tank, fits into tight spaces",
		Model		= "models/fueltank/fueltank_2x8x1.mdl",
		SurfaceArea	= 5094.5,
		Volume		= 16831.8,
	})

	ACF.RegisterFuelTank("Tank_2x8x2","FTS_2", {
		Name		= "2x8x2 Container",
		Description	= "Truck.",
		Model		= "models/fueltank/fueltank_2x8x2.mdl",
		SurfaceArea	= 6980,
		Volume		= 32275.9,
	})

	ACF.RegisterFuelTank("Tank_2x8x4","FTS_2", {
		Name		= "2x8x4 Container",
		Description	= "With great capacity, comes great responsibili--VROOOOM",
		Model		= "models/fueltank/fueltank_2x8x4.mdl",
		SurfaceArea	= 10898.2,
		Volume		= 63976,
	})
end
