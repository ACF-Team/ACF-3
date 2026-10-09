-- 85% ethanol with remainder 15% gasoline
-- ethanol autoignition 363C flashpoint 63C

ACF.Classes.DefineClass("ACF.FuelTypes.E85", "ACF.FuelTypes.FuelType", function(CLASS)
	CLASS.ID				= "E85"
	CLASS.Name				= "Gasahol E85"
	CLASS.Density			= 0.779	-- kg/L
	CLASS.SpecificEnergy	= 33.1		-- MJ/kg
	CLASS.Stoichiometric	= 14.7		-- Air to fuel ratio (value / fuel)
	CLASS.FlashPoint		= 8.0		-- Temperature (C) at which ignitable vapors come off the fluid
	CLASS.AutoIgnition		= 350.0	-- Temperature (C) at which it combusts without an ignition source
	CLASS.ArmorType			= "Petrol"
end)