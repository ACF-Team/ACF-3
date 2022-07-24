-- CVT (continuously variable transmission)
local ACF       = ACF
local Gearboxes = ACF.Classes.Gearboxes

-- Weight
local GearCVTSW = 65
local GearCVTMW = 180
local GearCVTLW = 500
local StWB = 0.75 --straight weight bonus mulitplier
-- Torque Rating
local GearCVTST = 175
local GearCVTMT = 650
local GearCVTLT = 6000
local StTB = 1.25 --straight torque bonus multiplier

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

do -- Inline Gearboxes
	Gearboxes.RegisterItem("CVT-L-S", "CVT", {
		Name		= "CVT, Inline, Small",
		Description	= "A light duty inline CVT.",
		Model		= "models/engines/linear_s.mdl",
		Mass		= GearCVTSW,
		Switch		= 0.15,
		MaxTorque	= GearCVTST,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("CVT-L-M", "CVT", {
		Name		= "CVT, Inline, Medium",
		Description	= "A medium inline CVT.",
		Model		= "models/engines/linear_m.mdl",
		Mass		= GearCVTMW,
		Switch		= 0.2,
		MaxTorque	= GearCVTMT,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("CVT-L-L", "CVT", {
		Name		= "CVT, Inline, Large",
		Description	= "A massive inline CVT designed for high torque applications.",
		Model		= "models/engines/linear_l.mdl",
		Mass		= GearCVTLW,
		Switch		= 0.3,
		MaxTorque	= GearCVTLT,
		Preview = {
			FOV = 125,
		},
	})
end

do -- Inline Dual Clutch Gearboxes
	Gearboxes.RegisterItem("CVT-LD-S", "CVT", {
		Name		= "CVT, Inline, Small, Dual Clutch",
		Description	= "A light duty inline CVT. The dual clutch allows you to apply power and brake each side independently.",
		Model		= "models/engines/linear_s.mdl",
		Mass		= GearCVTSW,
		Switch		= 0.15,
		MaxTorque	= GearCVTST,
		DualClutch	= true,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("CVT-LD-M", "CVT", {
		Name		= "CVT, Inline, Medium, Dual Clutch",
		Description	= "A medium inline CVT. The dual clutch allows you to apply power and brake each side independently.",
		Model		= "models/engines/linear_m.mdl",
		Mass		= GearCVTMW,
		Switch		= 0.2,
		MaxTorque	= GearCVTMT,
		DualClutch	= true,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("CVT-LD-L", "CVT", {
		Name		= "CVT, Inline, Large, Dual Clutch",
		Description	= "A massive inline CVT designed for high torque applications. The dual clutch allows you to apply power and brake each side independently.",
		Model		= "models/engines/linear_l.mdl",
		Mass		= GearCVTLW,
		Switch		= 0.3,
		MaxTorque	= GearCVTLT,
		DualClutch	= true,
		Preview = {
			FOV = 125,
		},
	})
end

do -- Transaxial Gearboxes
	Gearboxes.RegisterItem("CVT-T-S", "CVT", {
		Name		= "CVT, Transaxial, Small",
		Description	= "A light duty CVT.",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= GearCVTSW,
		Switch		= 0.15,
		MaxTorque	= GearCVTST,
		Preview = {
			FOV = 85,
		},
	})

	Gearboxes.RegisterItem("CVT-T-M", "CVT", {
		Name		= "CVT, Transaxial, Medium",
		Description	= "A medium CVT.",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= GearCVTMW,
		Switch		= 0.2,
		MaxTorque	= GearCVTMT,
		Preview = {
			FOV = 85,
		},
	})

	Gearboxes.RegisterItem("CVT-T-L", "CVT", {
		Name		= "CVT, Transaxial, Large",
		Description	= "A massive CVT designed for high torque applications.",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= GearCVTLW,
		Switch		= 0.3,
		MaxTorque	= GearCVTLT,
		Preview = {
			FOV = 85,
		},
	})
end

do -- Transaxial Dual Clutch Gearboxes
	Gearboxes.RegisterItem("CVT-TD-S", "CVT", {
		Name		= "CVT, Transaxial, Small, Dual Clutch",
		Description	= "A light duty CVT. The dual clutch allows you to apply power and brake each side independently.",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= GearCVTSW,
		Switch		= 0.15,
		MaxTorque	= GearCVTST,
		DualClutch	= true,
		Preview = {
			FOV = 85,
		},
	})

	Gearboxes.RegisterItem("CVT-TD-M", "CVT", {
		Name		= "CVT, Transaxial, Medium, Dual Clutch",
		Description	= "A medium CVT. The dual clutch allows you to apply power and brake each side independently.",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= GearCVTMW,
		Switch		= 0.2,
		MaxTorque	= GearCVTMT,
		DualClutch	= true,
		Preview = {
			FOV = 85,
		},
	})

	Gearboxes.RegisterItem("CVT-TD-L", "CVT", {
		Name		= "CVT, Transaxial, Large, Dual Clutch",
		Description	= "A massive CVT designed for high torque applications. The dual clutch allows you to apply power and brake each side independently.",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= GearCVTLW,
		Switch		= 0.3,
		MaxTorque	= GearCVTLT,
		DualClutch	= true,
		Preview = {
			FOV = 85,
		},
	})
end

do -- Straight-through Gearboxes
	Gearboxes.RegisterItem("CVT-ST-S", "CVT", {
		Name		= "CVT, Straight, Small",
		Description	= "A light duty straight-through CVT.",
		Model		= "models/engines/t5small.mdl",
		Mass		= math.floor(GearCVTSW * StWB),
		Switch		= 0.15,
		MaxTorque	= math.floor(GearCVTST * StTB),
		Preview = {
			FOV = 105,
		},
	})

	Gearboxes.RegisterItem("CVT-ST-M", "CVT", {
		Name		= "CVT, Straight, Medium",
		Description	= "A medium straight-through CVT.",
		Model		= "models/engines/t5med.mdl",
		Mass		= math.floor(GearCVTMW * StWB),
		Switch		= 0.2,
		MaxTorque	= math.floor(GearCVTMT * StTB),
		Preview = {
			FOV = 105,
		},
	})

	Gearboxes.RegisterItem("CVT-ST-L", "CVT", {
		Name		= "CVT, Straight, Large",
		Description	= "A massive straight-through CVT designed for high torque applications.",
		Model		= "models/engines/t5large.mdl",
		Mass		= math.floor(GearCVTLW * StWB),
		Switch		= 0.3,
		MaxTorque	= math.floor(GearCVTLT * StTB),
		Preview = {
			FOV = 105,
		},
	})
end

ACF.SetCustomAttachments("models/engines/t5large.mdl", {
	{ Name = "input", Pos = Vector(), Ang = Angle(0, 0, 90) },
	{ Name = "driveshaftR", Pos = Vector(0, 30), Ang = Angle(0, -180, 90) },
	{ Name = "driveshaftL", Pos = Vector(0, 30), Ang = Angle(0, -180, 90) },
})
ACF.SetCustomAttachments("models/engines/t5med.mdl", {
	{ Name = "input", Pos = Vector(), Ang = Angle(0, 0, 90) },
	{ Name = "driveshaftR", Pos = Vector(0, 25), Ang = Angle(0, -180, 90) },
	{ Name = "driveshaftL", Pos = Vector(0, 25), Ang = Angle(0, -180, 90) },
})
ACF.SetCustomAttachments("models/engines/t5small.mdl", {
	{ Name = "input", Pos = Vector(), Ang = Angle(0, 0, 90) },
	{ Name = "driveshaftR", Pos = Vector(0, 20), Ang = Angle(0, -180, 90) },
	{ Name = "driveshaftL", Pos = Vector(0, 20), Ang = Angle(0, -180, 90) },
})

local Models = {
	{ Model = "models/engines/t5large.mdl", Scale = 2 },
	{ Model = "models/engines/t5med.mdl", Scale = 1.5 },
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
