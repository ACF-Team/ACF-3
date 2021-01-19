ACF.RegisterFuelType("Electric", {
	Name			= "Lit-Ion Battery",
	Density			= 3.89,
	ConsumptionText	= function(PeakkW, _, Efficiency)
		local Text = "Peak Energy Consumption :\n%s kW - %s MJ/min"
		local Rate = ACF.FuelRate * PeakkW / Efficiency

		return Text:format(math.Round(Rate, 2), math.Round(Rate * 0.06, 2))
	end,
	FuelTankText	= function(Capacity, Mass)
		local Text = "Charge : %s kW per hour - %s MJ\nMass : %s"
		local kWh = math.Round(Capacity * ACF.LiIonED, 2)
		local MJ = math.Round(Capacity * ACF.LiIonED * 3.6, 2)

		return Text:format(kWh, MJ, ACF.GetProperMass(Mass))
	end,
})
