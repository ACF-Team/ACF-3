DEFINE_BASECLASS("acf_base_simple")

ENT.ACF_Limit = 20

ACF.AutoRegisterV2(function()
	MENU_FIELD("ACF.Turrets.Gyro", "Gyro", {
		InstantiateTypeForDefault = "ACF.Turrets.Gyro.Single",
		OnlyAllowSubtypes         = true,
	})
end, "Turret Gyro")

ENT.ACF_StaticWireOutputs = {
	"Entity (The gyroscope itself.) [ENTITY]",
}
