DEFINE_BASECLASS("acf_base_scalable")

ACF.Entities.AutoRegisterV2(function()
	-- The gearbox variant this entity represents (e.g. ACF.Gearboxes.Manual-T).
	MENU_FIELD("ACF.Gearboxes.BaseGearbox", "Gearbox", {OnlyAllowSubtypes = true, InstantiateTypeForDefault = "ACF.Gearboxes.2Gear-T"})

	-- Tunable scalars. The gear ratios / shift points live in the arrays below; everything else here is
	-- a flat per-entity setting validated by the serializer.
	MENU_FIELD("Number",  "GearboxScale",       {Min = ACF.GearboxMinSize, Max = ACF.GearboxMaxSize, Default = 1, Decimals = 2})
	MENU_FIELD("Number",  "GearAmount",         {Min = 1, Max = 10, Default = 2, Decimals = 0})
	MENU_FIELD("Number",  "FinalDrive",         {Min = ACF.MinGearRatio, Max = ACF.MaxGearRatio, Default = 1, Decimals = 3})
	MENU_FIELD("Number",  "Reverse",            {Min = ACF.MinGearRatio, Max = ACF.MaxGearRatio, Default = -1, Decimals = 3})
	MENU_FIELD("Number",  "MinRPM",             {Min = 1, Max = 9900, Default = 3000, Decimals = 0})
	MENU_FIELD("Number",  "MaxRPM",             {Min = 1, Max = 10000, Default = 5000, Decimals = 0})
	MENU_FIELD("Boolean", "DualClutch",         {Default = false})
	MENU_FIELD("Boolean", "GearboxLegacyRatio", {Default = false})

	-- Per-gear ratios (1-based) and automatic shift points. The serializer clamps each entry; the entity
	-- reconstructs the legacy [0] sentinel slots at runtime.
	MENU_FIELD("Number[]", "Gears",       {Min = ACF.MinGearRatio, Max = ACF.MaxGearRatio, Default = 0, Decimals = 3})
	MENU_FIELD("Number[]", "ShiftPoints", {Min = 0, Max = 9999, Default = 0, Decimals = 0})

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
