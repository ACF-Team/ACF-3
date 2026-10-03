local ACF     = ACF
local Classes = ACF.Classes

Classes.DefineClass("ACF.Sensors.IRST.Infrared", "ACF.Sensors.IRST", function(CLASS)
	CLASS.Name       = "Infrared Search / Track Sensor"
	CLASS.ID         = "IRST"
	CLASS.Entity     = "acf_irst"
	CLASS.SpawnModel = "models/props_lab/monitor01b.mdl"
end)

Classes.DefineClass("ACF.Sensors.IRST.Infrared.Standard", "ACF.Sensors.IRST.Infrared", function(CLASS)
	CLASS.Name        = "IRST Sensor"
	CLASS.ID          = "IRST-Standard"
	CLASS.Description = "A gimballed infrared sensor with a narrow field of view and unlimited range. Tracks players and contraptions, but needs a clear line of sight to them: terrain, smoke and its own contraption all block its view."
	CLASS.Model       = "models/props_lab/monitor01b.mdl"
	CLASS.Mass        = 30
	CLASS.Cost        = 10
	CLASS.ViewCone    = 2.5 -- Half-angle, in degrees
	CLASS.GimbalCone  = 15 -- Maximum angle the view can be steered away from the sensor's forward axis
	CLASS.SlewRate    = 60 -- Degrees per second
	CLASS.Offset      = Vector(6, -1, 0)
	CLASS.SwitchDelay = 1
	CLASS.ThinkTicks  = 3
	CLASS.Preview     = { FOV = 120 }
end)
