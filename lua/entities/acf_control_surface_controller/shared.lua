DEFINE_BASECLASS("acf_base_scalable")

ENT.PrintName           = "ACF Control Surface Controller"
ENT.WireDebugName       = "ACF Control Surface Controller"
ENT.PluralName          = "ACF Control Surface Controllers"
ENT.ACF_Limit           = 4
ENT.ACF_PreventArmoring = true

ACF.Entities.AutoRegisterV2(function(CLASS)
	function CLASS:VerifyData()
	end
end, "Control Surface Controller", "Control Surface Controllers")

-- The controller aims the airframe. It takes any ONE of three interchangeable aim inputs (whichever
-- triggers last wins) and drives the linked control surfaces to point the baseplate's nose at it. No PID
-- tuning: it learns each airframe's control response online.
ENT.ACF_StaticWireInputs = {
	"Active (Enable the controller when non-zero.)",
	"AimDirection (A world-space direction to point the nose at.) [VECTOR]",
	"AimPos (A world-space position to point the nose at.) [VECTOR]",
	"AimAngle (A global angle whose forward is the aim direction.) [ANGLE]",
}

ENT.ACF_StaticWireOutputs = {
	"Pitch (Normalised pitch command sent to the surfaces, -1 to 1.)",
	"Yaw (Normalised yaw command, -1 to 1.)",
	"Roll (Normalised roll command, -1 to 1.)",
	"Heading (Heading error to the aim, in degrees.)",
	"Elevation (Elevation error to the aim, in degrees.)",
	"Entity (The controller itself.) [ENTITY]",
}
