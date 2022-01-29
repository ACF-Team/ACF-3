ACF.RegisterEngineType("GenericPetrol", {
	Name        = "Generic Petrol Engine",
	Efficiency  = 0.304, --kg per kw hr
	TorqueScale = 0.25,
	TorqueCurve = { 0.3, 0.55, 0.7, 0.85, 1, 0.9, 0.7 },
	HealthMult  = 0.2,
})
