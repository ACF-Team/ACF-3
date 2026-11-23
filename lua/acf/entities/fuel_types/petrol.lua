ACF.Classes.DefineClass("ACF.FuelTypes.Petrol", "ACF.FuelTypes.FuelType", function(CLASS)
    CLASS.ID      = "Petrol"
    CLASS.Name    = "Petrol Fuel"
    CLASS.Density = 0.745 -- kg/L at 15 C, middle of EN 228's 0.720-0.775
    CLASS.ArmorType  = "Petrol"
end)
