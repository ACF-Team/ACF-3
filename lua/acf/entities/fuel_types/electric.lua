ACF.Classes.DefineClass("ACF.FuelTypes.Electric", "ACF.FuelTypes.FuelType", function(CLASS)
    CLASS.ID         = "Electric"
    CLASS.Name       = "Lit-Ion Battery"
    CLASS.Density    = 3.89
    CLASS.ArmorType  = "LiIon"
    CLASS.IsElectric = true

    function CLASS.ConsumptionText(PeakkW, _, Efficiency)
        local Text = "Peak Energy Consumption :\n%s kW - %s MJ/min"
        local Rate = ACF.FuelRate * PeakkW / Efficiency

        return Text:format(math.Round(Rate, 2), math.Round(Rate * 0.06, 2))
    end

    function CLASS.FuelTankText(Capacity, Mass)
        local Text = "Charge : %s kW per hour - %s MJ\nMass : %s"
        local kWh = math.Round(Capacity * ACF.LiIonED, 2)
        local MJ = math.Round(Capacity * ACF.LiIonED * 3.6, 2)

        return Text:format(kWh, MJ, ACF.FormatMass(Mass))
    end

    function CLASS.FuelTankOverlay(Fuel, State)
        local KiloWatt = math.Round(Fuel, 2)
        local Joules = math.Round(Fuel * 3.6, 2)
        State:AddKeyValue("Charge Level", ("%s kWh / %s mJ"):format(KiloWatt, Joules))
    end
end)
