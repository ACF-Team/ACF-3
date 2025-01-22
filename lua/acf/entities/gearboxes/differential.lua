local ACF       = ACF
local Gearboxes = ACF.Classes.Gearboxes

local Gear1SW = 10

-- Old gearbox scales
local ScaleT = 0.75
local ScaleS = 1
local ScaleM = 1.5
local ScaleL = 2.5

Gearboxes.Register("Differential", {
	Name		= "Differential",
	CreateMenu	= ACF.ManualGearboxMenu,
	Gears = {
		Min	= 0,
		Max	= 1,
	}
})

do -- Scalable Gearboxes
	Gearboxes.RegisterItem("1Gear-L", "Differential", {
		Name			= "Differential, Inline",
		Description		= "An inline gearbox used to connect power from another gearbox to the wheels.",
		Model			= "models/engines/linear_s.mdl",
		Mass			= Gear1SW,
		Switch			= 0.3,
		MaxTorque		= 25000,
		CanDualClutch	= true,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("1Gear-T", "Differential", {
		Name			= "Differential, Transaxial",
		Description		= "A transaxial gearbox used to connect power from another gearbox to the wheels.",
		Model			= "models/engines/transaxial_s.mdl",
		Mass			= Gear1SW,
		Switch			= 0.3,
		MaxTorque		= 25000,
		CanDualClutch	= true,
		Preview = {
			FOV = 85,
		},
	})
end

do -- Pre-Scalable Gearboxes
	-- Inline Gearboxes
	Gearboxes.AddItemAlias("Differential", "1Gear-L", "1Gear-L-S", {
		Scale = ScaleS,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("Differential", "1Gear-L", "1Gear-L-M", {
		Scale = ScaleM,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("Differential", "1Gear-L", "1Gear-L-L", {
		Scale = ScaleL,
		InvertGearRatios = true,
	})

	-- Inline Dual Clutch Gearboxes
	Gearboxes.AddItemAlias("Differential", "1Gear-L", "1Gear-LD-S", {
		Scale = ScaleS,
		DualClutch = true,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("Differential", "1Gear-L", "1Gear-LD-M", {
		Scale = ScaleM,
		DualClutch = true,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("Differential", "1Gear-L", "1Gear-LD-L", {
		Scale = ScaleL,
		DualClutch = true,
		InvertGearRatios = true,
	})

	-- Transaxial Gearboxes
	Gearboxes.AddItemAlias("Differential", "1Gear-T", "1Gear-T-S", {
		Scale = ScaleS,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("Differential", "1Gear-T", "1Gear-T-M", {
		Scale = ScaleM,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("Differential", "1Gear-T", "1Gear-T-L", {
		Scale = ScaleL,
		InvertGearRatios = true,
	})

	-- Transaxial Dual Clutch Gearboxes
	Gearboxes.AddItemAlias("Differential", "1Gear-T", "1Gear-TD-S", {
		Scale = ScaleS,
		DualClutch = true,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("Differential", "1Gear-T", "1Gear-TD-M", {
		Scale = ScaleM,
		DualClutch = true,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("Differential", "1Gear-T", "1Gear-TD-L", {
		Scale = ScaleL,
		DualClutch = true,
		InvertGearRatios = true,
	})
end

do -- ACF Extras Gearboxes (Pre-Scalable)
	-- Inline Gearboxes
	Gearboxes.AddItemAlias("Differential", "1Gear-L", "1Gear-L-T", {
		Scale = ScaleT,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("Differential", "1Gear-L", "1Gear-LD-T", {
		Scale = ScaleT,
		DualClutch = true,
		InvertGearRatios = true,
	})

	-- Transaxial Gearboxes
	Gearboxes.AddItemAlias("Differential", "1Gear-T", "1Gear-T-T", {
		Scale = ScaleT,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("Differential", "1Gear-T", "1Gear-TD-T", {
		Scale = ScaleT,
		DualClutch = true,
		InvertGearRatios = true,
	})
end

ACF.SetCustomAttachments("models/engines/transaxial_s.mdl", {
	{ Name = "driveshaftR", Pos = Vector(0, 8, 3.2), Ang = Angle(0, 90, 90) },
	{ Name = "driveshaftL", Pos = Vector(0, -8, 3.2), Ang = Angle(0, -90, 90) },
	{ Name = "input", Pos = Vector(8, 0, 3.2), Ang = Angle(0, 0, 90) },
})
ACF.SetCustomAttachments("models/engines/linear_s.mdl", {
	{ Name = "driveshaftR", Pos = Vector(0, 8, 3.2), Ang = Angle(0, 90, 90) },
	{ Name = "driveshaftL", Pos = Vector(0, -9.6, 3.2), Ang = Angle(0, -90, 90) },
	{ Name = "input", Pos = Vector(0, 1.6, 11.6), Ang = Angle(0, -90, 90) },
})

local Transaxial = {
	{ Model = "models/engines/transaxial_s.mdl", Scale = 1 },
}

local Linears = {
	{ Model = "models/engines/linear_s.mdl", Scale = 1 },
}

for _, Data in ipairs(Transaxial) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Axle = {
			Pos       = Vector(0, 0, 3.25) * Scale,
			Scale     = Vector(6.5, 16, 6.5) * Scale,
			Sensitive = true
		},
		In = {
			Pos   = Vector(5.5, 0, 3.25) * Scale,
			Scale = Vector(4.5, 6.5, 6.5) * Scale
		}
	})
end

for _, Data in ipairs(Linears) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Straight = {
			Pos       = Vector(0, -0.5, 3.25) * Scale,
			Scale     = Vector(6.5, 18, 6.5) * Scale,
			Sensitive = true
		},
		In = {
			Pos   = Vector(0, 4.75, 11) * Scale,
			Scale = Vector(6.5, 7.5, 9) * Scale
		}
	})
end
