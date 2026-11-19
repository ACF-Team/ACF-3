DEFINE_BASECLASS("acf_container")

ENT.ACF_Limit = 32

ACF.Entities.AutoRegister(2026091001, function()
	MENU_FIELD("ACF.FuelTypes.FuelType", "FuelType",  {Title = "#acf.menu.fields.acf_fueltank.fuel_type", OnlyAllowSubtypes = true, InstantiateTypeForDefault = "ACF.FuelTypes.Petrol"})
	MENU_FIELD("Number",                 "FuelSizeX", {Title = "#acf.menu.fields.acf_fueltank.fuel_size_x", Min = ACF.ContainerMinSize or 6, Max = ACF.ContainerMaxSize or 96, Default = 24, Decimals = 0})
	MENU_FIELD("Number",                 "FuelSizeY", {Title = "#acf.menu.fields.acf_fueltank.fuel_size_y", Min = ACF.ContainerMinSize or 6, Max = ACF.ContainerMaxSize or 96, Default = 24, Decimals = 0})
	MENU_FIELD("Number",                 "FuelSizeZ", {Title = "#acf.menu.fields.acf_fueltank.fuel_size_z", Min = ACF.ContainerMinSize or 6, Max = ACF.ContainerMaxSize or 96, Default = 24, Decimals = 0})
	MENU_FIELD("Number",                 "FuelPriority", {Title = "#acf.menu.fields.acf_fueltank.fuel_priority", Min = ACF.FuelPriorityMin, Max = ACF.FuelPriorityMax, Default = 1, Decimals = 0})
	-- Shape is inherited from acf_container.
end, "Fuel Tank")

ENT.ACF_StaticWireInputs = {
	"Active (If set to a non-zero value, it'll allow engines to consume fuel from this fuel tank.)",
}

ENT.ACF_StaticWireOutputs = {
	"Activated (Whether or not this fuel tank is able to be used by an engine.)",
	"Fuel (Amount of fuel currently in the tank, in liters or kWh)",
	"Capacity (Total amount of fuel the tank can hold, in liters or kWh)",
	"Leaking (Returns 1 if the fuel tank is currently losing fuel.)",
	"Entity (The fuel tank itself.) [ENTITY]",
}
