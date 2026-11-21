DEFINE_BASECLASS("acf_base_scalable")

ENT.ConvexMaterial = "RHA"

ACF.Entities.AutoRegister(2026100201, function()
	MENU_FIELD("ACF.Turrets.Drive", "Turret", {
		Title                     = "#acf.menu.fields.acf_turret.turret",
		InstantiateTypeForDefault = "ACF.Turrets.Drive.Horizontal",
		OnlyAllowSubtypes         = true,
		OnlyAllowLeafTypes        = true,
	})
	MENU_FIELD("Number", "RingSize", {Title = "#acf.menu.fields.acf_turret.ring_size", Min = 2,    Max = 512, Default = 60,   Decimals = 2}) -- Bore on actuators
	MENU_FIELD("Number", "MinDeg",   {Title = "#acf.menu.fields.acf_turret.min_deg", Min = -180, Max = 0,   Default = -180, Decimals = 1})
	MENU_FIELD("Number", "MaxDeg",   {Title = "#acf.menu.fields.acf_turret.max_deg", Min = 0,    Max = 180, Default = 180,  Decimals = 1})
	MENU_FIELD("Number", "MaxSpeed", {Title = "#acf.menu.fields.acf_turret.max_speed", Min = 0,    Max = 120, Default = 0,    Decimals = 2})
	MENU_FIELD("Number", "OnAngle",  {Title = "#acf.menu.fields.acf_turret.on_angle", Min = -180, Max = 180, Default = 15,   Decimals = 1}) -- Servos only
	MENU_FIELD("Number", "Stroke",   {Title = "#acf.menu.fields.acf_turret.stroke", Min = 4,    Max = 72,  Default = 24,   Decimals = 1}) -- Actuators only
	LINKED_ENTITY_FIELD("Motor", {AcceptableClasses = {acf_turret_motor = true}})
	LINKED_ENTITY_FIELD("Gyro", {AcceptableClasses = {acf_turret_gyro = true}})
	LINKED_ENTITY_FIELD("Radar", {AcceptableClasses = {acf_radar = true}})
	LINKED_ENTITY_ARRAY_FIELD("LightweightControllers", {AcceptableClasses = {acf_turret_controller = true}})
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
