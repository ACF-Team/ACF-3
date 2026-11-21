DEFINE_BASECLASS("acf_base_scalable")

ACF.Entities.AutoRegister(2026091001, function()
	MENU_FIELD("ACF.Turrets.Motor", "Motor", {
		Title                     = "#acf.menu.fields.acf_turret_motor.motor",
		InstantiateTypeForDefault = "ACF.Turrets.Motor.Electric",
		OnlyAllowSubtypes         = true,
	})
	MENU_FIELD("Number", "CompSize", {Title = "#acf.menu.fields.acf_turret_motor.comp_size", Min = 0.5, Max = 6,  Default = 1,  Decimals = 1})
	MENU_FIELD("Number", "Teeth",    {Title = "#acf.menu.fields.acf_turret_motor.teeth", Min = 8,   Max = 48, Default = 12, Decimals = 0})
end, "Turret Motor")

ENT.ACF_StaticWireOutputs = {
	"Entity (The turret motor itself.) [ENTITY]",
}
