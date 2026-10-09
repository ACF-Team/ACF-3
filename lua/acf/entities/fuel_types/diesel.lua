ACF.Classes.DefineClass("ACF.FuelTypes.Diesel", "ACF.FuelTypes.FuelType", function(CLASS)
	CLASS.ID				= "Diesel"
	CLASS.Name				= "Diesel Fuel"
	CLASS.Density			= 0.832	-- kg/L
	CLASS.SpecificEnergy	= 45.6		-- MJ/kg
	CLASS.Stoichiometric	= 14.5		-- Air to fuel ratio (value / fuel)
	CLASS.FlashPoint		= 52.0		-- Temperature (C) at which ignitable vapors come off the fluid
	CLASS.AutoIgnition		= 210.0	-- Temperature (C) at which it combusts without an ignition source
	CLASS.ArmorType			= "Diesel"
	CLASS.IsExplosive		= false
end)
