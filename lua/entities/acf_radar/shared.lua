DEFINE_BASECLASS("acf_base_simple")

ENT.Author    = "Bubbus"
ENT.ACF_Limit = 4

ACF.AutoRegisterV2(function()
	MENU_FIELD("ACF.Sensors.Radar", "Sensor", {
		InstantiateTypeForDefault = "ACF.Sensors.Radar.Targeting.SmallDirectional",
		OnlyAllowSubtypes         = true,
	})
end, "Radar")

ENT.ACF_StaticWireInputs = {
	"Active (If set to a non-zero value, attempts to start the radar activation.)",
}

ENT.ACF_StaticWireOutputs = {
	"Scanning (Returns 1 if the radar is currently scanning.)",
	"Detected (Returns the amount of targets detected by the radar.)",
	"ClosestDistance (Returns the distance in inches of the closest target detected by the radar.)",
	"IDs (Returns a list of IDs from all the detected targets.) [ARRAY]",
	"Owner (Returns a list of owner names from all the detected targets.) [ARRAY]",
	"Position (Returns a list of position vectors from all the detected targets.) [ARRAY]",
	"Velocity (Returns a list of velocity vectors from all the detected targets.) [ARRAY]",
	"Distance (Returns a list of distances from all the detected targets.) [ARRAY]",
	"Size (Returns a list of diameters, in mm, of all the detected targets.) [ARRAY]",
	"Think Delay (Returns the amount of time in seconds between each scan.)",
	"Entity (The radar itself.) [ENTITY]",
}
