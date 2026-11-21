DEFINE_BASECLASS("acf_base_scalable")

ACF.Entities.AutoRegister(2026091001, function(CLASS)
	-- The gearbox variant this entity represents (e.g. ACF.Gearboxes.Manual-T).
	MENU_FIELD("ACF.Gearboxes.BaseGearbox", "Gearbox", {Title = "#acf.menu.fields.acf_gearbox.gearbox", OnlyAllowSubtypes = true, OnlyAllowLeafTypes = true, InstantiateTypeForDefault = "ACF.Gearboxes.2Gear-T"})

	-- Tunable scalars. The gear ratios / shift points live in the arrays below; everything else here is
	-- a flat per-entity setting validated by the serializer.
	MENU_FIELD("Number",  "GearboxScale",       {Title = "#acf.menu.fields.acf_gearbox.gearbox_scale", Min = ACF.GearboxMinSize, Max = ACF.GearboxMaxSize, Default = 1, Decimals = 2})
	MENU_FIELD("Number",  "GearAmount",         {Title = "#acf.menu.fields.acf_gearbox.gear_amount", Min = 1, Max = 10, Default = 2, Decimals = 0})
	MENU_FIELD("Number",  "FinalDrive",            {Title = "#acf.menu.fields.acf_gearbox.final_drive", Min = ACF.MinGearRatioLegacy, Max = ACF.MaxGearRatioLegacy, Default = 1, Decimals = ACF.GearRatioDecimals})
	MENU_FIELD("Number",  "Reverse",               {Title = "#acf.menu.fields.acf_gearbox.reverse", Min = ACF.MinGearRatioLegacy, Max = ACF.MaxGearRatioLegacy, Default = -1, Decimals = ACF.GearRatioDecimals})
	MENU_FIELD("Number",  "MinRPM",                {Title = "#acf.menu.fields.acf_gearbox.min_rpm", Min = 1, Max = 9900, Default = 3000, Decimals = 0})
	MENU_FIELD("Number",  "MaxRPM",                {Title = "#acf.menu.fields.acf_gearbox.max_rpm", Min = 1, Max = 10000, Default = 5000, Decimals = 0})
	MENU_FIELD("Boolean", "DualClutch",            {Title = "#acf.menu.fields.acf_gearbox.dual_clutch", Default = false})
	MENU_FIELD("Boolean", "GearboxRealisticRatio", {Title = "#acf.menu.fields.acf_gearbox.gearbox_realistic_ratio", Default = false})
	LINKED_ENTITY_ARRAY_FIELD("Wheels")
	LINKED_ENTITY_ARRAY_FIELD("GearboxOut", {AcceptableClasses = {acf_gearbox = true}})
	LINKED_ENTITY_ARRAY_FIELD("Effectors")

	-- Per-gear ratios (1-based) and automatic shift points. The serializer clamps each entry; the entity
	-- reconstructs the legacy [0] sentinel slots at runtime. Storage is always the legacy format.
	MENU_FIELD("Number[]", "Gears",       {Title = "#acf.menu.fields.acf_gearbox.gears", Min = ACF.MinGearRatioLegacy, Max = ACF.MaxGearRatioLegacy, Default = 0, Decimals = ACF.GearRatioDecimals})
	MENU_FIELD("Number[]", "ShiftPoints", {Title = "#acf.menu.fields.acf_gearbox.shift_points", Min = 0, Max = 9999, Default = 0, Decimals = 0})

	-- The per-gear assembly + ratio conversion happens in ACF_OnVerifyClientData (see init.lua); the
	-- field constraints above handle the clamping.
	function CLASS:VerifyData()
	end
end, "Gearbox", "Gearboxes")

ENT.ACF_StaticWireInputs = {
	"Gear (Changes the current gear to the given value.)",
	"Gear Up (Attempts to shift up the current gear.)",
	"Gear Down (Attempts to shift down the current gear.)",
}

ENT.ACF_StaticWireOutputs = {
	"Current Gear (Returns the gear currently in use.)",
	"Ratio (Returns the current gear ratio, based on the current gear and final drive.)",
	"Entity (The gearbox itself.) [ENTITY]",
}

-- Returns the gearbox instance backing this entity.
function ENT:GetGearbox()
	return self:ACF_GetUserVar("Gearbox")
end
