DEFINE_BASECLASS("acf_container")

ENT.ACF_Limit = 32

ACF.Entities.AutoRegisterV2(function()
	MENU_FIELD("ACF.FuelTypes.FuelType", "FuelType",  {OnlyAllowSubtypes = true, InstantiateTypeForDefault = "ACF.FuelTypes.Petrol"})
	MENU_FIELD("Number",                 "FuelSizeX", {Min = ACF.ContainerMinSize or 6, Max = ACF.ContainerMaxSize or 96, Default = 24, Decimals = 0})
	MENU_FIELD("Number",                 "FuelSizeY", {Min = ACF.ContainerMinSize or 6, Max = ACF.ContainerMaxSize or 96, Default = 24, Decimals = 0})
	MENU_FIELD("Number",                 "FuelSizeZ", {Min = ACF.ContainerMinSize or 6, Max = ACF.ContainerMaxSize or 96, Default = 24, Decimals = 0})
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
