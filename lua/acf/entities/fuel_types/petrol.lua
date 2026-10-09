ACF.Classes.DefineClass("ACF.FuelTypes.Petrol", "ACF.FuelTypes.FuelType", function(CLASS)
	CLASS.ID				= "Petrol"
	CLASS.Name				= "Petrol Fuel"
	CLASS.Density			= 0.755	-- kg/L
	CLASS.SpecificEnergy	= 46.4		-- MJ/kg
	CLASS.Stoichiometric	= 14.7		-- Air to fuel ratio (value / fuel)
	CLASS.FlashPoint		= -45.0	-- Temperature (C) at which ignitable vapors come off the fluid
	CLASS.AutoIgnition		= 280.0	-- Temperature (C) at which it combusts without an ignition source
	CLASS.ArmorType			= "Petrol"
end)
