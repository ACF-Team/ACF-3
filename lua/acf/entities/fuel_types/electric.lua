ACF.Classes.DefineClass("ACF.FuelTypes.Electric", "ACF.FuelTypes.BaseFuelType", function()
	CLASS.Name = "Lit-Ion Battery"
	CLASS.ShortName = "Electric"
	CLASS.Density = 3.89
	CLASS.ConsumptionText = function(PeakkW, _, Efficiency)
		local Text = "Peak Energy Consumption :\n%s kW - %s MJ/min"
		local Rate = ACF.FuelRate * PeakkW / Efficiency

		return Text:format(math.Round(Rate, 2), math.Round(Rate * 0.06, 2))
	end
	CLASS.FuelTankText = function(Capacity, Mass)
		local Text = "Tank Armor : %s mm\nCharge : %s kW per hour - %s MJ\nMass : %s"
		local kWh = math.Round(Capacity * ACF.LiIonED, 2)
		local MJ = math.Round(Capacity * ACF.LiIonED * 3.6, 2)

		return Text:format(ACF.ContainerArmor, kWh, MJ, ACF.GetProperMass(Mass))
	end
	CLASS.FuelTankOverlay = function(Fuel, State)
		local KiloWatt = math.Round(Fuel, 2)
		local Joules = math.Round(Fuel * 3.6, 2)
		State:AddKeyValue("Charge Level", ("%s kWh / %s mJ"):format(KiloWatt, Joules))
	end
end)