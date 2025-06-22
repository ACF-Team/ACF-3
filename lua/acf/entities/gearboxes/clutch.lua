local ACF       = ACF
local Gearboxes = ACF.Classes.Gearboxes

-- Weight
local CSW = 5

-- Torque Rating
local CST = 3000

-- Old gearbox scales
local ScaleT = 0.75
local ScaleS = 1
local ScaleM = 1.5
local ScaleL = 2.5

-- General description
local CDesc = "A standalone clutch for when a full size gearbox is unnecessary or too long."

Gearboxes.Register("Clutch", {
	Name		= "Clutch",
	CreateMenu	= ACF.ManualGearboxMenu,
	Gears = {
		Min	= 0,
		Max	= 1,
	}
})

do -- Scalable Clutch
	Gearboxes.RegisterItem("Clutch-S", "Clutch", {
		Name		= "Clutch, Straight",
		Description	= CDesc,
		Model		= "models/engines/flywheelclutchs.mdl",
		Mass		= CSW,
		Switch		= 0.15,
		MaxTorque	= CST,
		Preview = {
			FOV = 115,
		},
	})
end

do -- Pre-Scalable Straight-through Gearboxes
	Gearboxes.AddItemAlias("Clutch", "Clutch-S", "Clutch-S-T", {
		Scale = ScaleT,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("Clutch", "Clutch-S", "Clutch-S-S", {
		Scale = ScaleS,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("Clutch", "Clutch-S", "Clutch-S-M", {
		Scale = ScaleM,
		InvertGearRatios = true,
	})

	Gearboxes.AddItemAlias("Clutch", "Clutch-S", "Clutch-S-L", {
		Scale = ScaleL,
		InvertGearRatios = true,
	})
end

ACF.SetCustomAttachments("models/engines/flywheelclutchs.mdl", {
	{ Name = "input", Pos = Vector(), Ang = Angle(0, 0, 90) },
	{ Name = "driveshaftR", Pos = Vector(0, 3), Ang = Angle(0, 180, 90) },
	{ Name = "driveshaftL", Pos = Vector(0, 3), Ang = Angle(0, 180, 90) },
})

local Models = {
	{ Model = "models/engines/flywheelclutchs.mdl", Scale = 1.5 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Clutch = {
			Pos       = Vector(0, 0.25) * Scale,
			Scale     = Vector(8, 4, 8) * Scale,
			Sensitive = true
		}
	})
end