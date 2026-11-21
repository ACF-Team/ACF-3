DEFINE_BASECLASS("acf_container")

ENT.ACF_Limit = 4

ACF.Entities.AutoRegister(2026091001, function()
	MENU_FIELD("Number", "SupplySizeX", {Title = "#acf.menu.fields.acf_supply.supply_size_x", Min = ACF.ContainerMinSize or 6, Max = ACF.ContainerMaxSize or 96, Default = 24, Decimals = 0})
	MENU_FIELD("Number", "SupplySizeY", {Title = "#acf.menu.fields.acf_supply.supply_size_y", Min = ACF.ContainerMinSize or 6, Max = ACF.ContainerMaxSize or 96, Default = 24, Decimals = 0})
	MENU_FIELD("Number", "SupplySizeZ", {Title = "#acf.menu.fields.acf_supply.supply_size_z", Min = ACF.ContainerMinSize or 6, Max = ACF.ContainerMaxSize or 96, Default = 24, Decimals = 0})
end, "Supply Crate")

ENT.ACF_StaticWireInputs = {
	"Active (If set to a non-zero value, it will allow this unit to supply mass.)",
}

ENT.ACF_StaticWireOutputs = {
	"Activated (Whether or not this unit can supply mass.)",
	"Amount (Current mass stored, in kilograms)",
	"Capacity (Total mass capacity, in kilograms)",
	"Entity (The supply entity itself.) [ENTITY]",
}
