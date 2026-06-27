local ACF         = ACF
local Classes     = ACF.Classes
Classes.DefineClass("ACF.EngineTypes.Electric", "ACF.EngineTypes.BaseEngineType", function()
	CLASS.Name        = "Generic Electric Engine"
	CLASS.Efficiency  = 0.85 --percent efficiency converting chemical kw into mechanical kw
	CLASS.TorqueScale = 0.5
	CLASS.TorqueCurve = { 1, 0.5, 0 }
	CLASS.HealthMult  = 0.75

	function CLASS.CalculateFuelUsage(Entity)
		-- Electric engines use current power output, not max
		return ACF.FuelRate * Entity.Efficiency / 3600
	end
end)