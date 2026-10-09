DEFINE_BASECLASS("acf_base_simple")

ENT.ACF_Limit           = 8
ENT.ACF_PreventArmoring = true

ENT.ACF_SteerplateModel = "models/hunter/plates/plate025x025.mdl"

-- Valid values for the string fields below, the first entry of each list is the default
ENT.ACF_SteerBehaviors   = { "Disable", "Neutral", "Continue", "Wire" }
ENT.ACF_WireInputMethods = { "AD", "Steer", "Angle" }
ENT.ACF_AIOInputMethods  = { "AD", "Aim" }

ACF.Entities.AutoRegister(2026100801, function()
	MENU_FIELD("Boolean", "UseAIOController",  { Default = true })
	MENU_FIELD("String",  "InputMethod",       { Default = "AD" })
	MENU_FIELD("Number",  "MaxSteerAngle",     { Min = 0, Max = 90, Default = 25, Decimals = 2 })  -- Degrees, at standstill
	MENU_FIELD("Number",  "MinSteerAngle",     { Min = 0, Max = 90, Default = 15, Decimals = 2 })  -- Degrees, at top speed
	MENU_FIELD("Number",  "TopSpeed",          { Min = 1, Max = 300, Default = 70, Decimals = 1 }) -- km/h
	MENU_FIELD("Number",  "TurnRate",          { Min = 1, Max = 720, Default = 160, Decimals = 1 }) -- Degrees per second
	MENU_FIELD("String",  "InactiveBehavior",  { Default = "Disable" })
	MENU_FIELD("String",  "BrakeBehavior",     { Default = "Disable" })
	MENU_FIELD("String",  "WaterBehavior",     { Default = "Disable" })
	     FIELD("Number",  "SteerAngle",        { Min = -90, Max = 90, Default = 0 }) -- Current steer angle, saved so dupes come back steered
	LINKED_ENTITY_FIELD("Baseplate",           { AcceptableClasses = { acf_baseplate = true } })
	LINKED_ENTITY_ARRAY_FIELD("Wheels",        { AcceptableClasses = { prop_physics = true } })
end, "Steer Plate")

ENT.ACF_StaticWireInputs = {
	"Active (Steering is enabled while this is non-zero, or unwired.)",
	"Brake (Whether the vehicle is braking.)",
	"InWater (Whether the vehicle is in water, only read when the in water behavior is wire provided.)",
	"A (Steers left while non-zero, with the A/D input method.)",
	"D (Steers right while non-zero, with the A/D input method.)",
	"Steer (Steering amount from -1 for full left to 1 for full right, with the Steer input method.)",
	"Angle (World heading to steer towards, with the World Angle input method.) [ANGLE]",
}

ENT.ACF_StaticWireOutputs = {
	"SteerAngle (Current steer angle relative to the baseplate, positive is left.)",
	"Entity (The steer plate itself.) [ENTITY]",
}
