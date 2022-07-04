local ACF       = ACF
local Gearboxes = ACF.Classes.Gearboxes

-- Weight
local CTW = 2
local CSW = 5
local CMW = 10
local CLW = 20

-- Torque Rating
local CTT = 75
local CST = 650
local CMT = 1400
local CLT = 8000

-- general description
local CDesc = "A standalone clutch for when a full size gearbox is unnecessary or too long."

Gearboxes.Register("Clutch", {
	Name		= "Clutch",
	CreateMenu	= ACF.ManualGearboxMenu,
	Gears = {
		Min	= 0,
		Max	= 1,
	}
})

do -- Straight-through Gearboxes
	Gearboxes.RegisterItem("Clutch-S-T", "Clutch", {
		Name		= "Clutch, Straight, Tiny",
		Description	= CDesc,
		Model		= "models/engines/flywheelclutcht.mdl",
		Mass		= CTW,
		Switch		= 0.1,
		MaxTorque	= CTT,
		Preview = {
			FOV = 115,
		},
	})

	Gearboxes.RegisterItem("Clutch-S-S", "Clutch", {
		Name		= "Clutch, Straight, Small",
		Description	= CDesc,
		Model		= "models/engines/flywheelclutchs.mdl",
		Mass		= CSW,
		Switch		= 0.15,
		MaxTorque	= CST,
		Preview = {
			FOV = 115,
		},
	})

	Gearboxes.RegisterItem("Clutch-S-M", "Clutch", {
		Name		= "Clutch, Straight, Medium",
		Description	= CDesc,
		Model		= "models/engines/flywheelclutchm.mdl",
		Mass		= CMW,
		Switch		= 0.2,
		MaxTorque	= CMT,
		Preview = {
			FOV = 115,
		},
	})

	Gearboxes.RegisterItem("Clutch-S-L", "Clutch", {
		Name		= "Clutch, Straight, Large",
		Description	= CDesc,
		Model		= "models/engines/flywheelclutchb.mdl",
		Mass		= CLW,
		Switch		= 0.3,
		MaxTorque	= CLT,
		Preview = {
			FOV = 115,
		},
	})
end

ACF.SetCustomAttachments("models/engines/flywheelclutchb.mdl", {
	{ Name = "input", Pos = Vector(), Ang = Angle(0, 0, 90) },
	{ Name = "driveshaftR", Pos = Vector(0, 6), Ang = Angle(0, 180, 90) },
	{ Name = "driveshaftL", Pos = Vector(0, 6), Ang = Angle(0, 180, 90) },
})
ACF.SetCustomAttachments("models/engines/flywheelclutchm.mdl", {
	{ Name = "input", Pos = Vector(), Ang = Angle(0, 0, 90) },
	{ Name = "driveshaftR", Pos = Vector(0, 4), Ang = Angle(0, 180, 90) },
	{ Name = "driveshaftL", Pos = Vector(0, 4), Ang = Angle(0, 180, 90) },
})
ACF.SetCustomAttachments("models/engines/flywheelclutchs.mdl", {
	{ Name = "input", Pos = Vector(), Ang = Angle(0, 0, 90) },
	{ Name = "driveshaftR", Pos = Vector(0, 3), Ang = Angle(0, 180, 90) },
	{ Name = "driveshaftL", Pos = Vector(0, 3), Ang = Angle(0, 180, 90) },
})
ACF.SetCustomAttachments("models/engines/flywheelclutcht.mdl", {
	{ Name = "input", Pos = Vector(), Ang = Angle(0, 0, 90) },
	{ Name = "driveshaftR", Pos = Vector(0, 2), Ang = Angle(0, 180, 90) },
	{ Name = "driveshaftL", Pos = Vector(0, 2), Ang = Angle(0, 180, 90) },
})

local Models = {
	{ Model = "models/engines/flywheelclutchb.mdl", Scale = 3 },
	{ Model = "models/engines/flywheelclutchm.mdl", Scale = 2 },
	{ Model = "models/engines/flywheelclutchs.mdl", Scale = 1.5 },
	{ Model = "models/engines/flywheelclutcht.mdl", Scale = 1 },
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
