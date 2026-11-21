DEFINE_BASECLASS("acf_base_simple")

ACF.Entities.AutoRegister(2026091001, function()
	MENU_FIELD("ACF.Turrets.Gyro", "Gyro", {
		Title                     = "#acf.menu.fields.acf_turret_gyro.gyro",
		InstantiateTypeForDefault = "ACF.Turrets.Gyro.Single",
		OnlyAllowSubtypes         = true,
	})
end, "Turret Gyro")

ENT.ACF_StaticWireOutputs = {
	"Entity (The gyroscope itself.) [ENTITY]",
}
