DEFINE_BASECLASS("acf_base_scalable")

ENT.PrintName           = "ACF Control Surface"
ENT.WireDebugName       = "ACF Control Surface"
ENT.PluralName          = "ACF Control Surfaces"
ENT.ACF_Limit           = 16
ENT.ACF_PreventArmoring = true

ACF.Entities.AutoRegisterV2(function(CLASS)
	-- Surface type selects which airframe axis it actuates (Elevator=pitch, Aileron=roll, Rudder=yaw).
	MENU_FIELD("ACF.ControlSurfaces.BaseSurface", "Surface", {OnlyAllowSubtypes = true, InstantiateTypeForDefault = "ACF.ControlSurfaces.Elevator"})
	-- Overall size: lift/authority scale with area (size^2). Bigger surfaces = more control, more mass/hitbox.
	MENU_FIELD("Number", "SurfaceSize", {Min = 0.5, Max = 3, Default = 1, Decimals = 2})
	-- Maximum deflection angle (deg) at full command. Bigger throw = more authority but stalls sooner.
	MENU_FIELD("Number", "MaxDeflection", {Min = 5, Max = 35, Default = 20, Decimals = 0})

	function CLASS:VerifyData()
	end
end, "Control Surface", "Control Surfaces")

-- Deflection is a physical hinge angle in DEGREES, clamped to MaxDeflection. A Control Surface Controller
-- drives it, or wire it by hand for manual control. The surface computes its own aerodynamic force from it.
ENT.ACF_StaticWireInputs = {
	"Deflection (Hinge angle in degrees, clamped to the surface's max. Wire this for manual control.)",
}

ENT.ACF_StaticWireOutputs = {
	"Deflection (Current hinge angle in degrees.)",
	"AoA (Current angle of attack of the surface's airflow, in degrees.)",
	"Entity (The control surface itself.) [ENTITY]",
}

-- Returns the surface instance backing this entity.
function ENT:GetSurface()
	return self:ACF_GetUserVar("Surface")
end
