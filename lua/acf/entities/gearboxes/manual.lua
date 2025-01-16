local ACF       = ACF
local Gearboxes = ACF.Classes.Gearboxes

-- Weight
local Gear4SW = 60
local StWB = 0.75 -- Straight weight bonus mulitplier

-- Torque Rating
local Gear4ST = 540
local StTB = 1.25 -- Straight torque bonus multiplier

-- Old gearbox scales
local ScaleS = 1
local ScaleM = 1.5
local ScaleL = 2.5

Gearboxes.Register("Manual", {
	Name		= "Manual",
	CreateMenu	= ACF.ManualGearboxMenu,
	CanSetGears = true,
	Gears = {
		Min	= 0,
		Max	= 9,
	},
	IsScalable	= true,
})

do -- Scalable Gearboxes
	Gearboxes.RegisterItem("Manual-L", "Manual", {
		Name			= "Manual, Inline",
		Description		= "A standard inline gearbox that requires manual gear shifting.",
		Model			= "models/engines/linear_s.mdl",
		Mass			= Gear4SW,
		Switch			= 0.15,
		MaxTorque		= Gear4ST,
		CanDualClutch	= true,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("Manual-T", "Manual", {
		Name			= "Manual, Transaxial",
		Description		= "A standard transaxial gearbox that requires manual gear shifting.",
		Model			= "models/engines/transaxial_s.mdl",
		Mass			= Gear4SW,
		Switch			= 0.15,
		MaxTorque		= Gear4ST,
		CanDualClutch	= true,
		Preview = {
			FOV = 85,
		},
	})

	Gearboxes.RegisterItem("Manual-ST", "Manual", {
		Name		= "Manual, Straight",
		Description	= "A standard straight-through gearbox that requires manual gear shifting.",
		Model		= "models/engines/t5small.mdl",
		Mass		= math.floor(Gear4SW * StWB),
		Switch		= 0.15,
		MaxTorque	= math.floor(Gear4ST * StTB),
		Preview = {
			FOV = 105,
		},
	})
end

do -- 4-Speed Manual Gearboxes
	Gearboxes.AddAlias("Manual", "4-Speed")

	-- Inline Gearboxes
	Gearboxes.AddItemAlias("4-Speed", "Manual-L", "4Gear-L-S", {
		MaxGear = 4,
		Scale = ScaleS,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("4-Speed", "Manual-L", "4Gear-L-M", {
		MaxGear = 4,
		Scale = ScaleM,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("4-Speed", "Manual-L", "4Gear-L-L", {
		MaxGear = 4,
		Scale = ScaleL,
		InvertGearRatios = true,
	})

	-- Inline Dual Clutch Gearboxes
	Gearboxes.AddItemAlias("4-Speed", "Manual-L", "4Gear-LD-S", {
		MaxGear = 4,
		Scale = ScaleS,
		DualClutch = true,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("4-Speed", "Manual-L", "4Gear-LD-M", {
		MaxGear = 4,
		Scale = ScaleM,
		DualClutch = true,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("4-Speed", "Manual-L", "4Gear-LD-L", {
		MaxGear = 4,
		Scale = ScaleL,
		DualClutch = true,
		InvertGearRatios = true,
	})

	-- Transaxial Gearboxes
	Gearboxes.AddItemAlias("4-Speed", "Manual-T", "4Gear-T-S", {
		MaxGear = 4,
		Scale = ScaleS,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("4-Speed", "Manual-T", "4Gear-T-M", {
		MaxGear = 4,
		Scale = ScaleM,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("4-Speed", "Manual-T", "4Gear-T-L", {
		MaxGear = 4,
		Scale = ScaleL,
		InvertGearRatios = true,
	})

	-- Transaxial Dual Clutch Gearboxes
	Gearboxes.AddItemAlias("4-Speed", "Manual-T", "4Gear-TD-S", {
		MaxGear = 4,
		Scale = ScaleS,
		DualClutch = true,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("4-Speed", "Manual-T", "4Gear-TD-M", {
		MaxGear = 4,
		Scale = ScaleM,
		DualClutch = true,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("4-Speed", "Manual-T", "4Gear-TD-L", {
		MaxGear = 4,
		Scale = ScaleL,
		DualClutch = true,
		InvertGearRatios = true,
	})

	-- Straight-through Gearboxes
	Gearboxes.AddItemAlias("4-Speed", "Manual-ST", "4Gear-ST-S", {
		MaxGear = 4,
		Scale = ScaleS,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("4-Speed", "Manual-ST", "4Gear-ST-M", {
		MaxGear = 4,
		Scale = ScaleM,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("4-Speed", "Manual-ST", "4Gear-ST-L", {
		MaxGear = 4,
		Scale = ScaleL,
		InvertGearRatios = true,
	})
end

do -- 6-Speed Manual Gearboxes
	Gearboxes.AddAlias("Manual", "6-Speed")

	-- Inline Gearboxes
	Gearboxes.AddItemAlias("6-Speed", "Manual-L", "6Gear-L-S", {
		MaxGear = 6,
		Scale = ScaleS,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("6-Speed", "Manual-L", "6Gear-L-M", {
		MaxGear = 6,
		Scale = ScaleM,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("6-Speed", "Manual-L", "6Gear-L-L", {
		MaxGear = 6,
		Scale = ScaleL,
		InvertGearRatios = true,
	})

	-- Inline Dual Clutch Gearboxes
	Gearboxes.AddItemAlias("6-Speed", "Manual-L", "6Gear-LD-S", {
		MaxGear = 6,
		Scale = ScaleS,
		DualClutch = true,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("6-Speed", "Manual-L", "6Gear-LD-M", {
		MaxGear = 6,
		Scale = ScaleM,
		DualClutch = true,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("6-Speed", "Manual-L", "6Gear-LD-L", {
		MaxGear = 6,
		Scale = ScaleL,
		DualClutch = true,
		InvertGearRatios = true,
	})

	-- Transaxial Gearboxes
	Gearboxes.AddItemAlias("6-Speed", "Manual-T", "6Gear-T-S", {
		MaxGear = 6,
		Scale = ScaleS,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("6-Speed", "Manual-T", "6Gear-T-M", {
		MaxGear = 6,
		Scale = ScaleM,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("6-Speed", "Manual-T", "6Gear-T-L", {
		MaxGear = 6,
		Scale = ScaleL,
		InvertGearRatios = true,
	})

	-- Transaxial Dual Clutch Gearboxes
	Gearboxes.AddItemAlias("6-Speed", "Manual-T", "6Gear-TD-S", {
		MaxGear = 6,
		Scale = ScaleS,
		DualClutch = true,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("6-Speed", "Manual-T", "6Gear-TD-M", {
		MaxGear = 6,
		Scale = ScaleM,
		DualClutch = true,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("6-Speed", "Manual-T", "6Gear-TD-L", {
		MaxGear = 6,
		Scale = ScaleL,
		DualClutch = true,
		InvertGearRatios = true,
	})

	-- Straight-through Gearboxes
	Gearboxes.AddItemAlias("6-Speed", "Manual-ST", "6Gear-ST-S", {
		MaxGear = 6,
		Scale = ScaleS,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("6-Speed", "Manual-ST", "6Gear-ST-M", {
		MaxGear = 6,
		Scale = ScaleM,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("6-Speed", "Manual-ST", "6Gear-ST-L", {
		MaxGear = 6,
		Scale = ScaleL,
		InvertGearRatios = true,
	})
end

do -- 8-Speed Manual Gearboxes
	Gearboxes.AddAlias("Manual", "8-Speed")

	-- Inline Gearboxes
	Gearboxes.AddItemAlias("8-Speed", "Manual-L", "8Gear-L-S", {
		MaxGear = 8,
		Scale = ScaleS,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("8-Speed", "Manual-L", "8Gear-L-M", {
		MaxGear = 8,
		Scale = ScaleM,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("8-Speed", "Manual-L", "8Gear-L-L", {
		MaxGear = 8,
		Scale = ScaleL,
		InvertGearRatios = true,
	})

	-- Inline Dual Clutch Gearboxes
	Gearboxes.AddItemAlias("8-Speed", "Manual-L", "8Gear-LD-S", {
		MaxGear = 8,
		Scale = ScaleS,
		DualClutch = true,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("8-Speed", "Manual-L", "8Gear-LD-M", {
		MaxGear = 8,
		Scale = ScaleM,
		DualClutch = true,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("8-Speed", "Manual-L", "8Gear-LD-L", {
		MaxGear = 8,
		Scale = ScaleL,
		DualClutch = true,
		InvertGearRatios = true,
	})

	-- Transaxial Gearboxes
	Gearboxes.AddItemAlias("8-Speed", "Manual-T", "8Gear-T-S", {
		MaxGear = 8,
		Scale = ScaleS,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("8-Speed", "Manual-T", "8Gear-T-M", {
		MaxGear = 8,
		Scale = ScaleM,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("8-Speed", "Manual-T", "8Gear-T-L", {
		MaxGear = 8,
		Scale = ScaleL,
		InvertGearRatios = true,
	})

	-- Transaxial Dual Clutch Gearboxes
	Gearboxes.AddItemAlias("8-Speed", "Manual-T", "8Gear-TD-S", {
		MaxGear = 8,
		Scale = ScaleS,
		DualClutch = true,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("8-Speed", "Manual-T", "8Gear-TD-M", {
		MaxGear = 8,
		Scale = ScaleM,
		DualClutch = true,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("8-Speed", "Manual-T", "8Gear-TD-L", {
		MaxGear = 8,
		Scale = ScaleL,
		DualClutch = true,
		InvertGearRatios = true,
	})

	-- Straight-through Gearboxes
	Gearboxes.AddItemAlias("8-Speed", "Manual-ST", "8Gear-ST-S", {
		MaxGear = 8,
		Scale = ScaleS,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("8-Speed", "Manual-ST", "8Gear-ST-M", {
		MaxGear = 8,
		Scale = ScaleM,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("8-Speed", "Manual-ST", "8Gear-ST-L", {
		MaxGear = 8,
		Scale = ScaleL,
		InvertGearRatios = true,
	})
end