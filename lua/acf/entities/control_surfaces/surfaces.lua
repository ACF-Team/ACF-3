local Classes = ACF.Classes

Classes.DefineClass("ACF.ControlSurfaces.Elevator", "ACF.ControlSurfaces.BaseSurface", function(CLASS)
	CLASS.Name        = "Elevator"
	CLASS.Description  = "Horizontal tail surface. Controls pitch (nose up/down)."
	CLASS.ControlAxis  = "Pitch"
	CLASS.BaseArea     = 2
end)

Classes.DefineClass("ACF.ControlSurfaces.Aileron", "ACF.ControlSurfaces.BaseSurface", function(CLASS)
	CLASS.Name        = "Aileron"
	CLASS.Description  = "Wing surface. Controls roll (banking). Fit a pair out on the wings."
	CLASS.ControlAxis  = "Roll"
	CLASS.BaseArea     = 1.5
end)

Classes.DefineClass("ACF.ControlSurfaces.Rudder", "ACF.ControlSurfaces.BaseSurface", function(CLASS)
	CLASS.Name        = "Rudder"
	CLASS.Description  = "Vertical tail surface. Controls yaw (nose left/right)."
	CLASS.ControlAxis  = "Yaw"
	CLASS.BaseArea     = 1.5
end)
