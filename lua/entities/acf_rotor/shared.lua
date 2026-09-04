DEFINE_BASECLASS("acf_base_scalable")

ENT.PrintName           = "ACF Main Rotor"
ENT.WireDebugName       = "ACF Main Rotor"
ENT.PluralName          = "ACF Main Rotors"
ENT.ACF_Limit           = 4
ENT.ACF_PreventArmoring = true

ACF.Entities.AutoRegisterV2(function(CLASS)
	-- Number of blades (2-5). More blades = more lift for a given disc, at more torque draw and mass.
	MENU_FIELD("Number", "Blades", {Min = 2, Max = 5, Default = 2, Decimals = 0})
	-- Rotor diameter in meters. Lift scales with D^4 but torque draw with D^5: a big rotor hovers heavy
	-- loads but needs a high-torque, low-RPM drivetrain (and the reaction torque it dumps on the hull grows).
	MENU_FIELD("Number", "Diameter", {Min = 3, Max = 10, Default = 6, Decimals = 1})

	function CLASS:VerifyData()
	end
end, "Main Rotor", "Main Rotors")

-- Collective sets how much of the rotor's thrust is made (the up/down control). Cyclic tilts the thrust
-- disc for translation/aim -- a Control Surface Controller drives cyclic to point the craft, or wire it.
ENT.ACF_StaticWireInputs = {
	"Collective (Thrust fraction 0..1: the helicopter's up/down/throttle control.)",
	"CyclicPitch (Fore/aft disc tilt, -1..1. Usually driven by a Control Surface Controller.)",
	"CyclicRoll (Left/right disc tilt, -1..1. Usually driven by a Control Surface Controller.)",
}

ENT.ACF_StaticWireOutputs = {
	"RPM (Current rotor RPM.)",
	"Thrust (Current thrust produced, in Newtons.)",
	"Entity (The rotor itself.) [ENTITY]",
}
