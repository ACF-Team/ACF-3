local ACF         = ACF
local EngineTypes = ACF.Classes.EngineTypes


EngineTypes.Register("Electric", {
	Name        = "Generic Electric Engine",
	Efficiency  = 0.85, --percent efficiency converting chemical kw into mechanical kw
	TorqueScale = 0.5,
	TorqueCurve = { 1, 0.5, 0 },
	HealthMult  = 0.75,
	CalculateFuelUsage = function(Entity)
		-- Electric engines use current power output, not max
		return ACF.FuelRate * Entity.Efficiency / 3600
	end
})
