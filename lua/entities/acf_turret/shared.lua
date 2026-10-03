DEFINE_BASECLASS("acf_base_scalable")

ENT.ACF_Limit = 20
ENT.ConvexMaterial = "RHA"

ACF.Entities.AutoRegister(2026100201, function()
	MENU_FIELD("ACF.Turrets.Drive", "Turret", {
		InstantiateTypeForDefault = "ACF.Turrets.Drive.Horizontal",
		OnlyAllowSubtypes         = true,
	})
	MENU_FIELD("Number", "RingSize", {Min = 2,    Max = 512, Default = 60,   Decimals = 2}) -- Bore on actuators
	MENU_FIELD("Number", "MinDeg",   {Min = -180, Max = 0,   Default = -180, Decimals = 1})
	MENU_FIELD("Number", "MaxDeg",   {Min = 0,    Max = 180, Default = 180,  Decimals = 1})
	MENU_FIELD("Number", "MaxSpeed", {Min = 0,    Max = 120, Default = 0,    Decimals = 2})
	MENU_FIELD("Number", "OnAngle",  {Min = -180, Max = 180, Default = 15,   Decimals = 1}) -- Servos only
	MENU_FIELD("Number", "OffAngle", {Min = -180, Max = 180, Default = 0,    Decimals = 1}) -- Servos only
	MENU_FIELD("Number", "Stroke",   {Min = 4,    Max = 72,  Default = 24,   Decimals = 1}) -- Actuators only
end, "Turret Drive", "Turret Drives")

ENT.ACF_StaticWireInputs = {
	"Active (Enables movement of the turret.)",
	"Angle (Global angle for the turret to attempt to aim at.) [ANGLE]",
	"Vector (Position for the turret to attempt to aim at.) [VECTOR]",
}

ENT.ACF_StaticWireOutputs = {
	"Mass (Current amount of mass loaded onto the turret.)",
	"Degrees (The number of degrees from center.)",
	"Entity (The turret drive.) [ENTITY]",
}
