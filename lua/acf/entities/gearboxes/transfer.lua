local ACF       = ACF
local Gearboxes = ACF.Classes.Gearboxes

local Gear2SW = 20
--local Gear2MW = 40
--local Gear2LW = 80

-- Old gearbox scales
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
		MaxTorque		= 25000,
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
		MaxTorque		= 25000,
		DualClutch		= true,
		Preview = {
			FOV = 85,
		},
	})
end

do -- Inline Gearboxes
	Gearboxes.AddItemAlias("Transfer", "2Gear-L", "2Gear-L-S", {
		Scale = ScaleS,
	})

	Gearboxes.AddItemAlias("Transfer", "2Gear-L", "2Gear-L-M", {
		Scale = ScaleM,
	})

	Gearboxes.AddItemAlias("Transfer", "2Gear-L", "2Gear-L-L", {
		Scale = ScaleL,
	})
end

do
	Gearboxes.AddItemAlias("Transfer", "2Gear-T", "2Gear-T-S", {
		Scale = ScaleS,
	})

	Gearboxes.AddItemAlias("Transfer", "2Gear-T", "2Gear-T-M", {
		Scale = ScaleM,
	})

	Gearboxes.AddItemAlias("Transfer", "2Gear-T", "2Gear-T-L", {
		Scale = ScaleL,
	})
end
--[[
do -- Inline Gearboxes
	Gearboxes.RegisterItem("2Gear-L-S", "Transfer", {
		Name		= "Transfer Case, Inline, Small",
		Description	= "2 speed gearbox, useful for low/high range and tank turning",
		Model		= "models/engines/linear_s.mdl",
		Mass		= Gear2SW,
		Switch		= 0.3,
		MaxTorque	= 25000,
		DualClutch	= true,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("2Gear-L-M", "Transfer", {
		Name		= "Transfer Case, Inline, Medium",
		Description	= "2 speed gearbox, useful for low/high range and tank turning",
		Model		= "models/engines/linear_m.mdl",
		Mass		= Gear2MW,
		Switch		= 0.4,
		MaxTorque	= 50000,
		DualClutch	= true,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("2Gear-L-L", "Transfer", {
		Name		= "Transfer Case, Inline, Large",
		Description	= "2 speed gearbox, useful for low/high range and tank turning",
		Model		= "models/engines/linear_l.mdl",
		Mass		= Gear2LW,
		Switch		= 0.6,
		MaxTorque	= 100000,
		DualClutch	= true,
		Preview = {
			FOV = 125,
		},
	})
end

do -- Transaxial Gearboxes
	Gearboxes.RegisterItem("2Gear-T-S", "Transfer", {
		Name		= "Transfer Case, Small",
		Description	= "2 speed gearbox, useful for low/high range and tank turning",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= Gear2SW,
		Switch		= 0.3,
		MaxTorque	= 25000,
		DualClutch	= true,
		Preview = {
			FOV = 85,
		},
	})

	Gearboxes.RegisterItem("2Gear-T-M", "Transfer", {
		Name		= "Transfer Case, Medium",
		Description	= "2 speed gearbox, useful for low/high range and tank turning",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= Gear2MW,
		Switch		= 0.4,
		MaxTorque	= 50000,
		DualClutch	= true,
		Preview = {
			FOV = 85,
		},
	})

	Gearboxes.RegisterItem("2Gear-T-L", "Transfer", {
		Name		= "Transfer Case, Large",
		Description	= "2 speed gearbox, useful for low/high range and tank turning",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= Gear2LW,
		Switch		= 0.6,
		MaxTorque	= 100000,
		DualClutch	= true,
		Preview = {
			FOV = 85,
		},
	})
end
]]