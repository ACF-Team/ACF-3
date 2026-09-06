DEFINE_BASECLASS("acf_base_simple")

ENT.Author    = "Bubbus"
ENT.ACF_Limit = 4

ACF.Entities.AutoRegisterV2(function()
	MENU_FIELD("ACF.Sensors.Radar", "Sensor", {
		InstantiateTypeForDefault = "ACF.Sensors.Radar.Standard.SmallDirectional",
		OnlyAllowSubtypes         = true,
	})

	-- One radar class detects both target types, so what it looks for is set per entity.
	MENU_FIELD("Boolean", "DetectContraptions", {Default = true})
	MENU_FIELD("Boolean", "DetectMissiles",     {Default = true})
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
	"Size (Returns a list of diameters, in inches, of all the detected targets.) [ARRAY]",
	"Type (Returns a list of target types for all detected targets.) [ARRAY]",
	"Think Delay (Returns the amount of time in seconds between each scan.)",
	"Clk (Returns engine.TickCount at the moment of the radar's last scan.)",
	"Entity (The radar itself.) [ENTITY]",
}
