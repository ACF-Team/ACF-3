local ACF       = ACF
local Gearboxes = ACF.Classes.Gearboxes

-- Weight
local Gear4SW = 60
local Gear4MW = 120
local Gear4LW = 240
local StWB = 0.75 --straight weight bonus mulitplier

-- Torque Rating
local Gear4ST = 540
local Gear4MT = 1700
local Gear4LT = 10000
local StTB = 1.25 --straight torque bonus multiplier

Gearboxes.Register("4-Speed", {
	Name		= "4-Speed Gearbox",
	CreateMenu	= ACF.ManualGearboxMenu,
	Gears = {
		Min	= 0,
		Max	= 4,
	}
})

do -- Inline Gearboxes
	Gearboxes.RegisterItem("4Gear-L-S", "4-Speed", {
		Name		= "4-Speed, Inline, Small",
		Description	= "A small, and light 4 speed inline gearbox, with a somewhat limited max torque rating.",
		Model		= "models/engines/linear_s.mdl",
		Mass		= Gear4SW,
		Switch		= 0.15,
		MaxTorque	= Gear4ST,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("4Gear-L-M", "4-Speed", {
		Name		= "4-Speed, Inline, Medium",
		Description	= "A medium sized, 4 speed inline gearbox.",
		Model		= "models/engines/linear_m.mdl",
		Mass		= Gear4MW,
		Switch		= 0.2,
		MaxTorque	= Gear4MT,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("4Gear-L-L", "4-Speed", {
		Name		= "4-Speed, Inline, Large",
		Description	= "A large, heavy and sturdy 4 speed inline gearbox.",
		Model		= "models/engines/linear_l.mdl",
		Mass		= Gear4LW,
		Switch		= 0.3,
		MaxTorque	= Gear4LT,
		Preview = {
			FOV = 125,
		},
	})
end

do -- Inline Dual Clutch Gearboxes
	Gearboxes.RegisterItem("4Gear-LD-S", "4-Speed", {
		Name		= "4-Speed, Inline, Small, Dual Clutch",
		Description	= "A small, and light 4 speed inline gearbox, with a somewhat limited max torque rating.",
		Model		= "models/engines/linear_s.mdl",
		Mass		= Gear4SW,
		Switch		= 0.15,
		MaxTorque	= Gear4ST,
		DualClutch	= true,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("4Gear-LD-M", "4-Speed", {
		Name		= "4-Speed, Inline, Medium, Dual Clutch",
		Description	= "A medium sized, 4 speed inline gearbox.",
		Model		= "models/engines/linear_m.mdl",
		Mass		= Gear4MW,
		Switch		= 0.2,
		MaxTorque	= Gear4MT,
		DualClutch	= true,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("4Gear-LD-L", "4-Speed", {
		Name		= "4-Speed, Inline, Large, Dual Clutch",
		Description	= "A large, heavy and sturdy 4 speed inline gearbox.",
		Model		= "models/engines/linear_l.mdl",
		Mass		= Gear4LW,
		Switch		= 0.3,
		MaxTorque	= Gear4LT,
		DualClutch	= true,
		Preview = {
			FOV = 125,
		},
	})
end

do -- Transaxial Gearboxes
	Gearboxes.RegisterItem("4Gear-T-S", "4-Speed", {
		Name		= "4-Speed, Transaxial, Small",
		Description	= "A small, and light 4 speed gearbox, with a somewhat limited max torque rating.",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= Gear4SW,
		Switch		= 0.15,
		MaxTorque	= Gear4ST,
		Preview = {
			FOV = 85,
		},
	})

	Gearboxes.RegisterItem("4Gear-T-M", "4-Speed", {
		Name		= "4-Speed, Transaxial, Medium",
		Description	= "A medium sized, 4 speed gearbox.",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= Gear4MW,
		Switch		= 0.2,
		MaxTorque	= Gear4MT,
		Preview = {
			FOV = 85,
		},
	})

	Gearboxes.RegisterItem("4Gear-T-L", "4-Speed", {
		Name		= "4-Speed, Transaxial, Large",
		Description	= "A large, heavy and sturdy 4 speed gearbox.",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= Gear4LW,
		Switch		= 0.3,
		MaxTorque	= Gear4LT,
		Preview = {
			FOV = 85,
		},
	})
end

do -- Transaxial Dual Clutch Gearboxes
	Gearboxes.RegisterItem("4Gear-TD-S", "4-Speed", {
		Name		= "4-Speed, Transaxial, Small, Dual Clutch",
		Description	= "A small, and light 4 speed gearbox, with a somewhat limited max torque rating.",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= Gear4SW,
		Switch		= 0.15,
		MaxTorque	= Gear4ST,
		DualClutch	= true,
		Preview = {
			FOV = 85,
		},
	})

	Gearboxes.RegisterItem("4Gear-TD-M", "4-Speed", {
		Name		= "4-Speed, Transaxial, Medium, Dual Clutch",
		Description	= "A medium sized, 4 speed gearbox.",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= Gear4MW,
		Switch		= 0.2,
		MaxTorque	= Gear4MT,
		DualClutch	= true,
		Preview = {
			FOV = 85,
		},
	})

	Gearboxes.RegisterItem("4Gear-TD-L", "4-Speed", {
		Name		= "4-Speed, Transaxial, Large, Dual Clutch",
		Description	= "A large, heavy and sturdy 4 speed gearbox.",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= Gear4LW,
		Switch		= 0.3,
		MaxTorque	= Gear4LT,
		DualClutch	= true,
		Preview = {
			FOV = 85,
		},
	})
end

do -- Straight-through Gearboxes
	Gearboxes.RegisterItem("4Gear-ST-S", "4-Speed", {
		Name		= "4-Speed, Straight, Small",
		Description	= "A small straight-through gearbox.",
		Model		= "models/engines/t5small.mdl",
		Mass		= math.floor(Gear4SW * StWB),
		Switch		= 0.15,
		MaxTorque	= math.floor(Gear4ST * StTB),
		Preview = {
			FOV = 105,
		},
	})

	Gearboxes.RegisterItem("4Gear-ST-M", "4-Speed", {
		Name		= "4-Speed, Straight, Medium",
		Description	= "A medium sized, 4 speed straight-through gearbox.",
		Model		= "models/engines/t5med.mdl",
		Mass		= math.floor(Gear4MW * StWB),
		Switch		= 0.2,
		MaxTorque	= math.floor(Gear4MT * StTB),
		Preview = {
			FOV = 105,
		},
	})

	Gearboxes.RegisterItem("4Gear-ST-L", "4-Speed", {
		Name		= "4-Speed, Straight, Large",
		Description	= "A large sized, 4 speed straight-through gearbox.",
		Model		= "models/engines/t5large.mdl",
		Mass		= math.floor(Gear4LW * StWB),
		Switch		= 0.3,
		MaxTorque	= math.floor(Gear4LT * StTB),
		Preview = {
			FOV = 105,
		},
	})
end
