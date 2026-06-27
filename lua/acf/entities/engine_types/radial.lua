local ACF         = ACF
local Classes     = ACF.Classes
Classes.DefineClass("ACF.EngineTypes.Radial", "ACF.EngineTypes.BaseEngineType", function()
	CLASS.Name        = "Generic Radial Engine"
	CLASS.Efficiency  = 0.4 -- 0.38 to 0.53
	CLASS.TorqueScale = 0.3
	CLASS.TorqueCurve = { 0.7, 0.96, 1, 0.97, 0.93, 0.82, 0.7, 0.5 }
	CLASS.HealthMult  = 0.3
end)