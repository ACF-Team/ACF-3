local Classes = ACF.Classes

Classes.DefineClass("ACF.FuelTypes.FuelType", function(CLASS)
    CLASS.ID          = "FuelType"
    CLASS.Name        = "Fuel Type"
    CLASS.Density     = 0.832 -- kg per liter (or kg per kWh for electric)
    CLASS.IsElectric  = false

    -- Fire
    CLASS.CanSelfSeal      = true -- Whether tanks can have a self-sealing liner
    CLASS.BurnRate         = 0.04 -- kg/m²/s off a large spill (Babrauskas large-pool burning rates)
    CLASS.HeatOfCombustion = 44e6 -- J/kg
    CLASS.CanFireball      = false -- Whether a ruptured, lit tank flashes over
    CLASS.Suppressible     = true -- Whether an extinguisher's agent puts its fire out
    CLASS.IgnitionChance   = {} -- Chance per Hit, Jet or Fire (see ACF.Damage.Fire.GetIgnitionSource); Fire and HotSurface are per second when sustained

    --- @return vector # Inside size of a tank left for fuel once any liner is in.
    function CLASS:GetFuelSpace(Size, SelfSealing)
        if not SelfSealing or not self.CanSelfSeal then return Size end

        return Size - Vector(2, 2, 2) * ACF.FuelSealLiner
    end

    --- @return number # Liters per second escaping the tank's holes.
    function CLASS:GetLeakRate(Tank)
        return Tank:GetOrificeFlow()
    end

    --- Lets fuel out of the tank into the spill around it, which is what actually burns.
    function CLASS:Release(Tank, Liters)
        Tank:Spill(Liters)
    end

    --- @return number # Liters a rupture sprays out to flash over when lit.
    function CLASS:GetFlashAmount(Tank)
        return self.CanFireball and Tank.Amount * ACF.FuelFireballFraction or 0
    end

    --- @return boolean # Whether fuel is out in the open, where flames can reach it.
    function CLASS:IsExposed(Tank)
        return Tank.Leaking > 0 or Tank.Spilled > 0
    end

    --- @return boolean # Whether a tank of this fuel has anything that can burn right now.
    function CLASS:CanBurn(Tank)
        return self:IsExposed(Tank) -- Only spilled fuel burns
    end

    --- Subtypes also get the fraction of the tank the hit destroyed.
    --- @return number # Chance a hit from Source lights the fuel.
    function CLASS:GetIgnitionChance(Source)
        return self.IgnitionChance[Source] or 0
    end

    --- Burns a tank's spill across the area it spread to, so a pool burns down at a steady rate until it's gone.
    --- @return number|nil # Heat released in watts, nil once there's nothing left to burn.
    function CLASS:Burn(Tank, DeltaTime)
        if Tank.Spilled <= 0 then
            if Tank.Leaking > 0 then return 0 end -- More is on its way

            return
        end

        local Burnt = Tank:TakeSpill(self.BurnRate * ACF.FuelBurnRateMult * Tank.PoolArea * DeltaTime)

        return Burnt * self.HeatOfCombustion / DeltaTime
    end

    -- Optional display hooks (overridden by subtypes, e.g. Electric):
    --   CLASS.ConsumptionText(PeakkW, _, Efficiency) -> string
    --   CLASS.FuelTankText(Capacity, Mass[, EmptyMass]) -> string
    --   CLASS.FuelTankOverlay(Fuel, State)
end)
