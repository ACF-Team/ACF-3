DEFINE_BASECLASS("acf_base_simple")

ENT.Author    = "ACF Team"
ENT.ACF_Limit = 2

ACF.Entities.AutoRegister(2026091001, function()
	MENU_FIELD("ACF.Sensors.IRST", "Sensor", {
		InstantiateTypeForDefault = "ACF.Sensors.IRST.Infrared.Standard",
		OnlyAllowSubtypes         = true,
	})
end, "Infrared Search / Track Sensor", "Infrared Search / Track Sensors")

ENT.ACF_StaticWireInputs = {
	"Active (If set to a non-zero value, attempts to start the sensor activation.)",
	"Pitch (Degrees on the vertical axis to steer the view towards, relative to the sensor.)",
	"Yaw (Degrees on the horizontal axis to steer the view towards, relative to the sensor.)",
	"HitPos (World position to steer the view towards, overrides Pitch and Yaw while non-zero.) [VECTOR]",
}

ENT.ACF_StaticWireOutputs = {
	"Scanning (Returns 1 if the sensor is currently scanning.)",
	"Detected (Returns the amount of targets detected by the sensor.)",
	"ClosestDistance (Returns the distance in inches of the closest target detected by the sensor.)",
	"IDs (Returns a list of IDs from all the detected targets.) [ARRAY]",
	"Owner (Returns a list of owner names from all the detected targets.) [ARRAY]",
	"Position (Returns a list of position vectors from all the detected targets.) [ARRAY]",
	"Velocity (Returns a list of velocity vectors from all the detected targets.) [ARRAY]",
	"Distance (Returns a list of distances from all the detected targets.) [ARRAY]",
	"Size (Returns a list of diameters, in inches, of all the detected targets.) [ARRAY]",
	"Type (Returns a list of target types for all detected targets.) [ARRAY]",
	"Current Pitch (Current degrees on the vertical axis the view is steered to.)",
	"Current Yaw (Current degrees on the horizontal axis the view is steered to.)",
	"Direction (The world direction the sensor is currently looking in.) [VECTOR]",
	"Think Delay (Returns the amount of time in seconds between each scan.)",
	"Clk (Returns engine.TickCount at the moment of the sensor's last scan.)",
	"Entity (The sensor itself.) [ENTITY]",
}
