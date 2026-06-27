DEFINE_BASECLASS("acf_base_simple")

ACF.Entities.AutoRegisterV2(function()
	-- The engine type this entity represents. Engines aren't scalable, so this is the only config field.
	MENU_FIELD("ACF.Engines.BaseEngine", "Engine", {OnlyAllowSubtypes = true, InstantiateTypeForDefault = "ACF.Engines.5.7-V8"})

	-- Nothing to validate: the Engine field is constrained to ACF.Engines.* subtypes by the serializer.
	function CLASS:VerifyData()
	end
end, "Engine", "Engines")

ENT.ACF_StaticWireInputs = {
	"Active (If set to a non-zero value, it'll attempt to start the engine.)",
	"Throttle (On a range from 0 to 100, defines how much power will be given to the engine.)",
}

ENT.ACF_StaticWireOutputs = {
	"RPM (Current rotations per minute of the engine.)",
	"Torque (Current torque, in nM, output by the engine.)",
	"Power (Current power, in kW, output by the engine.)",
	"Fuel Use (Amount of fuel, in liters per minute, being consumed by the engine.)",
	"Mass (Total mass detected on the vehicle by the engine.)",
	"Physical Mass (Physical mass detected on the vehicle by the engine.)",
	"Entity (The engine itself.) [ENTITY]",
}

-- Returns the engine instance backing this entity.
function ENT:GetEngine()
	return self:ACF_GetUserVar("Engine")
end
