--	https://en.wikipedia.org/wiki/Jet_fuel	JP-8 is a militarized version of Jet A-1, with some other additives

ACF.Classes.DefineClass("ACF.FuelTypes.JP8", "ACF.FuelTypes.FuelType", function(CLASS)
	CLASS.ID				= "JP8"
	CLASS.Name				= "Jet Propellant 8"
	CLASS.Density			= 0.840	-- kg/L
	CLASS.SpecificEnergy	= 46.4		-- MJ/kg
	CLASS.Stoichiometric	= 14.5		-- Air to fuel ratio (value / fuel)
	CLASS.FlashPoint		= 38.0	-- Temperature (C) at which ignitable vapors come off the fluid
	CLASS.AutoIgnition		= 210.0	-- Temperature (C) at which it combusts without an ignition source
	CLASS.ArmorType			= "Diesel"
	CLASS.IsExplosive		= false
end)