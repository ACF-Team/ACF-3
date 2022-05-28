ACF.RegisterEngineType("Radial", {
	Name        = "Generic Radial Engine",
	Efficiency  = 0.4, -- 0.38 to 0.53
	TorqueScale = 0.3,
	TorqueCurve = { 0.7, 0.96, 1, 0.97, 0.93, 0.82, 0.7, 0.5 },
	--TorqueCurve = { 0.6, 0.75, 0.85, 0.95, 0.98, 0.6 },
	HealthMult  = 0.3,
})
