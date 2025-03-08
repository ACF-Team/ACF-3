local ACF       = ACF
local Gearboxes = ACF.Classes.Gearboxes

-- Weight
local Gear4SW = 50
local StWB = 0.75 -- Straight weight bonus mulitplier

-- Torque Rating
local Gear4ST = 1000
local StTB = 1.25 -- Straight torque bonus multiplier

-- Old gearbox scales
local ScaleT = 0.75
local ScaleS = 1
local ScaleM = 1.5
local ScaleL = 2.5
local StScaleL = 2 -- Straight gearbox large scale

Gearboxes.Register("Manual", {
	Name		= "Manual",
	CreateMenu	= ACF.ManualGearboxMenu,
	CanSetGears = true,
	Gears = {
		Min	= 0,
		Max	= 10,
	},
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

do -- Pre-Scalable 4/6/8-Speed Manual Gearboxes
	local OldGearValues = {4, 6, 8}

	for _, Gear in ipairs(OldGearValues) do
		local OldCategory = tostring(Gear .. "-Speed")
		local OldGear = tostring(Gear .. "Gear")

		Gearboxes.AddAlias("Manual", OldCategory)

		-- Inline Gearboxes
		Gearboxes.AddItemAlias(OldCategory, "Manual-L", OldGear .. "-L-S", {
			MaxGear = Gear,
			Scale = ScaleS,
			InvertGearRatios = true,
		})

		Gearboxes.AddItemAlias(OldCategory, "Manual-L", OldGear .. "-L-M", {
			MaxGear = Gear,
			Scale = ScaleM,
			InvertGearRatios = true,
		})

		Gearboxes.AddItemAlias(OldCategory, "Manual-L", OldGear .. "-L-L", {
			MaxGear = Gear,
			Scale = ScaleL,
			InvertGearRatios = true,
		})

		-- Inline Dual Clutch Gearboxes
		Gearboxes.AddItemAlias(OldCategory, "Manual-L", OldGear .. "-LD-S", {
			MaxGear = Gear,
			Scale = ScaleS,
			DualClutch = true,
			InvertGearRatios = true,
		})

		Gearboxes.AddItemAlias(OldCategory, "Manual-L", OldGear .. "-LD-M", {
			MaxGear = Gear,
			Scale = ScaleM,
			DualClutch = true,
			InvertGearRatios = true,
		})

		Gearboxes.AddItemAlias(OldCategory, "Manual-L", OldGear .. "-LD-L", {
			MaxGear = Gear,
			Scale = ScaleL,
			DualClutch = true,
			InvertGearRatios = true,
		})

		-- Transaxial Gearboxes
		Gearboxes.AddItemAlias(OldCategory, "Manual-T", OldGear .. "-T-S", {
			MaxGear = Gear,
			Scale = ScaleS,
			InvertGearRatios = true,
		})

		Gearboxes.AddItemAlias(OldCategory, "Manual-T", OldGear .. "-T-M", {
			MaxGear = Gear,
			Scale = ScaleM,
			InvertGearRatios = true,
		})

		Gearboxes.AddItemAlias(OldCategory, "Manual-T", OldGear .. "-T-L", {
			MaxGear = Gear,
			Scale = ScaleL,
			InvertGearRatios = true,
		})

		-- Transaxial Dual Clutch Gearboxes
		Gearboxes.AddItemAlias(OldCategory, "Manual-T", OldGear .. "-TD-S", {
			MaxGear = Gear,
			Scale = ScaleS,
			DualClutch = true,
			InvertGearRatios = true,
		})

		Gearboxes.AddItemAlias(OldCategory, "Manual-T", OldGear .. "-TD-M", {
			MaxGear = Gear,
			Scale = ScaleM,
			DualClutch = true,
			InvertGearRatios = true,
		})

		Gearboxes.AddItemAlias(OldCategory, "Manual-T", OldGear .. "-TD-L", {
			MaxGear = Gear,
			Scale = ScaleL,
			DualClutch = true,
			InvertGearRatios = true,
		})

		-- Straight-through Gearboxes
		Gearboxes.AddItemAlias(OldCategory, "Manual-ST", OldGear .. "-ST-S", {
			MaxGear = Gear,
			Scale = ScaleS,
			InvertGearRatios = true,
		})

		Gearboxes.AddItemAlias(OldCategory, "Manual-ST", OldGear .. "-ST-M", {
			MaxGear = Gear,
			Scale = ScaleM,
			InvertGearRatios = true,
		})

		Gearboxes.AddItemAlias(OldCategory, "Manual-ST", OldGear .. "-ST-L", {
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

		Gearboxes.AddAlias("Manual", OldCategory)

		-- Inline Gearboxes
		Gearboxes.AddItemAlias(OldCategory, "Manual-L", OldGear .. "-L-T", {
			MaxGear = Gear,
			Scale = ScaleT,
			InvertGearRatios = true,
		})

		Gearboxes.AddItemAlias(OldCategory, "Manual-L", OldGear .. "-LD-T", {
			MaxGear = Gear,
			Scale = ScaleT,
			DualClutch = true,
			InvertGearRatios = true,
		})

		-- Transaxial Gearboxes
		Gearboxes.AddItemAlias(OldCategory, "Manual-T", OldGear .. "-T-T", {
			MaxGear = Gear,
			Scale = ScaleT,
			InvertGearRatios = true,
		})

		Gearboxes.AddItemAlias(OldCategory, "Manual-T", OldGear .. "-TD-T", {
			MaxGear = Gear,
			Scale = ScaleT,
			DualClutch = true,
			InvertGearRatios = true,
		})

		-- Straight-through Gearboxes
		Gearboxes.AddItemAlias(OldCategory, "Manual-ST", OldGear .. "-ST-T", {
			MaxGear = Gear,
			Scale = ScaleT,
			InvertGearRatios = true,
		})
	end
end