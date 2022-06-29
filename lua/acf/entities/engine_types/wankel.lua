local EngineTypes = ACF.Classes.EngineTypes


EngineTypes.Register("Wankel", {
	Name        = "Generic Wankel Engine",
	Efficiency  = 0.335,
	TorqueScale = 0.2,
	TorqueCurve = { 0.35, 0.7, 0.85, 0.95, 1, 0.9, 0.7 },
	HealthMult  = 0.125,
})
