ACF.Classes.DefineClass("ACF.FuelTypes.Electric", "ACF.FuelTypes.FuelType", function(CLASS)
    CLASS.ID         = "Electric"
    CLASS.Name       = "Lit-Ion Battery"
    CLASS.Density    = 3.89
    CLASS.ArmorType  = "LiIon"
    CLASS.IsElectric = true

    CLASS.CanSelfSeal  = false -- No liquid to seal in
    CLASS.Suppressible = false -- Thermal runaway makes its own oxygen, no agent stops it
    CLASS.IgnitionChance = { -- Scaled by how much of the pack the hit destroyed, see ACF.BatteryIgnitionScale
        Hit  = 0.25,
        Jet  = 0.8,
        Fire = 1,
    }

    -- Thermal runaway burns the cells in place, nothing pours out
    function CLASS:GetLeakRate()
        return 0
    end

    function CLASS:Release() end

    function CLASS:IsExposed()
        return false
    end

    function CLASS:CanBurn(Tank)
        return Tank.Amount > 0
    end

    --- @param Damaged number Fraction of the pack the hit destroyed.
    function CLASS:GetIgnitionChance(Source, Damaged)
        return (self.IgnitionChance[Source] or 0) * math.min(1, Damaged * ACF.BatteryIgnitionScale) -- Only wrecked cells run away
    end

    --- Thermal runaway works through the charge, releasing more heat than it stored.
    function CLASS:Burn(Tank, DeltaTime)
        local Burnt = math.min(Tank.Amount, Tank.Capacity * DeltaTime * ACF.FuelBurnRateMult / ACF.BatteryFireDuration)

        if Burnt <= 0 then return end

        Tank:Consume(Burnt)

        return Burnt * 3.6e6 * ACF.BatteryFireHeatRatio / DeltaTime -- kWh to J
    end

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
