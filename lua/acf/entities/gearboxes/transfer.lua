local ACF       = ACF
local Gearboxes = ACF.Classes.Gearboxes

local Gear2SW = 20

-- Old gearbox scales
local ScaleT = 0.75
local ScaleS = 1
local ScaleM = 1.5
local ScaleL = 2.5

Gearboxes.Register("Transfer", {
	Name		= "Transfer Case",
	CreateMenu	= ACF.ManualGearboxMenu,
	Gears = {
		Min	= 0,
		Max	= 2,
	}
})

do -- Scalable gearboxes
	Gearboxes.RegisterItem("2Gear-L", "Transfer", {
		Name			= "Transfer Case, Inline",
		Description		= "2 speed gearbox. Useful for low/high range and tank turning.",
		Model			= "models/engines/linear_s.mdl",
		Mass			= Gear2SW,
		Switch			= 0.3,
		MaxTorque		= 6000,
		DualClutch		= true,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("2Gear-T", "Transfer", {
		Name			= "Transfer Case",
		Description		= "2 speed gearbox. Useful for low/high range and tank turning.",
		Model			= "models/engines/transaxial_s.mdl",
		Mass			= Gear2SW,
		Switch			= 0.3,
		MaxTorque		= 6000,
		DualClutch		= true,
		Preview = {
			FOV = 85,
		},
	})
end