local ACF       = ACF
local Gearboxes = ACF.Classes.Gearboxes

-- Weight
local Gear6SW = 80
local Gear6MW = 160
local Gear6LW = 320
local StWB = 0.75 --straight weight bonus mulitplier

-- Torque Rating
local Gear6ST = 440
local Gear6MT = 1360
local Gear6LT = 10000
local StTB = 1.25 --straight torque bonus multiplier

Gearboxes.Register("6-Speed", {
	Name		= "6-Speed Gearbox",
	CreateMenu	= ACF.ManualGearboxMenu,
	Gears = {
		Min	= 0,
		Max	= 6,
	}
})

do -- Inline Gearboxes
	Gearboxes.RegisterItem("6Gear-L-S", "6-Speed", {
		Name		= "6-Speed, Inline, Small",
		Description	= "A small and light 6 speed inline gearbox, with a limited max torque rating.",
		Model		= "models/engines/linear_s.mdl",
		Mass		= Gear6SW,
		Switch		= 0.15,
		MaxTorque	= Gear6ST,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("6Gear-L-M", "6-Speed", {
		Name		= "6-Speed, Inline, Medium",
		Description	= "A medium duty 6 speed inline gearbox with a limited torque rating.",
		Model		= "models/engines/linear_m.mdl",
		Mass		= Gear6MW,
		Switch		= 0.2,
		MaxTorque	= Gear6MT,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("6Gear-L-L", "6-Speed", {
		Name		= "6-Speed, Inline, Large",
		Description	= "Heavy duty 6 speed inline gearbox, however not as resilient as a 4 speed.",
		Model		= "models/engines/linear_l.mdl",
		Mass		= Gear6LW,
		Switch		= 0.3,
		MaxTorque	= Gear6LT,
		Preview = {
			FOV = 125,
		},
	})
end

do -- Inline Dual Clutch Gearboxes
	Gearboxes.RegisterItem("6Gear-LD-S", "6-Speed", {
		Name		= "6-Speed, Inline, Small, Dual Clutch",
		Description	= "A small and light 6 speed inline gearbox, with a limited max torque rating.",
		Model		= "models/engines/linear_s.mdl",
		Mass		= Gear6SW,
		Switch		= 0.15,
		MaxTorque	= Gear6ST,
		DualClutch	= true,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("6Gear-LD-M", "6-Speed", {
		Name		= "6-Speed, Inline, Medium, Dual Clutch",
		Description	= "A a medium duty 6 speed inline gearbox. The added gears reduce torque capacity substantially.",
		Model		= "models/engines/linear_m.mdl",
		Mass		= Gear6MW,
		Switch		= 0.2,
		MaxTorque	= Gear6MT,
		DualClutch	= true,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("6Gear-LD-L", "6-Speed", {
		Name		= "6-Speed, Inline, Large, Dual Clutch",
		Description	= "Heavy duty 6 speed inline gearbox, however not as resilient as a 4 speed.",
		Model		= "models/engines/linear_l.mdl",
		Mass		= Gear6LW,
		Switch		= 0.3,
		MaxTorque	= Gear6LT,
		DualClutch	= true,
		Preview = {
			FOV = 125,
		},
	})
end

do -- Transaxial Gearboxes
	Gearboxes.RegisterItem("6Gear-T-S", "6-Speed", {
		Name		= "6-Speed, Transaxial, Small",
		Description	= "A small and light 6 speed gearbox, with a limited max torque rating.",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= Gear6SW,
		Switch		= 0.15,
		MaxTorque	= Gear6ST,
		Preview = {
			FOV = 85,
		},
	})

	Gearboxes.RegisterItem("6Gear-T-M", "6-Speed", {
		Name		= "6-Speed, Transaxial, Medium",
		Description	= "A medium duty 6 speed gearbox with a limited torque rating.",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= Gear6MW,
		Switch		= 0.2,
		MaxTorque	= Gear6MT,
		Preview = {
			FOV = 85,
		},
	})

	Gearboxes.RegisterItem("6Gear-T-L", "6-Speed", {
		Name		= "6-Speed, Transaxial, Large",
		Description	= "Heavy duty 6 speed gearbox, however not as resilient as a 4 speed.",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= Gear6LW,
		Switch		= 0.3,
		MaxTorque	= Gear6LT,
		Preview = {
			FOV = 85,
		},
	})
end

do -- Transaxial Dual Clutch
	Gearboxes.RegisterItem("6Gear-TD-S", "6-Speed", {
		Name		= "6-Speed, Transaxial, Small, Dual Clutch",
		Description	= "A small and light 6 speed gearbox, with a limited max torque rating.",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= Gear6SW,
		Switch		= 0.15,
		MaxTorque	= Gear6ST,
		DualClutch	= true,
		Preview = {
			FOV = 85,
		},
	})

	Gearboxes.RegisterItem("6Gear-TD-M", "6-Speed", {
		Name		= "6-Speed, Transaxial, Medium, Dual Clutch",
		Description	= "A a medium duty 6 speed gearbox. The added gears reduce torque capacity substantially.",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= Gear6MW,
		Switch		= 0.2,
		MaxTorque	= Gear6MT,
		DualClutch	= true,
		Preview = {
			FOV = 85,
		},
	})

	Gearboxes.RegisterItem("6Gear-TD-L", "6-Speed", {
		Name		= "6-Speed, Transaxial, Large, Dual Clutch",
		Description	= "Heavy duty 6 speed gearbox, however not as resilient as a 4 speed.",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= Gear6LW,
		Switch		= 0.3,
		MaxTorque	= Gear6LT,
		DualClutch	= true,
		Preview = {
			FOV = 85,
		},
	})
end

do -- Straight-through Gearboxes
	Gearboxes.RegisterItem("6Gear-ST-S", "6-Speed", {
		Name		= "6-Speed, Straight, Small",
		Description	= "A small and light 6 speed straight-through gearbox.",
		Model		= "models/engines/t5small.mdl",
		Mass		= math.floor(Gear6SW * StWB),
		Switch		= 0.15,
		MaxTorque	= math.floor(Gear6ST * StTB),
		Preview = {
			FOV = 105,
		},
	})

	Gearboxes.RegisterItem("6Gear-ST-M", "6-Speed", {
		Name		= "6-Speed, Straight, Medium",
		Description	= "A medium 6 speed straight-through gearbox.",
		Model		= "models/engines/t5med.mdl",
		Mass		= math.floor(Gear6MW * StWB),
		Switch		= 0.2,
		MaxTorque	= math.floor(Gear6MT * StTB),
		Preview = {
			FOV = 105,
		},
	})

	Gearboxes.RegisterItem("6Gear-ST-L", "6-Speed", {
		Name		= "6-Speed, Straight, Large",
		Description	= "A large 6 speed straight-through gearbox.",
		Model		= "models/engines/t5large.mdl",
		Mass		= math.floor(Gear6LW * StWB),
		Switch		= 0.3,
		MaxTorque	= math.floor(Gear6LT * StTB),
		Preview = {
			FOV = 105,
		},
	})
end
