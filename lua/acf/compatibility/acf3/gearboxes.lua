local GetSubtype = ACF.Classes.GetSubtypeByName

-- Resolves a gearbox short id ("Manual-T") to its class FQN, or nil if unknown.
local function GearboxFQN(ID)
	local FQN = "ACF.Gearboxes." .. tostring(ID)

	return GetSubtype("ACF.Gearboxes.BaseGearbox", FQN) and FQN or nil
end

-- Migrate legacy gearbox dupes onto the AutoRegisterV2 field set. Pre-scalable aliases (and their
-- gear-count / scale / ratio-inversion overrides) are resolved via the class alias compat; the gear
-- ratio + shift point assembly and clamping then happens in the entity's ACF_OnVerifyClientData.
ACF.Entities.RegisterCompatPatch("acf_gearbox", 2026062801, function(Data)
	if Data.ACF_UserData then return end

	local Old       = Data.Data or {}
	local GearboxID = Old.Gearbox or Data.Gearbox or "2Gear-T"
	local Overrides

	local FQN = GearboxFQN(GearboxID)

	if not FQN then
		local Alias = ACF.Compatibility.Gearboxes and ACF.Compatibility.Gearboxes.CheckGroupItem(GearboxID)

		if Alias then
			Overrides = Alias.Overrides
			FQN       = GearboxFQN(Alias.ID)
		end
	end

	FQN = FQN or "ACF.Gearboxes.2Gear-T"

	-- Values may live at the top level (modern legacy dupes) or under a nested "Data" table (older/ACE).
	local function Pick(Key)
		local Value = Old[Key]
		if Value == nil then Value = Data[Key] end
		return Value
	end

	local UserData = {
		Gearbox            = {Type = FQN, Data = {}},
		Gears              = Pick("Gears"),
		ShiftPoints        = Pick("ShiftPoints"),
		FinalDrive         = Pick("FinalDrive"),
		Reverse            = Pick("Reverse"),
		MinRPM             = Pick("MinRPM"),
		MaxRPM             = Pick("MaxRPM"),
		GearAmount         = Pick("GearAmount"),
		GearboxScale       = Pick("GearboxScale"),
		DualClutch         = Pick("DualClutch"),
		GearboxLegacyRatio = Pick("GearboxLegacyRatio"),
		Gear0              = Pick("Gear0"),
		ShiftUnit          = Pick("ShiftUnit"),
	}

	-- Carry legacy flat per-gear / shift keys so ACF_OnVerifyClientData can assemble them.
	for I = 1, 10 do
		UserData["Gear" .. I]  = Pick("Gear" .. I)
		UserData["Shift" .. I] = Pick("Shift" .. I)
	end

	-- Apply pre-scalable overrides (gear count, scale) and flag ratio inversion for the verify step.
	if Overrides then
		UserData.GearAmount       = Overrides.MaxGear or UserData.GearAmount
		UserData.GearboxScale     = Overrides.Scale or UserData.GearboxScale
		UserData.InvertGearRatios = Overrides.InvertGearRatios
	end

	Data.ACF_UserData = UserData
end)
