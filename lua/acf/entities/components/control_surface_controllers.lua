local ACF     = ACF
local Classes = ACF.Classes

function ACF.CreateControlSurfaceControllerMenu(_, Menu)
	Menu:AddLabel("Aims the airframe with no PID tuning: it learns each aircraft's control response online.")
	Menu:AddLabel("Link it (right-click) to ONE baseplate and to your control surfaces.")
	Menu:AddLabel("Feed it any one of AimDirection, AimPos or AimAngle (last one received is used), plus Active.")
end

Classes.DefineClass("ACF.Components.ControlSurfaceController", "ACF.Components.BaseComponent", function(CLASS)
	CLASS.Name        = "Control Surface Controller"
	CLASS.Description  = "Fly-by-wire brain: aims the airframe and drives its control surfaces. Self-tuning."
	CLASS.Model        = "models/holograms/cube.mdl"
	CLASS.Entity       = "acf_control_surface_controller"
	CLASS.CreateMenu   = ACF.CreateControlSurfaceControllerMenu
end)
