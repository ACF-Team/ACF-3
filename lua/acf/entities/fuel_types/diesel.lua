ACF.Classes.DefineClass("ACF.FuelTypes.Diesel", "ACF.FuelTypes.FuelType", function(CLASS)
    CLASS.ID          = "Diesel"
    CLASS.Name        = "Diesel Fuel"
    CLASS.Density     = 0.832
    CLASS.ArmorType  = "Diesel"

    CLASS.IgnitionChance = { -- Won't flash below ~52°C, so it takes a sustained flame or a jet
        Hit        = 0.02,
        Jet        = 0.4,
        Fire       = 0.5,
        HotSurface = 0.1,
    }
end)
