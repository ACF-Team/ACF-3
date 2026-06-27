local ACF         = ACF
local Classes     = ACF.Classes
Classes.DefineClass("ACF.EngineTypes.GenericPetrol", "ACF.EngineTypes.BaseEngineType", function()
	CLASS.Name        = "Generic Petrol Engine"
	CLASS.Efficiency  = 0.304 --kg per kw hr
	CLASS.TorqueScale = 0.25
	CLASS.TorqueCurve = { 0.4, 0.65, 0.85, 1, 0.9, 0.6 }
	CLASS.HealthMult  = 0.2
end)
