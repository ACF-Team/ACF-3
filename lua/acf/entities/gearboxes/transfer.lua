local ACF       = ACF
local Gearboxes = ACF.Classes.Gearboxes

local Gear2SW = 20
local Gear2MW = 40
local Gear2LW = 80

Gearboxes.Register("Transfer", {
	Name		= "Transfer Case",
	CreateMenu	= ACF.ManualGearboxMenu,
	Gears = {
		Min	= 0,
		Max	= 2,
	}
})

do -- Inline Gearboxes
	Gearboxes.RegisterItem("2Gear-L-S", "Transfer", {
		Name		= "Transfer case, Inline, Small",
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
		Name		= "Transfer case, Inline, Medium",
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
		Name		= "Transfer case, Inline, Large",
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
		Name		= "Transfer case, Small",
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
		Name		= "Transfer case, Medium",
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
		Name		= "Transfer case, Large",
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
