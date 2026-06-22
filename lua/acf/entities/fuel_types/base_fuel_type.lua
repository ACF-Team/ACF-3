ACF.Classes.DefineClass("ACF.FuelTypes.FuelType", function()
    CLASS.ID          = "FuelType"
    CLASS.Name        = "Fuel Type"
    CLASS.Density     = 0.832 -- kg per liter (or kg per kWh for electric)
    CLASS.IsExplosive = true
    CLASS.IsElectric  = false

    -- Optional display hooks (overridden by subtypes, e.g. Electric):
    --   CLASS.ConsumptionText(PeakkW, _, Efficiency) -> string
    --   CLASS.FuelTankText(Capacity, Mass[, EmptyMass]) -> string
    --   CLASS.FuelTankOverlay(Fuel, State)
end)
