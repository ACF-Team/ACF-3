DEFINE_BASECLASS("acf_base_simple")

ENT.PrintName     = "ACF Turret Controller"
ENT.WireDebugName = "ACF Turret Controller"
ENT.PluralName    = "ACF Turret Controllers"

ACF.Entities.AutoRegisterV2(function()
	MENU_FIELD("ACF.Turrets.Controller", "Controller", {
		InstantiateTypeForDefault = "ACF.Turrets.Controller.Lightweight",
		OnlyAllowSubtypes         = true,
	})
end, "Turret Controller", "Turret Controllers")

ENT.ACF_StaticWireOutputs = {
	"Entity (The controller itself.) [ENTITY]",
}
