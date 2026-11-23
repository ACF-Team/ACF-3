ACF.Classes.DefineClass("ACF.FuelTypes.Diesel", "ACF.FuelTypes.FuelType", function(CLASS)
    CLASS.ID          = "Diesel"
    CLASS.Name        = "Diesel Fuel"
    CLASS.Density     = 0.832 -- kg/L at 15 C, middle of EN 590's 0.820-0.845
    CLASS.ArmorType  = "Diesel"
    CLASS.IsExplosive = false
end)
