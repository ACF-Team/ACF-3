DEFINE_BASECLASS("acf_base_simple")

ENT.Author    = "LiddulBOFH"
ENT.ACF_Limit = 4

ACF.AutoRegisterV2(function()
	MENU_FIELD("ACF.Sensors.Receiver", "Sensor", {
		InstantiateTypeForDefault = "ACF.Sensors.Receiver.Warning.Laser",
		OnlyAllowSubtypes         = true,
	})
end, "Receiver")

ENT.ACF_StaticWireOutputs = {
	"Detected (Returns 1 if something is detected.)",
	"Direction (The direction to a source.) [VECTOR]",
	"Angle (The direction to a source.) [ANGLE]",
	"Entity (The receiver itself.) [ENTITY]",
}
