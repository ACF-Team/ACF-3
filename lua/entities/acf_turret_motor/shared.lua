DEFINE_BASECLASS("acf_base_scalable")

ENT.ACF_Limit = 20

ACF.Entities.AutoRegisterV2(function()
	MENU_FIELD("ACF.Turrets.Motor", "Motor", {
		InstantiateTypeForDefault = "ACF.Turrets.Motor.Electric",
		OnlyAllowSubtypes         = true,
	})
	MENU_FIELD("Number", "CompSize", {Min = 0.5, Max = 6,  Default = 1,  Decimals = 1})
	MENU_FIELD("Number", "Teeth",    {Min = 8,   Max = 48, Default = 12, Decimals = 0})
end, "Turret Motor")

ENT.ACF_StaticWireOutputs = {
	"Entity (The turret motor itself.) [ENTITY]",
}
