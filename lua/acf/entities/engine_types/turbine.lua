local ACF         = ACF
local Classes     = ACF.Classes
Classes.DefineClass("ACF.EngineTypes.Turbine", "ACF.EngineTypes.BaseEngineType", function()
	CLASS.Name        = "Generic Turbine"
	CLASS.Efficiency  = 0.375 -- previously 0.231
	CLASS.TorqueScale = 0.2
	CLASS.TorqueCurve = { 1, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1 }
	CLASS.HealthMult  = 0.125
end)
