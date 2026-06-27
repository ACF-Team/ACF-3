local ACF         = ACF
local Classes     = ACF.Classes
Classes.DefineClass("ACF.EngineTypes.Wankel", "ACF.EngineTypes.BaseEngineType", function()
	CLASS.Name        = "Generic Wankel Engine"
	CLASS.Efficiency  = 0.335
	CLASS.TorqueScale = 0.2
	CLASS.TorqueCurve = { 0.35, 0.7, 0.85, 0.95, 1, 0.9, 0.7 }
	CLASS.HealthMult  = 0.125
end)