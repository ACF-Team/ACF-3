ACF.RegisterEngineType("Turbine", {
	Name		= "Generic Turbine",
	Efficiency	= 0.375, -- previously 0.231
	TorqueScale	= 0.2,
	TorqueCurve = {0.8, 1, 0.9, 0.8, 0.6, 0.4, 0.2, 0.1},
	HealthMult	= 0.125,
})
