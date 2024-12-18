local ACF       = ACF
local Gearboxes = ACF.Classes.Gearboxes

-- Weight
local Gear4SW = 60
--local Gear4MW = 120
--local Gear4LW = 240
local StWB = 0.75 --straight weight bonus mulitplier

-- Torque Rating
local Gear4ST = 540
--local Gear4MT = 1700
--local Gear4LT = 10000
local StTB = 1.25 --straight torque bonus multiplier

Gearboxes.Register("Manual", {
	Name		= "Manual",
	CreateMenu	= ACF.ManualGearboxMenu,
	CanSetGears = true,
	Gears = {
		Min	= 0,
		Max	= 8,
	},
	IsScalable	= true,
})

do -- Scalable Gearboxes
	Gearboxes.RegisterItem("Manual-L", "Manual", {
		Name			= "Manual, Inline",
		Description		= "A standard inline gearbox.",
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
		Description		= "A small, and light 4 speed gearbox, with a somewhat limited max torque rating.",
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
		Description	= "A small straight-through gearbox.",
		Model		= "models/engines/t5small.mdl",
		Mass		= math.floor(Gear4SW * StWB),
		Switch		= 0.15,
		MaxTorque	= math.floor(Gear4ST * StTB),
		Preview = {
			FOV = 105,
		},
	})
end