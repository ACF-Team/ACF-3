DEFINE_BASECLASS("acf_container")

ENT.ACF_Limit = 4

ACF.AutoRegisterV2(function() end, "Supply Crate")

ENT.ACF_StaticWireInputs = {
	"Active (If set to a non-zero value, it will allow this unit to supply mass.)",
}

ENT.ACF_StaticWireOutputs = {
	"Activated (Whether or not this unit can supply mass.)",
	"Amount (Current mass stored, in kilograms)",
	"Capacity (Total mass capacity, in kilograms)",
	"Entity (The supply entity itself.) [ENTITY]",
}
