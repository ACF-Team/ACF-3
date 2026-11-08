local GetSubtype = ACF.Classes.GetSubtypeByName

-- Resolves a gearbox short id ("Manual-T") to its class FQN, or nil if unknown.
local function GearboxFQN(ID)
	local FQN = "ACF.Gearboxes." .. tostring(ID)

	return GetSubtype("ACF.Gearboxes.BaseGearbox", FQN) and FQN or nil
end

---------------------------------------------------------------------------------------------------------------------
--  Pre-Scalable Gearboxes Compatibility
--      All previously registered gearboxes for ACF-3
--
--      Breaking change introduced: December 17th, 2024, finalized February 15th, 2025
--      https://github.com/ACF-Team/ACF-3/commit/0dfbe3cb5c16d88fa444823d96b6eb2815151cbf
--      https://github.com/ACF-Team/ACF-3/pull/443
---------------------------------------------------------------------------------------------------------------------
local Gearboxes_CheckGroupItem
do
	-- Old gearbox scales
	-- MARCH: I checked, these were all the same across gearbox definitions
	local ScaleT    = 0.75
	local ScaleS    = 1
	local ScaleM    = 1.5
	local ScaleL    = 2.5
	local StScaleL  = 2 -- Straight gearbox large scale

	local PreScalableGearboxes_ItemChanges 	= {}
	local PreScalableGearboxes_GroupChanges = {}

	local function Gearboxes_RegisterItemAlias(GroupID, ID, Alias, Overrides)
		local Data = {
			GroupID   = GroupID,
			ID        = ID,
			Overrides = Overrides
		}
		PreScalableGearboxes_ItemChanges[Alias] = Data
	end

	local function Gearboxes_RegisterGroupChange(NewClass, OldClass)
		PreScalableGearboxes_GroupChanges[OldClass] = NewClass
	end

	function Gearboxes_CheckGroupItem(GroupItem)
		return PreScalableGearboxes_ItemChanges[GroupItem]
	end

	-- local function Gearboxes_CheckGroup(GroupItem)
	-- 	return Aliases.Get("PreScalableGearboxes_GroupChanges", GroupItem)
	-- end

	-- Automatic gearboxes
	do -- Pre-Scalable 3/5/7-Speed Gearboxes
		local OldGearValues = {3, 5, 7}

		for _, Gear in ipairs(OldGearValues) do
			local OldCategory = tostring(Gear .. "-Auto")
			local OldGear = tostring(Gear .. "Gear")

			Gearboxes_RegisterGroupChange("Auto", OldCategory)

			-- Inline Gearboxes
			Gearboxes_RegisterItemAlias(OldCategory, "Auto-L", OldGear .. "-A-L-S", {
				MaxGear = Gear,
				Scale = ScaleS,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias(OldCategory, "Auto-L", OldGear .. "-A-L-M", {
				MaxGear = Gear,
				Scale = ScaleM,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias(OldCategory, "Auto-L", OldGear .. "-A-L-L", {
				MaxGear = Gear,
				Scale = ScaleL,
				InvertGearRatios = true,
			})

			-- Inline Dual Clutch Gearboxes
			Gearboxes_RegisterItemAlias(OldCategory, "Auto-L", OldGear .. "-A-LD-S", {
				MaxGear = Gear,
				Scale = ScaleS,
				DualClutch = true,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias(OldCategory, "Auto-L", OldGear .. "-A-LD-M", {
				MaxGear = Gear,
				Scale = ScaleM,
				DualClutch = true,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias(OldCategory, "Auto-L", OldGear .. "-A-LD-L", {
				MaxGear = Gear,
				Scale = ScaleL,
				DualClutch = true,
				InvertGearRatios = true,
			})

			-- Transaxial Gearboxes
			Gearboxes_RegisterItemAlias(OldCategory, "Auto-T", OldGear .. "-A-T-S", {
				MaxGear = Gear,
				Scale = ScaleS,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias(OldCategory, "Auto-T", OldGear .. "-A-T-M", {
				MaxGear = Gear,
				Scale = ScaleM,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias(OldCategory, "Auto-T", OldGear .. "-A-T-L", {
				MaxGear = Gear,
				Scale = ScaleL,
				InvertGearRatios = true,
			})

			-- Transaxial Dual Clutch Gearboxes
			Gearboxes_RegisterItemAlias(OldCategory, "Auto-T", OldGear .. "-A-TD-S", {
				MaxGear = Gear,
				Scale = ScaleS,
				DualClutch = true,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias(OldCategory, "Auto-T", OldGear .. "-A-TD-M", {
				MaxGear = Gear,
				Scale = ScaleM,
				DualClutch = true,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias(OldCategory, "Auto-T", OldGear .. "-A-TD-L", {
				MaxGear = Gear,
				Scale = ScaleL,
				DualClutch = true,
				InvertGearRatios = true,
			})

			-- Straight-through Gearboxes
			Gearboxes_RegisterItemAlias(OldCategory, "Auto-ST", OldGear .. "-A-ST-S", {
				MaxGear = Gear,
				Scale = ScaleS,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias(OldCategory, "Auto-ST", OldGear .. "-A-ST-M", {
				MaxGear = Gear,
				Scale = ScaleM,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias(OldCategory, "Auto-ST", OldGear .. "-A-ST-L", {
				MaxGear = Gear,
				Scale = StScaleL,
				InvertGearRatios = true,
			})
		end
	end



	-- Clutch gearboxes
	do
		do -- Pre-Scalable Straight-through Gearboxes
			Gearboxes_RegisterItemAlias("Clutch", "Clutch-S", "Clutch-S-T", {
				Scale = ScaleT,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias("Clutch", "Clutch-S", "Clutch-S-S", {
				Scale = ScaleS,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias("Clutch", "Clutch-S", "Clutch-S-M", {
				Scale = ScaleM,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias("Clutch", "Clutch-S", "Clutch-S-L", {
				Scale = ScaleL,
				InvertGearRatios = true,
			})
		end
	end



	-- CVT gearboxes
	do
		do -- Inline Gearboxes
			Gearboxes_RegisterItemAlias("CVT", "CVT-L", "CVT-L-S", {
				Scale = ScaleS,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias("CVT", "CVT-L", "CVT-L-M", {
				Scale = ScaleM,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias("CVT", "CVT-L", "CVT-L-L", {
				Scale = ScaleL,
				InvertGearRatios = true,
			})
		end

		do -- Inline Dual Clutch Gearboxes
			Gearboxes_RegisterItemAlias("CVT", "CVT-L", "CVT-LD-S", {
				Scale = ScaleS,
				DualClutch = true,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias("CVT", "CVT-L", "CVT-LD-M", {
				Scale = ScaleM,
				DualClutch = true,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias("CVT", "CVT-L", "CVT-LD-L", {
				Scale = ScaleL,
				DualClutch = true,
				InvertGearRatios = true,
			})
		end

		do -- Transaxial Gearboxes
			Gearboxes_RegisterItemAlias("CVT", "CVT-T", "CVT-T-S", {
				Scale = ScaleS,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias("CVT", "CVT-T", "CVT-T-M", {
				Scale = ScaleM,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias("CVT", "CVT-T", "CVT-T-L", {
				Scale = ScaleL,
				InvertGearRatios = true,
			})
		end


		do -- Transaxial Dual Clutch Gearboxes
			Gearboxes_RegisterItemAlias("CVT", "CVT-T", "CVT-TD-S", {
				Scale = ScaleS,
				DualClutch = true,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias("CVT", "CVT-T", "CVT-TD-M", {
				Scale = ScaleM,
				DualClutch = true,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias("CVT", "CVT-T", "CVT-TD-L", {
				Scale = ScaleL,
				DualClutch = true,
				InvertGearRatios = true,
			})
		end

		do -- Straight-through Gearboxes
			Gearboxes_RegisterItemAlias("CVT", "CVT-ST", "CVT-ST-S", {
				Scale = ScaleS,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias("CVT", "CVT-ST", "CVT-ST-M", {
				Scale = ScaleM,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias("CVT", "CVT-ST", "CVT-ST-L", {
				Scale = StScaleL,
				InvertGearRatios = true,
			})
		end
	end

	-- Differential gearboxes
	do -- Pre-Scalable Inline/Transaxial Gearboxes
		local OldGearboxTypes = {"L", "T"}

		for _, GearboxType in ipairs(OldGearboxTypes) do
			local OldCategory = "1Gear-" .. GearboxType

			-- Regular Gearboxes
			Gearboxes_RegisterItemAlias("Differential", OldCategory, OldCategory .. "-S", {
				Scale = ScaleS,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias("Differential", OldCategory, OldCategory .. "-M", {
				Scale = ScaleM,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias("Differential", OldCategory, OldCategory .. "-L", {
				Scale = ScaleL,
				InvertGearRatios = true,
			})

			-- Dual Clutch Gearboxes
			Gearboxes_RegisterItemAlias("Differential", OldCategory, OldCategory .. "D-S", {
				Scale = ScaleS,
				DualClutch = true,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias("Differential", OldCategory, OldCategory .. "D-M", {
				Scale = ScaleM,
				DualClutch = true,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias("Differential", OldCategory, OldCategory .. "D-L", {
				Scale = ScaleL,
				DualClutch = true,
				InvertGearRatios = true,
			})

			-- ACF Extras Gearboxes
			Gearboxes_RegisterItemAlias("Differential", OldCategory, OldCategory .. "-T", {
				Scale = ScaleT,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias("Differential", OldCategory, OldCategory .. "D-T", {
				Scale = ScaleT,
				DualClutch = true,
				InvertGearRatios = true,
			})
		end
	end



	-- Double Differential gearboxes
	do
		Gearboxes_RegisterItemAlias("DoubleDiff", "DoubleDiff-T", "DoubleDiff-T-S", {
			Scale = ScaleS,
			InvertGearRatios = true,
		})

		Gearboxes_RegisterItemAlias("DoubleDiff", "DoubleDiff-T", "DoubleDiff-T-M", {
			Scale = ScaleM,
			InvertGearRatios = true,
		})

		Gearboxes_RegisterItemAlias("DoubleDiff", "DoubleDiff-T", "DoubleDiff-T-L", {
			Scale = ScaleL,
			InvertGearRatios = true,
		})
	end



	-- Manual gearboxes
	do
		do -- Pre-Scalable 4/6/8-Speed Manual Gearboxes + ACE 9-Speed Manual Gearboxes
			local OldGearValues = {4, 6, 8, 9}

			for _, Gear in ipairs(OldGearValues) do
				local OldCategory = tostring(Gear .. "-Speed")
				local OldGear = tostring(Gear .. "Gear")

				Gearboxes_RegisterGroupChange("Manual", OldCategory)

				-- Inline Gearboxes
				Gearboxes_RegisterItemAlias(OldCategory, "Manual-L", OldGear .. "-L-S", {
					MaxGear = Gear,
					Scale = ScaleS,
					InvertGearRatios = true,
				})

				Gearboxes_RegisterItemAlias(OldCategory, "Manual-L", OldGear .. "-L-M", {
					MaxGear = Gear,
					Scale = ScaleM,
					InvertGearRatios = true,
				})

				Gearboxes_RegisterItemAlias(OldCategory, "Manual-L", OldGear .. "-L-L", {
					MaxGear = Gear,
					Scale = ScaleL,
					InvertGearRatios = true,
				})

				-- Inline Dual Clutch Gearboxes
				Gearboxes_RegisterItemAlias(OldCategory, "Manual-L", OldGear .. "-LD-S", {
					MaxGear = Gear,
					Scale = ScaleS,
					DualClutch = true,
					InvertGearRatios = true,
				})

				Gearboxes_RegisterItemAlias(OldCategory, "Manual-L", OldGear .. "-LD-M", {
					MaxGear = Gear,
					Scale = ScaleM,
					DualClutch = true,
					InvertGearRatios = true,
				})

				Gearboxes_RegisterItemAlias(OldCategory, "Manual-L", OldGear .. "-LD-L", {
					MaxGear = Gear,
					Scale = ScaleL,
					DualClutch = true,
					InvertGearRatios = true,
				})

				-- Transaxial Gearboxes
				Gearboxes_RegisterItemAlias(OldCategory, "Manual-T", OldGear .. "-T-S", {
					MaxGear = Gear,
					Scale = ScaleS,
					InvertGearRatios = true,
				})

				Gearboxes_RegisterItemAlias(OldCategory, "Manual-T", OldGear .. "-T-M", {
					MaxGear = Gear,
					Scale = ScaleM,
					InvertGearRatios = true,
				})

				Gearboxes_RegisterItemAlias(OldCategory, "Manual-T", OldGear .. "-T-L", {
					MaxGear = Gear,
					Scale = ScaleL,
					InvertGearRatios = true,
				})

				-- Transaxial Dual Clutch Gearboxes
				Gearboxes_RegisterItemAlias(OldCategory, "Manual-T", OldGear .. "-TD-S", {
					MaxGear = Gear,
					Scale = ScaleS,
					DualClutch = true,
					InvertGearRatios = true,
				})

				Gearboxes_RegisterItemAlias(OldCategory, "Manual-T", OldGear .. "-TD-M", {
					MaxGear = Gear,
					Scale = ScaleM,
					DualClutch = true,
					InvertGearRatios = true,
				})

				Gearboxes_RegisterItemAlias(OldCategory, "Manual-T", OldGear .. "-TD-L", {
					MaxGear = Gear,
					Scale = ScaleL,
					DualClutch = true,
					InvertGearRatios = true,
				})

				-- Straight-through Gearboxes
				Gearboxes_RegisterItemAlias(OldCategory, "Manual-ST", OldGear .. "-ST-S", {
					MaxGear = Gear,
					Scale = ScaleS,
					InvertGearRatios = true,
				})

				Gearboxes_RegisterItemAlias(OldCategory, "Manual-ST", OldGear .. "-ST-M", {
					MaxGear = Gear,
					Scale = ScaleM,
					InvertGearRatios = true,
				})

				Gearboxes_RegisterItemAlias(OldCategory, "Manual-ST", OldGear .. "-ST-L", {
					MaxGear = Gear,
					Scale = StScaleL,
					InvertGearRatios = true,
				})
			end
		end

		do -- ACF Extras Manual Gearboxes (4/6-Speed)
			local OldGearValues = {4, 6}

			for _, Gear in ipairs(OldGearValues) do
				local OldCategory = tostring(Gear .. "-Speed-Inline")
				local OldGear = tostring(Gear .. "Gear")

				Gearboxes_RegisterGroupChange("Manual", OldCategory)

				-- Inline Gearboxes
				Gearboxes_RegisterItemAlias(OldCategory, "Manual-L", OldGear .. "-L-T", {
					MaxGear = Gear,
					Scale = ScaleT,
					InvertGearRatios = true,
				})

				Gearboxes_RegisterItemAlias(OldCategory, "Manual-L", OldGear .. "-LD-T", {
					MaxGear = Gear,
					Scale = ScaleT,
					DualClutch = true,
					InvertGearRatios = true,
				})

				-- Transaxial Gearboxes
				Gearboxes_RegisterItemAlias(OldCategory, "Manual-T", OldGear .. "-T-T", {
					MaxGear = Gear,
					Scale = ScaleT,
					InvertGearRatios = true,
				})

				Gearboxes_RegisterItemAlias(OldCategory, "Manual-T", OldGear .. "-TD-T", {
					MaxGear = Gear,
					Scale = ScaleT,
					DualClutch = true,
					InvertGearRatios = true,
				})

				-- Straight-through Gearboxes
				Gearboxes_RegisterItemAlias(OldCategory, "Manual-ST", OldGear .. "-ST-T", {
					MaxGear = Gear,
					Scale = ScaleT,
					InvertGearRatios = true,
				})
			end
		end
	end


	-- Transfer case gearboxes
	do -- Pre-Scalable Inline/Transaxial Gearboxes
		local OldGearboxTypes = {"L", "T"}

		for _, GearboxType in ipairs(OldGearboxTypes) do
			local OldCategory = "2Gear-" .. GearboxType

			-- Regular Gearboxes
			Gearboxes_RegisterItemAlias("Transfer", OldCategory, OldCategory .. "-S", {
				Scale = ScaleS,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias("Transfer", OldCategory, OldCategory .. "-M", {
				Scale = ScaleM,
				InvertGearRatios = true,
			})

			Gearboxes_RegisterItemAlias("Transfer", OldCategory, OldCategory .. "-L", {
				Scale = ScaleL,
				InvertGearRatios = true,
			})

			-- ACF Extras Gearboxes
			Gearboxes_RegisterItemAlias("Transfer", OldCategory, OldCategory .. "-T", {
				Scale = ScaleT,
				InvertGearRatios = true,
			})
		end
	end
end

-- Migrate legacy gearbox dupes onto the AutoRegisterV2 field set. Pre-scalable aliases (and their
-- gear-count / scale / ratio-inversion overrides) are resolved via the class alias compat; the gear
-- ratio + shift point assembly and clamping then happens in the entity's ACF_OnVerifyClientData.
ACF.Entities.RegisterCompatPatch("acf_gearbox", 2026062801, function(Data)
	if Data.ACF_UserData then return end

	local GearboxID = Data.Gearbox or Data.Id or "2Gear-T"
	local Overrides

	local FQN = GearboxFQN(GearboxID)

	if not FQN then
		local Alias = Gearboxes_CheckGroupItem(GearboxID)
		if Alias then
			Overrides = Alias.Overrides
			FQN       = GearboxFQN(Alias.ID)
		end
	end

	FQN = FQN or "ACF.Gearboxes.2Gear-T"

	local function Pick(Key)
		return Data[Key]
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

	-- Apply pre-scalable overrides (gear count, scale) and mark them as legacy ratios for the ratio format patch.
	if Overrides then
		UserData.GearAmount       = Overrides.MaxGear or UserData.GearAmount
		UserData.GearboxScale     = Overrides.Scale or UserData.GearboxScale
		UserData.InvertGearRatios = Overrides.InvertGearRatios
		UserData.DualClutch       = Overrides.DualClutch or UserData.DualClutch
	end

	Data.ACF_UserData = UserData
end)

-- Gearboxes saved between 2025-06-20 and 2026-11-07 stored realistic ratios (x) instead of legacy ones (1/x).
-- Every save from 2025-08-02 on carries GearboxLegacyRatio, which only ever controlled the display.
-- Earlier saves (old format, no ACF_Version) are only recognizable by a ratio above 1, which legacy storage never allowed.
ACF.Entities.RegisterCompatPatch("acf_gearbox", 2026110701, function(Data)
	local UserData = Data.ACF_UserData
	if not UserData then return end

	local PreScalable = UserData.InvertGearRatios
	UserData.InvertGearRatios = nil

	local LegacyFlag = UserData.GearboxLegacyRatio
	UserData.GearboxLegacyRatio = nil

	local Gears = istable(UserData.Gears) and UserData.Gears or {}
	local Realistic = LegacyFlag ~= nil

	-- Versioned dupes always carry the key when realistic, and may legitimately hold legacy ratios above 1
	if not Realistic and not PreScalable and not Data.ACF_Version then
		local function IsRealistic(Ratio) return isnumber(Ratio) and math.abs(Ratio) > 1 end

		Realistic = IsRealistic(UserData.FinalDrive) or IsRealistic(UserData.Reverse)
		for _, Ratio in ipairs(Gears) do Realistic = Realistic or IsRealistic(Ratio) end
	end

	if not Realistic then return end

	local function Invert(Ratio)
		if not isnumber(Ratio) or Ratio == 0 then return Ratio end
		return math.Round(1 / Ratio, ACF.GearRatioDecimals)
	end

	for I, Ratio in ipairs(Gears) do Gears[I] = Invert(Ratio) end
	UserData.FinalDrive = Invert(UserData.FinalDrive)
	UserData.Reverse    = Invert(UserData.Reverse)

	-- Keep showing these gearboxes the way their builder saw them, which also keeps wired Ratio outputs unchanged
	UserData.GearboxRealisticRatio = LegacyFlag == nil or not tobool(LegacyFlag)
end)
