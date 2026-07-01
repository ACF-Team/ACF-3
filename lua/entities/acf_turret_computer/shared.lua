DEFINE_BASECLASS("acf_base_simple")

ENT.ACF_Limit = 4

ACF.Entities.AutoRegisterV2(function()
	MENU_FIELD("ACF.Turrets.Computer", "Computer", {
		InstantiateTypeForDefault = "ACF.Turrets.Computer.Direct",
		OnlyAllowSubtypes         = true,
	})
end, "Ballistic Computer")

ENT.ACF_StaticWireInputs = {
	"Calculate (Starts the simulation, continues calculating if capable while enabled.)",
	"Position (The position to calculate a trajectory for.) [VECTOR]",
	"Velocity (The relative velocity to include in the calculation.) [VECTOR]",
}

ENT.ACF_StaticWireOutputs = {
	"Angle (Angle the gun should point in to hit the target) [ANGLE]",
	"Flight Time (The estimated time of arrival for the current round to hit the target.)",
	"Status (The current status of the computer) [STRING]",
	"Entity (The computer itself.) [ENTITY]",
}
