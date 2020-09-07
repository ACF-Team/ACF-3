ACF.RegisterEngineType("Electric", {
	Name		= "Generic Electric Engine",
	Efficiency	= 0.85, --percent efficiency converting chemical kw into mechanical kw
	TorqueScale	= 0.5,
	HealthMult	= 0.75,
	CalculatePeakEnergy = function(Entity)
		-- Adjust torque to 1 rpm maximum, assuming a linear decrease from a max @ 1 rpm to min @ limiter
		local peakkw = (Entity.PeakTorque * (1 + Entity.PeakMaxRPM / Entity.LimitRPM)) * Entity.LimitRPM / (4 * 9548.8)
		local PeakKwRPM = math.floor(Entity.LimitRPM * 0.5)

		return peakkw, PeakKwRPM
	end,
	CalculateFuelUsage = function(Entity)
		-- Electric engines use current power output, not max
		return ACF.FuelRate / Entity.Efficiency * 3600
	end
})
