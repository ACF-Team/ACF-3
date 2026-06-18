DEFINE_BASECLASS("acf_container")

ENT.ACF_Limit = 32

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

ACF.AutoRegisterV2(function()
	FIELD("ACF.FuelTanks.BaseFuelTank", "FuelTankType", { OnlyAllowSubtypes = true, InstantiateTypeForDefault = "ACF.FuelTanks.ScalableFuelTank" })
	MENU_FIELD("ACF.FuelTypes.BaseFuelType", "FuelType", { OnlyAllowSubtypes = true, InstantiateTypeForDefault = "ACF.FuelTypes.Petrol" })
end, "Fuel Tank")