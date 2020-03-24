
-- 6-Speed gearboxes

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

-- Inline

ACF_DefineGearbox( "6Gear-L-S", {
	name = "6-Speed, Inline, Small",
	desc = "A small and light 6 speed inline gearbox, with a limited max torque rating.",
	model = "models/engines/linear_s.mdl",
	category = "6-Speed",
	weight = Gear6SW,
	switch = 0.15,
	maxtq = Gear6ST,
	gears = 6,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "6Gear-L-M", {
	name = "6-Speed, Inline, Medium",
	desc = "A medium duty 6 speed inline gearbox with a limited torque rating.",
	model = "models/engines/linear_m.mdl",
	category = "6-Speed",
	weight = Gear6MW,
	switch = 0.2,
	maxtq = Gear6MT,
	gears = 6,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "6Gear-L-L", {
	name = "6-Speed, Inline, Large",
	desc = "Heavy duty 6 speed inline gearbox, however not as resilient as a 4 speed.",
	model = "models/engines/linear_l.mdl",
	category = "6-Speed",
	weight = Gear6LW,
	switch = 0.3,
	maxtq = Gear6LT,
	gears = 6,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = -0.1,
		[ -1 ] = 1
	}
} )

-- Inline Dual Clutch

ACF_DefineGearbox( "6Gear-LD-S", {
	name = "6-Speed, Inline, Small, Dual Clutch",
	desc = "A small and light 6 speed inline gearbox, with a limited max torque rating. The dual clutch allows you to apply power and brake each side independently\n\nThe Final Drive slider is a multiplier applied to all the other gear ratios",
	model = "models/engines/linear_s.mdl",
	category = "6-Speed",
	weight = Gear6SW,
	switch = 0.15,
	maxtq = Gear6ST,
	gears = 6,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "6Gear-LD-M", {
	name = "6-Speed, Inline, Medium, Dual Clutch",
	desc = "A a medium duty 6 speed inline gearbox. The added gears reduce torque capacity substantially. The dual clutch allows you to apply power and brake each side independently\n\nThe Final Drive slider is a multiplier applied to all the other gear ratios",
	model = "models/engines/linear_m.mdl",
	category = "6-Speed",
	weight = Gear6MW,
	switch = 0.2,
	maxtq = Gear6MT,
	gears = 6,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "6Gear-LD-L", {
	name = "6-Speed, Inline, Large, Dual Clutch",
	desc = "Heavy duty 6 speed inline gearbox, however not as resilient as a 4 speed. The dual clutch allows you to apply power and brake each side independently\n\nThe Final Drive slider is a multiplier applied to all the other gear ratios",
	model = "models/engines/linear_l.mdl",
	category = "6-Speed",
	weight = Gear6LW,
	switch = 0.3,
	maxtq = Gear6LT,
	gears = 6,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = -0.1,
		[ -1 ] = 1
	}
} )

-- Transaxial

ACF_DefineGearbox( "6Gear-T-S", {
	name = "6-Speed, Transaxial, Small",
	desc = "A small and light 6 speed gearbox, with a limited max torque rating.",
	model = "models/engines/transaxial_s.mdl",
	category = "6-Speed",
	weight = Gear6SW,
	switch = 0.15,
	maxtq = Gear6ST,
	gears = 6,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "6Gear-T-M", {
	name = "6-Speed, Transaxial, Medium",
	desc = "A medium duty 6 speed gearbox with a limited torque rating.",
	model = "models/engines/transaxial_m.mdl",
	category = "6-Speed",
	weight = Gear6MW,
	switch = 0.2,
	maxtq = Gear6MT,
	gears = 6,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "6Gear-T-L", {
	name = "6-Speed, Transaxial, Large",
	desc = "Heavy duty 6 speed gearbox, however not as resilient as a 4 speed.",
	model = "models/engines/transaxial_l.mdl",
	category = "6-Speed",
	weight = Gear6LW,
	switch = 0.3,
	maxtq = Gear6LT,
	gears = 6,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = -0.1,
		[ -1 ] = 1
	}
} )

-- Transaxial Dual Clutch

ACF_DefineGearbox( "6Gear-TD-S", {
	name = "6-Speed, Transaxial, Small, Dual Clutch",
	desc = "A small and light 6 speed gearbox, with a limited max torque rating. The dual clutch allows you to apply power and brake each side independently\n\nThe Final Drive slider is a multiplier applied to all the other gear ratios",
	model = "models/engines/transaxial_s.mdl",
	category = "6-Speed",
	weight = Gear6SW,
	switch = 0.15,
	maxtq = Gear6ST,
	gears = 6,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "6Gear-TD-M", {
	name = "6-Speed, Transaxial, Medium, Dual Clutch",
	desc = "A a medium duty 6 speed gearbox. The added gears reduce torque capacity substantially. The dual clutch allows you to apply power and brake each side independently\n\nThe Final Drive slider is a multiplier applied to all the other gear ratios",
	model = "models/engines/transaxial_m.mdl",
	category = "6-Speed",
	weight = Gear6MW,
	switch = 0.2,
	maxtq = Gear6MT,
	gears = 6,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "6Gear-TD-L", {
	name = "6-Speed, Transaxial, Large, Dual Clutch",
	desc = "Heavy duty 6 speed gearbox, however not as resilient as a 4 speed. The dual clutch allows you to apply power and brake each side independently\n\nThe Final Drive slider is a multiplier applied to all the other gear ratios",
	model = "models/engines/transaxial_l.mdl",
	category = "6-Speed",
	weight = Gear6LW,
	switch = 0.3,
	maxtq = Gear6LT,
	gears = 6,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = -0.1,
		[ -1 ] = 1
	}
} )

-- Straight-through gearboxes

ACF_DefineGearbox( "6Gear-ST-S", {
	name = "6-Speed, Straight, Small",
	desc = "A small and light 6 speed straight-through gearbox.",
	model = "models/engines/t5small.mdl",
	category = "6-Speed",
	weight = math.floor(Gear6SW * StWB),
	switch = 0.15,
	maxtq = math.floor(Gear6ST * StTB),
	gears = 6,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "6Gear-ST-M", {
	name = "6-Speed, Straight, Medium",
	desc = "A medium 6 speed straight-through gearbox.",
	model = "models/engines/t5med.mdl",
	category = "6-Speed",
	weight = math.floor(Gear6MW * StWB),
	switch = 0.2,
	maxtq = math.floor(Gear6MT * StTB),
	gears = 6,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "6Gear-ST-L", {
	name = "6-Speed, Straight, Large",
	desc = "A large 6 speed straight-through gearbox.",
	model = "models/engines/t5large.mdl",
	category = "6-Speed",
	weight = math.floor(Gear6LW * StWB),
	switch = 0.3,
	maxtq = math.floor(Gear6LT * StTB),
	gears = 6,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF.RegisterGearboxClass("6-Speed", {
	Name	= "6-Speed Gearbox",
	Gears = {
		Min	= 0,
		Max	= 6,
	}
})

do -- Inline Gearboxes
	ACF.RegisterGearbox("6Gear-L-S", "6-Speed", {
		Name		= "6-Speed, Inline, Small",
		Description	= "A small and light 6 speed inline gearbox, with a limited max torque rating.",
		Model		= "models/engines/linear_s.mdl",
		Mass		= Gear6SW,
		Switch		= 0.15,
		MaxTorque	= Gear6ST,
	})

	ACF.RegisterGearbox("6Gear-L-M", "6-Speed", {
		Name		= "6-Speed, Inline, Medium",
		Description	= "A medium duty 6 speed inline gearbox with a limited torque rating.",
		Model		= "models/engines/linear_m.mdl",
		Mass		= Gear6MW,
		Switch		= 0.2,
		MaxTorque	= Gear6MT,
	})

	ACF.RegisterGearbox("6Gear-L-L", "6-Speed", {
		Name		= "6-Speed, Inline, Large",
		Description	= "Heavy duty 6 speed inline gearbox, however not as resilient as a 4 speed.",
		Model		= "models/engines/linear_l.mdl",
		Mass		= Gear6LW,
		Switch		= 0.3,
		MaxTorque	= Gear6LT,
	})
end

do -- Inline Dual Clutch Gearboxes
	ACF.RegisterGearbox("6Gear-LD-S", "6-Speed", {
		Name		= "6-Speed, Inline, Small, Dual Clutch",
		Description	= "A small and light 6 speed inline gearbox, with a limited max torque rating.",
		Model		= "models/engines/linear_s.mdl",
		Mass		= Gear6SW,
		Switch		= 0.15,
		MaxTorque	= Gear6ST,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("6Gear-LD-M", "6-Speed", {
		Name		= "6-Speed, Inline, Medium, Dual Clutch",
		Description	= "A a medium duty 6 speed inline gearbox. The added gears reduce torque capacity substantially.",
		Model		= "models/engines/linear_m.mdl",
		Mass		= Gear6MW,
		Switch		= 0.2,
		MaxTorque	= Gear6MT,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("6Gear-LD-L", "6-Speed", {
		Name		= "6-Speed, Inline, Large, Dual Clutch",
		Description	= "Heavy duty 6 speed inline gearbox, however not as resilient as a 4 speed.",
		Model		= "models/engines/linear_l.mdl",
		Mass		= Gear6LW,
		Switch		= 0.3,
		MaxTorque	= Gear6LT,
		DualClutch	= true,
	})
end

do -- Transaxial Gearboxes
	ACF.RegisterGearbox("6Gear-T-S", "6-Speed", {
		Name		= "6-Speed, Transaxial, Small",
		Description	= "A small and light 6 speed gearbox, with a limited max torque rating.",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= Gear6SW,
		Switch		= 0.15,
		MaxTorque	= Gear6ST,
	})

	ACF.RegisterGearbox("6Gear-T-M", "6-Speed", {
		Name		= "6-Speed, Transaxial, Medium",
		Description	= "A medium duty 6 speed gearbox with a limited torque rating.",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= Gear6MW,
		Switch		= 0.2,
		MaxTorque	= Gear6MT,
	})

	ACF.RegisterGearbox("6Gear-T-L", "6-Speed", {
		Name		= "6-Speed, Transaxial, Large",
		Description	= "Heavy duty 6 speed gearbox, however not as resilient as a 4 speed.",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= Gear6LW,
		Switch		= 0.3,
		MaxTorque	= Gear6LT,
	})
end

do -- Transaxial Dual Clutch
	ACF.RegisterGearbox("6Gear-TD-S", "6-Speed", {
		Name		= "6-Speed, Transaxial, Small, Dual Clutch",
		Description	= "A small and light 6 speed gearbox, with a limited max torque rating.",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= Gear6SW,
		Switch		= 0.15,
		MaxTorque	= Gear6ST,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("6Gear-TD-M", "6-Speed", {
		Name		= "6-Speed, Transaxial, Medium, Dual Clutch",
		Description	= "A a medium duty 6 speed gearbox. The added gears reduce torque capacity substantially.",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= Gear6MW,
		Switch		= 0.2,
		MaxTorque	= Gear6MT,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("6Gear-TD-L", "6-Speed", {
		Name		= "6-Speed, Transaxial, Large, Dual Clutch",
		Description	= "Heavy duty 6 speed gearbox, however not as resilient as a 4 speed.",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= Gear6LW,
		Switch		= 0.3,
		MaxTorque	= Gear6LT,
		DualClutch	= true,
	})
end

do -- Straight-through Gearboxes
	ACF.RegisterGearbox("6Gear-ST-S", "6-Speed", {
		Name		= "6-Speed, Straight, Small",
		Description	= "A small and light 6 speed straight-through gearbox.",
		Model		= "models/engines/t5small.mdl",
		Mass		= math.floor(Gear6SW * StWB),
		Switch		= 0.15,
		MaxTorque	= math.floor(Gear6ST * StTB),
	})

	ACF.RegisterGearbox("6Gear-ST-M", "6-Speed", {
		Name		= "6-Speed, Straight, Medium",
		Description	= "A medium 6 speed straight-through gearbox.",
		Model		= "models/engines/t5med.mdl",
		Mass		= math.floor(Gear6MW * StWB),
		Switch		= 0.2,
		MaxTorque	= math.floor(Gear6MT * StTB),
	})

	ACF.RegisterGearbox("6Gear-ST-L", "6-Speed", {
		Name		= "6-Speed, Straight, Large",
		Description	= "A large 6 speed straight-through gearbox.",
		Model		= "models/engines/t5large.mdl",
		Mass		= math.floor(Gear6LW * StWB),
		Switch		= 0.3,
		MaxTorque	= math.floor(Gear6LT * StTB),
	})
end
