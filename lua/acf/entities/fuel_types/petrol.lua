ACF.Classes.DefineClass("ACF.FuelTypes.Petrol", "ACF.FuelTypes.FuelType", function(CLASS)
    CLASS.ID      = "Petrol"
    CLASS.Name    = "Petrol Fuel"
    CLASS.Density = 0.745
    CLASS.ArmorType  = "Petrol"

    CLASS.BurnRate    = 0.055 -- Measured gasoline pools burn at 0.028-0.064
    CLASS.CanFireball = true
    CLASS.IgnitionChance = { -- Flashes far below freezing, so anything hot lights a spill
        Hit        = 0.2,
        Jet        = 0.9,
        Fire       = 1,
        HotSurface = 0.1,
    }
end)
