local ACF         = ACF
local Classes     = ACF.Classes
Classes.DefineClass("ACF.EngineTypes.GenericDiesel", "ACF.EngineTypes.BaseEngineType", function()
	CLASS.Name        = "Generic Diesel Engine"
	CLASS.Efficiency  = 0.243 --up to 0.274
	CLASS.TorqueScale = 0.35
	CLASS.TorqueCurve = { 0.7, 0.96, 1, 0.97, 0.93, 0.82, 0.7, 0.5 }
	CLASS.HealthMult  = 0.5
end)