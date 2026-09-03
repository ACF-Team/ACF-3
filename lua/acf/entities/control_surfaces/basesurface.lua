local ACF = ACF

ACF.Classes.DefineClass("ACF.ControlSurfaces.BaseSurface", function(CLASS)
	CLASS.Name        = "Control Surface"
	CLASS.Description  = "Provides control authority about one airframe axis. Effectiveness scales with airspeed."
	CLASS.Model        = "models/holograms/cube.mdl"
	CLASS.Entity       = "acf_control_surface"

	-- Which airframe axis this surface actuates: "Pitch", "Yaw" or "Roll".
	CLASS.ControlAxis  = "Pitch"
	-- Reference planform area (m^2) at SurfaceSize 1; the entity scales it by size^2.
	CLASS.BaseArea     = 2
end)
