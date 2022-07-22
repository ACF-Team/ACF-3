local EngineTypes = ACF.Classes.EngineTypes


EngineTypes.Register("GenericDiesel", {
	Name        = "Generic Diesel Engine",
	Efficiency  = 0.243, --up to 0.274
	TorqueScale = 0.35,
	TorqueCurve = { 0.7, 0.96, 1, 0.97, 0.93, 0.82, 0.7, 0.5 },
	HealthMult  = 0.5,
})
