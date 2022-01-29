ACF.RegisterEngineType("GenericDiesel", {
	Name        = "Generic Diesel Engine",
	Efficiency  = 0.243, --up to 0.274
	TorqueScale = 0.35,
	TorqueCurve = { 0.3, 0.9, 0.97, 1, 0.95, 0.9, 0.8, 0.65 },
	HealthMult  = 0.5,
})
