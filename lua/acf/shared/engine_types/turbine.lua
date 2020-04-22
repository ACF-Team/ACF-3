ACF.RegisterEngineType("Turbine", {
	Name		= "Generic Turbine",
	Efficiency	= 0.375, -- previously 0.231
	TorqueScale	= 0.2,
	HealthMult	= 0.125,
	CalculatePeakEnergy = function(Entity)
		-- Adjust torque to 1 rpm maximum, assuming a linear decrease from a max @ 1 rpm to min @ limiter
		local peakkw = (Entity.PeakTorque * (1 + Entity.PeakMaxRPM / Entity.LimitRPM)) * Entity.LimitRPM / (4 * 9548.8)
		local PeakKwRPM = math.floor(Entity.LimitRPM * 0.5)

		return peakkw, PeakKwRPM
	end,
})
