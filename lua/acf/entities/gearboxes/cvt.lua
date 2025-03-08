-- CVT (continuously variable transmission)
local ACF       = ACF
local Gearboxes = ACF.Classes.Gearboxes

-- Weight
local GearCVTSW = 65
local StWB = 0.75 -- Straight weight bonus mulitplier

-- Torque Rating
local GearCVTST = 700
local StTB = 1.25 -- Straight torque bonus multiplier

-- Old gearbox scales
local ScaleS = 1
local ScaleM = 1.5
local ScaleL = 2.5
local StScaleL = 2 -- Straight gearbox large scale

local function InitGearbox(Gearbox)
	local Gears = Gearbox.Gears

	Gearbox.CVT      = true
	Gearbox.CVTRatio = 0

	WireLib.TriggerOutput(Gearbox, "Min Target RPM", Gears.MinRPM)
	WireLib.TriggerOutput(Gearbox, "Max Target RPM", Gears.MaxRPM)
end

Gearboxes.Register("CVT", {
	Name		= "CVT",
	CreateMenu	= ACF.CVTGearboxMenu,
	Gears = {
		Min		= 0,
		Max		= 2,
	},
	OnSpawn = InitGearbox,
	OnUpdate = InitGearbox,
	VerifyData = function(Data)
		local Min, Max = Data.MinRPM, Data.MaxRPM

		Data.Gears[1] = 0.01

		if not Min then
			Min = ACF.CheckNumber(Data.Gear3, 3000)

			Data.Gear3 = nil
		end

		if not Max then
			Max = ACF.CheckNumber(Data.Gear4, 5000)

			Data.Gear4 = nil
		end

		Data.MinRPM = math.Clamp(Min, 1, 9900)
		Data.MaxRPM = math.Clamp(Max, Data.MinRPM + 100, 10000)
	end,
	SetupInputs = function(_, List)
		List[#List + 1] = "CVT Ratio (Manually sets the gear ratio on the gearbox.)"
	end,
	SetupOutputs = function(_, List)
		local Count = #List

		List[Count + 1] = "Min Target RPM (Sets the lower targeted RPM for the CVT to maintain.)"
		List[Count + 2] = "Max Target RPM (Sets the upper targeted RPM for the CVT to maintain.)"
	end,
	OnLast = function(Gearbox)
		Gearbox.CVT      = nil
		Gearbox.CVTRatio = nil
	end,
	GetGearsText = function(Gearbox)
		local Text    = "Reverse Gear: %s\nTarget: %s - %s RPM"
		local Gears   = Gearbox.Gears
		local Reverse = math.Round(Gears[2], 2)
		local Min     = math.Round(Gearbox.MinRPM)
		local Max     = math.Round(Gearbox.MaxRPM)

		return Text:format(Reverse, Min, Max)
	end,
})

do -- Scalable Gearboxes
	Gearboxes.RegisterItem("CVT-L", "CVT", {
		Name			= "CVT, Inline",
		Description		= "An inline gearbox capable of keeping an engine within a specified RPM range by constantly adjusting the gear ratio.",
		Model			= "models/engines/linear_s.mdl",
		Mass			= GearCVTSW,
		Switch			= 0.15,
		MaxTorque		= GearCVTST,
		CanDualClutch	= true,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("CVT-T", "CVT", {
		Name			= "CVT, Transaxial",
		Description		= "A transaxial gearbox capable of keeping an engine within a specified RPM range by constantly adjusting the gear ratio.",
		Model			= "models/engines/transaxial_s.mdl",
		Mass			= GearCVTSW,
		Switch			= 0.15,
		MaxTorque		= GearCVTST,
		CanDualClutch	= true,
		Preview = {
			FOV = 85,
		},
	})

	Gearboxes.RegisterItem("CVT-ST", "CVT", {
		Name		= "CVT, Straight",
		Description	= "A straight-through gearbox capable of keeping an engine within a specified RPM range by constantly adjusting the gear ratio.",
		Model		= "models/engines/t5small.mdl",
		Mass		= math.floor(GearCVTSW * StWB),
		Switch		= 0.15,
		MaxTorque	= math.floor(GearCVTST * StTB),
		Preview = {
			FOV = 105,
		},
	})
end

do -- Inline Gearboxes
	Gearboxes.AddItemAlias("CVT", "CVT-L", "CVT-L-S", {
		Scale = ScaleS,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("CVT", "CVT-L", "CVT-L-M", {
		Scale = ScaleM,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("CVT", "CVT-L", "CVT-L-L", {
		Scale = ScaleL,
		InvertGearRatios = true,
	})
end

do -- Inline Dual Clutch Gearboxes
	Gearboxes.AddItemAlias("CVT", "CVT-L", "CVT-LD-S", {
		Scale = ScaleS,
		DualClutch = true,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("CVT", "CVT-L", "CVT-LD-M", {
		Scale = ScaleM,
		DualClutch = true,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("CVT", "CVT-L", "CVT-LD-L", {
		Scale = ScaleL,
		DualClutch = true,
		InvertGearRatios = true,
	})
end

do -- Transaxial Gearboxes
	Gearboxes.AddItemAlias("CVT", "CVT-T", "CVT-T-S", {
		Scale = ScaleS,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("CVT", "CVT-T", "CVT-T-M", {
		Scale = ScaleM,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("CVT", "CVT-T", "CVT-T-L", {
		Scale = ScaleL,
		InvertGearRatios = true,
	})
end

do -- Transaxial Dual Clutch Gearboxes
	Gearboxes.AddItemAlias("CVT", "CVT-T", "CVT-TD-S", {
		Scale = ScaleS,
		DualClutch = true,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("CVT", "CVT-T", "CVT-TD-M", {
		Scale = ScaleM,
		DualClutch = true,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("CVT", "CVT-T", "CVT-TD-L", {
		Scale = ScaleL,
		DualClutch = true,
		InvertGearRatios = true,
	})
end

do -- Straight-through Gearboxes
	Gearboxes.AddItemAlias("CVT", "CVT-ST", "CVT-ST-S", {
		Scale = ScaleS,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("CVT", "CVT-ST", "CVT-ST-M", {
		Scale = ScaleM,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("CVT", "CVT-ST", "CVT-ST-L", {
		Scale = StScaleL,
		InvertGearRatios = true,
	})
end

ACF.SetCustomAttachments("models/engines/t5small.mdl", {
	{ Name = "input", Pos = Vector(), Ang = Angle(0, 0, 90) },
	{ Name = "driveshaftR", Pos = Vector(0, 20), Ang = Angle(0, -180, 90) },
	{ Name = "driveshaftL", Pos = Vector(0, 20), Ang = Angle(0, -180, 90) },
})

local Models = {
	{ Model = "models/engines/t5small.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Straight = {
			Pos       = Vector(0, 12.5, -0.75) * Scale,
			Scale     = Vector(6.5, 15, 8) * Scale,
			Sensitive = true
		},
		Clutch = {
			Pos   = Vector(0, 2.5, 0) * Scale,
			Scale = Vector(11, 5, 11) * Scale
		}
	})
end