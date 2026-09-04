DEFINE_BASECLASS("acf_base_scalable")

ENT.PrintName           = "ACF Tail Rotor"
ENT.WireDebugName       = "ACF Tail Rotor"
ENT.PluralName          = "ACF Tail Rotors"
ENT.ACF_Limit           = 4
ENT.ACF_PreventArmoring = true

ACF.Entities.AutoRegisterV2(function(CLASS)
	-- Size scales the sideways thrust (authority ~ size^2). Mount it out on the tail boom for a long arm.
	MENU_FIELD("Number", "Size", {Min = 0.5, Max = 3, Default = 1, Decimals = 2})

	function CLASS:VerifyData()
	end
end, "Tail Rotor", "Tail Rotors")

-- The tail rotor makes sideways thrust at its position: it both COUNTERS the main rotor's reaction torque
-- (anti-torque, automatic) and provides YAW control. Destroy it and the main reaction spins the craft.
ENT.ACF_StaticWireInputs = {
	"Yaw (Yaw command, -1..1. Usually driven by a Control Surface Controller.)",
}

ENT.ACF_StaticWireOutputs = {
	"Entity (The tail rotor itself.) [ENTITY]",
}
