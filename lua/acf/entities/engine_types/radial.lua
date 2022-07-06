local EngineTypes = ACF.Classes.EngineTypes


EngineTypes.Register("Radial", {
	Name        = "Generic Radial Engine",
	Efficiency  = 0.4, -- 0.38 to 0.53
	TorqueScale = 0.3,
	TorqueCurve = { 0.7, 0.96, 1, 0.97, 0.93, 0.82, 0.7, 0.5 },
	HealthMult  = 0.3,
})
