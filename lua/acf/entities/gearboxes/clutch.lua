local ACF       = ACF
local Classes   = ACF.Classes

-- Weight
local CSW = 5

-- Torque Rating
local CST = 3000

-- General description
local CDesc = "A standalone clutch for when a full size gearbox is unnecessary or too long."

Classes.DefineClass("ACF.Gearboxes.Clutch", "ACF.Gearboxes.BaseGearbox", function()
	CLASS.Name		= "Clutch"
	CLASS.CreateMenu	= ACF.ManualGearboxMenu
	CLASS.Gears = {
		Min	= 0,
		Max	= 1,
	}
end)

do -- Scalable Clutch
	Classes.DefineClass("ACF.Gearboxes.Clutch-S", "ACF.Gearboxes.Clutch", function()
		CLASS.Name		= "Clutch, Straight"
		CLASS.Description	= CDesc
		CLASS.Model		= "models/engines/flywheelclutchs.mdl"
		CLASS.Mass		= CSW
		CLASS.Switch		= 0.15
		CLASS.MaxTorque	= CST
		CLASS.Preview = {
			FOV = 115,
		}
	end)
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