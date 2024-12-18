local Gearboxes = ACF.Classes.Gearboxes

-- Old gearbox scales
local ScaleS = 1
local ScaleM = 1.5
local ScaleL = 2.5

do -- 3-Speed Automatic Gearboxes
	Gearboxes.AddAlias("Auto", "3-Auto")

	-- Inline Gearboxes
	Gearboxes.AddItemAlias("3-Auto", "Auto-L", "3Gear-A-L-S", {
		MaxGear = 3,
		Scale = ScaleS,
	})

	Gearboxes.AddItemAlias("3-Auto", "Auto-L", "3Gear-A-L-M", {
		MaxGear = 3,
		Scale = ScaleM,
	})

	Gearboxes.AddItemAlias("3-Auto", "Auto-L", "3Gear-A-L-L", {
		MaxGear = 3,
		Scale = ScaleL,
	})

	-- Inline Dual Clutch Gearboxes
	Gearboxes.AddItemAlias("3-Auto", "Auto-L", "3Gear-A-LD-S", {
		MaxGear = 3,
		Scale = ScaleS,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("3-Auto", "Auto-L", "3Gear-A-LD-M", {
		MaxGear = 3,
		Scale = ScaleM,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("3-Auto", "Auto-L", "3Gear-A-LD-L", {
		MaxGear = 3,
		Scale = ScaleL,
		DualClutch = true,
	})

	-- Transaxial Gearboxes
	Gearboxes.AddItemAlias("3-Auto", "Auto-T", "3Gear-A-T-S", {
		MaxGear = 3,
		Scale = ScaleS,
	})

	Gearboxes.AddItemAlias("3-Auto", "Auto-T", "3Gear-A-T-M", {
		MaxGear = 3,
		Scale = ScaleM,
	})

	Gearboxes.AddItemAlias("3-Auto", "Auto-T", "3Gear-A-T-L", {
		MaxGear = 3,
		Scale = ScaleL,
	})

	-- Transaxial Dual Clutch Gearboxes
	Gearboxes.AddItemAlias("3-Auto", "Auto-T", "3Gear-A-TD-S", {
		MaxGear = 3,
		Scale = ScaleS,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("3-Auto", "Auto-T", "3Gear-A-TD-M", {
		MaxGear = 3,
		Scale = ScaleM,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("3-Auto", "Auto-T", "3Gear-A-TD-L", {
		MaxGear = 3,
		Scale = ScaleL,
		DualClutch = true,
	})

	-- Straight-through Gearboxes
	Gearboxes.AddItemAlias("3-Auto", "Auto-ST", "3Gear-A-ST-S", {
		MaxGear = 3,
		Scale = ScaleS,
	})

	Gearboxes.AddItemAlias("3-Auto", "Auto-ST", "3Gear-A-ST-M", {
		MaxGear = 3,
		Scale = ScaleM,
	})

	Gearboxes.AddItemAlias("3-Auto", "Auto-ST", "3Gear-A-ST-L", {
		MaxGear = 3,
		Scale = ScaleL,
	})
end
--[[
do -- Pre-Scalable CVT Gearboxes
	-- Inline Gearboxes
	Gearboxes.AddItemAlias("CVT", "CVT-L", "CVT-L-S", {
		Scale = ScaleS,
	})

	Gearboxes.AddItemAlias("CVT", "CVT-L", "CVT-L-M", {
		Scale = ScaleM,
	})

	Gearboxes.AddItemAlias("CVT", "CVT-L", "CVT-L-L", {
		Scale = ScaleL,
	})

	-- Inline Dual Clutch Gearboxes
	Gearboxes.AddItemAlias("CVT", "CVT-L", "CVT-LD-S", {
		Scale = ScaleS,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("CVT", "CVT-L", "CVT-LD-M", {
		Scale = ScaleM,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("CVT", "CVT-L", "CVT-LD-L", {
		Scale = ScaleL,
		DualClutch = true,
	})

	-- Transaxial Gearboxes
	Gearboxes.AddItemAlias("CVT", "CVT-T", "CVT-T-S", {
		Scale = ScaleS,
	})

	Gearboxes.AddItemAlias("CVT", "CVT-T", "CVT-T-M", {
		Scale = ScaleM,
	})

	Gearboxes.AddItemAlias("CVT", "CVT-T", "CVT-T-L", {
		Scale = ScaleL,
	})

	-- Transaxial Dual Clutch Gearboxes
	Gearboxes.AddItemAlias("CVT", "CVT-T", "CVT-TD-S", {
		Scale = ScaleS,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("CVT", "CVT-T", "CVT-TD-M", {
		Scale = ScaleM,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("CVT", "CVT-T", "CVT-TD-L", {
		Scale = ScaleL,
		DualClutch = true,
	})

	-- Straight-through Gearboxes
	Gearboxes.AddItemAlias("CVT", "CVT-ST", "CVT-ST-S", {
		Scale = ScaleS,
	})

	Gearboxes.AddItemAlias("CVT", "CVT-ST", "CVT-ST-M", {
		Scale = ScaleM,
	})

	Gearboxes.AddItemAlias("CVT", "CVT-ST", "CVT-ST-L", {
		Scale = ScaleL,
	})
end
]]
do -- 4-Speed Manual Gearboxes
	Gearboxes.AddAlias("Manual", "4-Speed")

	-- Inline Gearboxes
	Gearboxes.AddItemAlias("4-Speed", "Manual-L", "4Gear-L-S", {
		MaxGear = 4,
		Scale = ScaleS,
	})

	Gearboxes.AddItemAlias("4-Speed", "Manual-L", "4Gear-L-M", {
		MaxGear = 4,
		Scale = ScaleM,
	})

	Gearboxes.AddItemAlias("4-Speed", "Manual-L", "4Gear-L-L", {
		MaxGear = 4,
		Scale = ScaleL,
	})

	-- Inline Dual Clutch Gearboxes
	Gearboxes.AddItemAlias("4-Speed", "Manual-L", "4Gear-LD-S", {
		MaxGear = 4,
		Scale = ScaleS,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("4-Speed", "Manual-L", "4Gear-LD-M", {
		MaxGear = 4,
		Scale = ScaleM,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("4-Speed", "Manual-L", "4Gear-LD-L", {
		MaxGear = 4,
		Scale = ScaleL,
		DualClutch = true,
	})

	-- Transaxial Gearboxes
	Gearboxes.AddItemAlias("4-Speed", "Manual-T", "4Gear-T-S", {
		MaxGear = 4,
		Scale = ScaleS,
	})

	Gearboxes.AddItemAlias("4-Speed", "Manual-T", "4Gear-T-M", {
		MaxGear = 4,
		Scale = ScaleM,
	})

	Gearboxes.AddItemAlias("4-Speed", "Manual-T", "4Gear-T-L", {
		MaxGear = 4,
		Scale = ScaleL,
	})

	-- Transaxial Dual Clutch Gearboxes
	Gearboxes.AddItemAlias("4-Speed", "Manual-T", "4Gear-TD-S", {
		MaxGear = 4,
		Scale = ScaleS,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("4-Speed", "Manual-T", "4Gear-TD-M", {
		MaxGear = 4,
		Scale = ScaleM,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("4-Speed", "Manual-T", "4Gear-TD-L", {
		MaxGear = 4,
		Scale = ScaleL,
		DualClutch = true,
	})

	-- Straight-through Gearboxes
	Gearboxes.AddItemAlias("4-Speed", "Manual-ST", "4Gear-ST-S", {
		MaxGear = 4,
		Scale = ScaleS,
	})

	Gearboxes.AddItemAlias("4-Speed", "Manual-ST", "4Gear-ST-M", {
		MaxGear = 4,
		Scale = ScaleM,
	})

	Gearboxes.AddItemAlias("4-Speed", "Manual-ST", "4Gear-ST-L", {
		MaxGear = 4,
		Scale = ScaleL,
	})
end

do -- 5-Speed Automatic Gearboxes
	Gearboxes.AddAlias("Auto", "5-Auto")

	-- Inline Gearboxes
	Gearboxes.AddItemAlias("5-Auto", "Auto-L", "5Gear-A-L-S", {
		MaxGear = 5,
		Scale = ScaleS,
	})

	Gearboxes.AddItemAlias("5-Auto", "Auto-L", "5Gear-A-L-M", {
		MaxGear = 5,
		Scale = ScaleM,
	})

	Gearboxes.AddItemAlias("5-Auto", "Auto-L", "5Gear-A-L-L", {
		MaxGear = 5,
		Scale = ScaleL,
	})

	-- Inline Dual Clutch Gearboxes
	Gearboxes.AddItemAlias("5-Auto", "Auto-L", "5Gear-A-LD-S", {
		MaxGear = 5,
		Scale = ScaleS,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("5-Auto", "Auto-L", "5Gear-A-LD-M", {
		MaxGear = 5,
		Scale = ScaleM,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("5-Auto", "Auto-L", "5Gear-A-LD-L", {
		MaxGear = 5,
		Scale = ScaleL,
		DualClutch = true,
	})

	-- Transaxial Gearboxes
	Gearboxes.AddItemAlias("5-Auto", "Auto-T", "5Gear-A-T-S", {
		MaxGear = 5,
		Scale = ScaleS,
	})

	Gearboxes.AddItemAlias("5-Auto", "Auto-T", "5Gear-A-T-M", {
		MaxGear = 5,
		Scale = ScaleM,
	})

	Gearboxes.AddItemAlias("5-Auto", "Auto-T", "5Gear-A-T-L", {
		MaxGear = 5,
		Scale = ScaleL,
	})

	-- Transaxial Dual Clutch Gearboxes
	Gearboxes.AddItemAlias("5-Auto", "Auto-T", "5Gear-A-TD-S", {
		MaxGear = 5,
		Scale = ScaleS,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("5-Auto", "Auto-T", "5Gear-A-TD-M", {
		MaxGear = 5,
		Scale = ScaleM,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("5-Auto", "Auto-T", "5Gear-A-TD-L", {
		MaxGear = 5,
		Scale = ScaleL,
		DualClutch = true,
	})

	-- Straight-through Gearboxes
	Gearboxes.AddItemAlias("5-Auto", "Auto-ST", "5Gear-A-ST-S", {
		MaxGear = 5,
		Scale = ScaleS,
	})

	Gearboxes.AddItemAlias("5-Auto", "Auto-ST", "5Gear-A-ST-M", {
		MaxGear = 5,
		Scale = ScaleM,
	})

	Gearboxes.AddItemAlias("5-Auto", "Auto-ST", "5Gear-A-ST-L", {
		MaxGear = 5,
		Scale = ScaleL,
	})
end

do -- 6-Speed Manual Gearboxes
	Gearboxes.AddAlias("Manual", "6-Speed")

	-- Inline Gearboxes
	Gearboxes.AddItemAlias("6-Speed", "Manual-L", "6Gear-L-S", {
		MaxGear = 6,
		Scale = ScaleS,
	})

	Gearboxes.AddItemAlias("6-Speed", "Manual-L", "6Gear-L-M", {
		MaxGear = 6,
		Scale = ScaleM,
	})

	Gearboxes.AddItemAlias("6-Speed", "Manual-L", "6Gear-L-L", {
		MaxGear = 6,
		Scale = ScaleL,
	})

	-- Inline Dual Clutch Gearboxes
	Gearboxes.AddItemAlias("6-Speed", "Manual-L", "6Gear-LD-S", {
		MaxGear = 6,
		Scale = ScaleS,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("6-Speed", "Manual-L", "6Gear-LD-M", {
		MaxGear = 6,
		Scale = ScaleM,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("6-Speed", "Manual-L", "6Gear-LD-L", {
		MaxGear = 6,
		Scale = ScaleL,
		DualClutch = true,
	})

	-- Transaxial Gearboxes
	Gearboxes.AddItemAlias("6-Speed", "Manual-T", "6Gear-T-S", {
		MaxGear = 6,
		Scale = ScaleS,
	})

	Gearboxes.AddItemAlias("6-Speed", "Manual-T", "6Gear-T-M", {
		MaxGear = 6,
		Scale = ScaleM,
	})

	Gearboxes.AddItemAlias("6-Speed", "Manual-T", "6Gear-T-L", {
		MaxGear = 6,
		Scale = ScaleL,
	})

	-- Transaxial Dual Clutch Gearboxes
	Gearboxes.AddItemAlias("6-Speed", "Manual-T", "6Gear-TD-S", {
		MaxGear = 6,
		Scale = ScaleS,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("6-Speed", "Manual-T", "6Gear-TD-M", {
		MaxGear = 6,
		Scale = ScaleM,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("6-Speed", "Manual-T", "6Gear-TD-L", {
		MaxGear = 6,
		Scale = ScaleL,
		DualClutch = true,
	})

	-- Straight-through Gearboxes
	Gearboxes.AddItemAlias("6-Speed", "Manual-ST", "6Gear-ST-S", {
		MaxGear = 6,
		Scale = ScaleS,
	})

	Gearboxes.AddItemAlias("6-Speed", "Manual-ST", "6Gear-ST-M", {
		MaxGear = 6,
		Scale = ScaleM,
	})

	Gearboxes.AddItemAlias("6-Speed", "Manual-ST", "6Gear-ST-L", {
		MaxGear = 6,
		Scale = ScaleL,
	})
end

do -- 7-Speed Automatic Gearboxes
	Gearboxes.AddAlias("Auto", "7-Auto")

	-- Inline Gearboxes
	Gearboxes.AddItemAlias("7-Auto", "Auto-L", "7Gear-A-L-S", {
		MaxGear = 7,
		Scale = ScaleS,
	})

	Gearboxes.AddItemAlias("7-Auto", "Auto-L", "7Gear-A-L-M", {
		MaxGear = 7,
		Scale = ScaleM,
	})

	Gearboxes.AddItemAlias("7-Auto", "Auto-L", "7Gear-A-L-L", {
		MaxGear = 7,
		Scale = ScaleL,
	})

	-- Inline Dual Clutch Gearboxes
	Gearboxes.AddItemAlias("7-Auto", "Auto-L", "7Gear-A-LD-S", {
		MaxGear = 7,
		Scale = ScaleS,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("7-Auto", "Auto-L", "7Gear-A-LD-M", {
		MaxGear = 7,
		Scale = ScaleM,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("7-Auto", "Auto-L", "7Gear-A-LD-L", {
		MaxGear = 7,
		Scale = ScaleL,
		DualClutch = true,
	})

	-- Transaxial Gearboxes
	Gearboxes.AddItemAlias("7-Auto", "Auto-T", "7Gear-A-T-S", {
		MaxGear = 7,
		Scale = ScaleS,
	})

	Gearboxes.AddItemAlias("7-Auto", "Auto-T", "7Gear-A-T-M", {
		MaxGear = 7,
		Scale = ScaleM,
	})

	Gearboxes.AddItemAlias("7-Auto", "Auto-T", "7Gear-A-T-L", {
		MaxGear = 7,
		Scale = ScaleL,
	})

	-- Transaxial Dual Clutch Gearboxes
	Gearboxes.AddItemAlias("7-Auto", "Auto-T", "7Gear-A-TD-S", {
		MaxGear = 7,
		Scale = ScaleS,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("7-Auto", "Auto-T", "7Gear-A-TD-M", {
		MaxGear = 7,
		Scale = ScaleM,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("7-Auto", "Auto-T", "7Gear-A-TD-L", {
		MaxGear = 7,
		Scale = ScaleL,
		DualClutch = true,
	})

	-- Straight-through Gearboxes
	Gearboxes.AddItemAlias("7-Auto", "Auto-ST", "7Gear-A-ST-S", {
		MaxGear = 7,
		Scale = ScaleS,
	})

	Gearboxes.AddItemAlias("7-Auto", "Auto-ST", "7Gear-A-ST-M", {
		MaxGear = 7,
		Scale = ScaleM,
	})

	Gearboxes.AddItemAlias("7-Auto", "Auto-ST", "7Gear-A-ST-L", {
		MaxGear = 7,
		Scale = ScaleL,
	})
end

do -- 8-Speed Manual Gearboxes
	Gearboxes.AddAlias("Manual", "8-Speed")

	-- Inline Gearboxes
	Gearboxes.AddItemAlias("8-Speed", "Manual-L", "8Gear-L-S", {
		MaxGear = 8,
		Scale = ScaleS,
	})

	Gearboxes.AddItemAlias("8-Speed", "Manual-L", "8Gear-L-M", {
		MaxGear = 8,
		Scale = ScaleM,
	})

	Gearboxes.AddItemAlias("8-Speed", "Manual-L", "8Gear-L-L", {
		MaxGear = 8,
		Scale = ScaleL,
	})

	-- Inline Dual Clutch Gearboxes
	Gearboxes.AddItemAlias("8-Speed", "Manual-L", "8Gear-LD-S", {
		MaxGear = 8,
		Scale = ScaleS,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("8-Speed", "Manual-L", "8Gear-LD-M", {
		MaxGear = 8,
		Scale = ScaleM,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("8-Speed", "Manual-L", "8Gear-LD-L", {
		MaxGear = 8,
		Scale = ScaleL,
		DualClutch = true,
	})

	-- Transaxial Gearboxes
	Gearboxes.AddItemAlias("8-Speed", "Manual-T", "8Gear-T-S", {
		MaxGear = 8,
		Scale = ScaleS,
	})

	Gearboxes.AddItemAlias("8-Speed", "Manual-T", "8Gear-T-M", {
		MaxGear = 8,
		Scale = ScaleM,
	})

	Gearboxes.AddItemAlias("8-Speed", "Manual-T", "8Gear-T-L", {
		MaxGear = 8,
		Scale = ScaleL,
	})

	-- Transaxial Dual Clutch Gearboxes
	Gearboxes.AddItemAlias("8-Speed", "Manual-T", "8Gear-TD-S", {
		MaxGear = 8,
		Scale = ScaleS,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("8-Speed", "Manual-T", "8Gear-TD-M", {
		MaxGear = 8,
		Scale = ScaleM,
		DualClutch = true,
	})

	Gearboxes.AddItemAlias("8-Speed", "Manual-T", "8Gear-TD-L", {
		MaxGear = 8,
		Scale = ScaleL,
		DualClutch = true,
	})

	-- Straight-through Gearboxes
	Gearboxes.AddItemAlias("8-Speed", "Manual-ST", "8Gear-ST-S", {
		MaxGear = 8,
		Scale = ScaleS,
	})

	Gearboxes.AddItemAlias("8-Speed", "Manual-ST", "8Gear-ST-M", {
		MaxGear = 8,
		Scale = ScaleM,
	})

	Gearboxes.AddItemAlias("8-Speed", "Manual-ST", "8Gear-ST-L", {
		MaxGear = 8,
		Scale = ScaleL,
	})
end