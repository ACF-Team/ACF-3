DEFINE_BASECLASS("acf_base_scalable")

ENT.PrintName           = "ACF Propeller"
ENT.WireDebugName       = "ACF Propeller"
ENT.PluralName          = "ACF Propellers"
ENT.ACF_Limit           = 8
ENT.ACF_PreventArmoring = true

ACF.Entities.AutoRegisterV2(function(CLASS)
	-- Number of blades (2-5). More blades = more thrust for a given diameter, but each blade adds
	-- torque draw and mass, so thrust-per-torque (efficiency) drops. Use blades when diameter-limited.
	MENU_FIELD("Number", "Blades", {Min = 2, Max = 5, Default = 3, Decimals = 0})
	-- Propeller diameter in meters. Thrust scales with D^4 but torque draw with D^5, so a bigger prop
	-- is powerful but demands a low-RPM, high-torque drivetrain (and grows heavy fast).
	MENU_FIELD("Number", "Diameter", {Min = 1, Max = 4, Default = 2, Decimals = 1})

	-- Nothing to validate: fields are constrained (min/max/decimals) by the serializer.
	function CLASS:VerifyData()
	end
end, "Propeller", "Propellers")

ENT.ACF_StaticWireOutputs = {
	"RPM (Current shaft RPM driving the propeller.)",
	"Thrust (Current thrust produced, in Newtons.)",
	"Entity (The propeller itself.) [ENTITY]",
}
