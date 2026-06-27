DEFINE_BASECLASS("acf_container")

ENT.ACF_Limit = 4

ACF.Entities.AutoRegisterV2(function()
	MENU_FIELD("Number", "SupplySizeX", {Min = ACF.ContainerMinSize or 6, Max = ACF.ContainerMaxSize or 96, Default = 24, Decimals = 0})
	MENU_FIELD("Number", "SupplySizeY", {Min = ACF.ContainerMinSize or 6, Max = ACF.ContainerMaxSize or 96, Default = 24, Decimals = 0})
	MENU_FIELD("Number", "SupplySizeZ", {Min = ACF.ContainerMinSize or 6, Max = ACF.ContainerMaxSize or 96, Default = 24, Decimals = 0})
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
