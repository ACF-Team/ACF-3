
-- 4-Speed gearboxes

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

-- Inline

ACF_DefineGearbox( "4Gear-L-S", {
	name = "4-Speed, Inline, Small",
	desc = "A small, and light 4 speed inline gearbox, with a somewhat limited max torque rating\n\nThe Final Drive slider is a multiplier applied to all the other gear ratios",
	model = "models/engines/linear_s.mdl",
	category = "4-Speed",
	weight = Gear4SW,
	switch = 0.15,
	maxtq = Gear4ST,
	gears = 4,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "4Gear-L-M", {
	name = "4-Speed, Inline, Medium",
	desc = "A medium sized, 4 speed inline gearbox",
	model = "models/engines/linear_m.mdl",
	category = "4-Speed",
	weight = Gear4MW,
	switch = 0.2,
	maxtq = Gear4MT,
	gears = 4,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "4Gear-L-L", {
	name = "4-Speed, Inline, Large",
	desc = "A large, heavy and sturdy 4 speed inline gearbox",
	model = "models/engines/linear_l.mdl",
	category = "4-Speed",
	weight = Gear4LW,
	switch = 0.3,
	maxtq = Gear4LT,
	gears = 4,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = -0.1,
		[ -1 ] = 1
	}
} )

-- Inline Dual Clutch

ACF_DefineGearbox( "4Gear-LD-S", {
	name = "4-Speed, Inline, Small, Dual Clutch",
	desc = "A small, and light 4 speed inline gearbox, with a somewhat limited max torque rating. The dual clutch allows you to apply power and brake each side independently\n\nThe Final Drive slider is a multiplier applied to all the other gear ratios",
	model = "models/engines/linear_s.mdl",
	category = "4-Speed",
	weight = Gear4SW,
	switch = 0.15,
	maxtq = Gear4ST,
	gears = 4,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "4Gear-LD-M", {
	name = "4-Speed, Inline, Medium, Dual Clutch",
	desc = "A medium sized, 4 speed inline gearbox. The dual clutch allows you to apply power and brake each side independently",
	model = "models/engines/linear_m.mdl",
	category = "4-Speed",
	weight = Gear4MW,
	switch = 0.2,
	maxtq = Gear4MT,
	gears = 4,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "4Gear-LD-L", {
	name = "4-Speed, Inline, Large, Dual Clutch",
	desc = "A large, heavy and sturdy 4 speed inline gearbox. The dual clutch allows you to apply power and brake each side independently",
	model = "models/engines/linear_l.mdl",
	category = "4-Speed",
	weight = Gear4LW,
	switch = 0.3,
	maxtq = Gear4LT,
	gears = 4,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = -0.1,
		[ -1 ] = 1
	}
} )

-- Transaxial

ACF_DefineGearbox( "4Gear-T-S", {
	name = "4-Speed, Transaxial, Small",
	desc = "A small, and light 4 speed gearbox, with a somewhat limited max torque rating\n\nThe Final Drive slider is a multiplier applied to all the other gear ratios",
	model = "models/engines/transaxial_s.mdl",
	category = "4-Speed",
	weight = Gear4SW,
	switch = 0.15,
	maxtq = Gear4ST,
	gears = 4,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "4Gear-T-M", {
	name = "4-Speed, Transaxial, Medium",
	desc = "A medium sized, 4 speed gearbox",
	model = "models/engines/transaxial_m.mdl",
	category = "4-Speed",
	weight = Gear4MW,
	switch = 0.2,
	maxtq = Gear4MT,
	gears = 4,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "4Gear-T-L", {
	name = "4-Speed, Transaxial, Large",
	desc = "A large, heavy and sturdy 4 speed gearbox",
	model = "models/engines/transaxial_l.mdl",
	category = "4-Speed",
	weight = Gear4LW,
	switch = 0.3,
	maxtq = Gear4LT,
	gears = 4,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = -0.1,
		[ -1 ] = 1
	}
} )

-- Transaxial Dual Clutch

ACF_DefineGearbox( "4Gear-TD-S", {
	name = "4-Speed, Transaxial, Small, Dual Clutch",
	desc = "A small, and light 4 speed gearbox, with a somewhat limited max torque rating. The dual clutch allows you to apply power and brake each side independently\n\nThe Final Drive slider is a multiplier applied to all the other gear ratios",
	model = "models/engines/transaxial_s.mdl",
	category = "4-Speed",
	weight = Gear4SW,
	switch = 0.15,
	maxtq = Gear4ST,
	gears = 4,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "4Gear-TD-M", {
	name = "4-Speed, Transaxial, Medium, Dual Clutch",
	desc = "A medium sized, 4 speed gearbox. The dual clutch allows you to apply power and brake each side independently",
	model = "models/engines/transaxial_m.mdl",
	category = "4-Speed",
	weight = Gear4MW,
	switch = 0.2,
	maxtq = Gear4MT,
	gears = 4,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "4Gear-TD-L", {
	name = "4-Speed, Transaxial, Large, Dual Clutch",
	desc = "A large, heavy and sturdy 4 speed gearbox. The dual clutch allows you to apply power and brake each side independently",
	model = "models/engines/transaxial_l.mdl",
	category = "4-Speed",
	weight = Gear4LW,
	switch = 0.3,
	maxtq = Gear4LT,
	gears = 4,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = -0.1,
		[ -1 ] = 1
	}
} )

-- Straight-through gearboxes

ACF_DefineGearbox( "4Gear-ST-S", {
	name = "4-Speed, Straight, Small",
	desc = "A small straight-through gearbox",
	model = "models/engines/t5small.mdl",
	category = "4-Speed",
	weight = math.floor(Gear4SW * StWB),
	switch = 0.15,
	maxtq = math.floor(Gear4ST * StTB),
	gears = 4,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = -0.1,
		[ -1 ] = 1
	}
} )

ACF_DefineGearbox( "4Gear-ST-M", {
	name = "4-Speed, Straight, Medium",
	desc = "A medium sized, 4 speed straight-through gearbox.",
	model = "models/engines/t5med.mdl",
	category = "4-Speed",
	weight = math.floor(Gear4MW * StWB),
	switch = 0.2,
	maxtq = math.floor(Gear4MT * StTB),
	gears = 4,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "4Gear-ST-L", {
	name = "4-Speed, Straight, Large",
	desc = "A large sized, 4 speed straight-through gearbox.",
	model = "models/engines/t5large.mdl",
	category = "4-Speed",
	weight = math.floor(Gear4LW * StWB),
	switch = 0.3,
	maxtq = math.floor(Gear4LT * StTB),
	gears = 4,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

--  The dual clutch allows you to apply power and brake each side independently

ACF.RegisterGearboxClass("4-Speed", {
	Name	= "4-Speed Gearbox",
	Gears = {
		Min	= 0,
		Max	= 4,
	}
})

do -- Inline Gearboxes
	ACF.RegisterGearbox("4Gear-L-S", "4-Speed", "4-Speed", {
		Name		= "4-Speed, Inline, Small",
		Description	= "A small, and light 4 speed inline gearbox, with a somewhat limited max torque rating.",
		Model		= "models/engines/linear_s.mdl",
		Mass		= Gear4SW,
		Switch		= 0.15,
		MaxTorque	= Gear4ST,
	})

	ACF.RegisterGearbox("4Gear-L-M", "4-Speed", {
		Name		= "4-Speed, Inline, Medium",
		Description	= "A medium sized, 4 speed inline gearbox.",
		Model		= "models/engines/linear_m.mdl",
		Mass		= Gear4MW,
		Switch		= 0.2,
		MaxTorque	= Gear4MT,
	})

	ACF.RegisterGearbox("4Gear-L-L", "4-Speed", {
		Name		= "4-Speed, Inline, Large",
		Description	= "A large, heavy and sturdy 4 speed inline gearbox.",
		Model		= "models/engines/linear_l.mdl",
		Mass		= Gear4LW,
		Switch		= 0.3,
		MaxTorque	= Gear4LT,
	})
end

do -- Inline Dual Clutch Gearboxes
	ACF.RegisterGearbox("4Gear-LD-S", "4-Speed", {
		Name		= "4-Speed, Inline, Small, Dual Clutch",
		Description	= "A small, and light 4 speed inline gearbox, with a somewhat limited max torque rating.",
		Model		= "models/engines/linear_s.mdl",
		Mass		= Gear4SW,
		Switch		= 0.15,
		MaxTorque	= Gear4ST,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("4Gear-LD-M", "4-Speed", {
		Name		= "4-Speed, Inline, Medium, Dual Clutch",
		Description	= "A medium sized, 4 speed inline gearbox.",
		Model		= "models/engines/linear_m.mdl",
		Mass		= Gear4MW,
		Switch		= 0.2,
		MaxTorque	= Gear4MT,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("4Gear-LD-L", "4-Speed", {
		Name		= "4-Speed, Inline, Large, Dual Clutch",
		Description	= "A large, heavy and sturdy 4 speed inline gearbox.",
		Model		= "models/engines/linear_l.mdl",
		Mass		= Gear4LW,
		Switch		= 0.3,
		MaxTorque	= Gear4LT,
		DualClutch	= true,
	})
end

do -- Transaxial Gearboxes
	ACF.RegisterGearbox("4Gear-T-S", "4-Speed", {
		Name		= "4-Speed, Transaxial, Small",
		Description	= "A small, and light 4 speed gearbox, with a somewhat limited max torque rating.",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= Gear4SW,
		Switch		= 0.15,
		MaxTorque	= Gear4ST,
	})

	ACF.RegisterGearbox("4Gear-T-M", "4-Speed", {
		Name		= "4-Speed, Transaxial, Medium",
		Description	= "A medium sized, 4 speed gearbox.",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= Gear4MW,
		Switch		= 0.2,
		MaxTorque	= Gear4MT,
	})

	ACF.RegisterGearbox("4Gear-T-L", "4-Speed", {
		Name		= "4-Speed, Transaxial, Large",
		Description	= "A large, heavy and sturdy 4 speed gearbox.",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= Gear4LW,
		Switch		= 0.3,
		MaxTorque	= Gear4LT,
	})
end

do -- Transaxial Dual Clutch Gearboxes
	ACF.RegisterGearbox("4Gear-TD-S", "4-Speed", {
		Name		= "4-Speed, Transaxial, Small, Dual Clutch",
		Description	= "A small, and light 4 speed gearbox, with a somewhat limited max torque rating.",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= Gear4SW,
		Switch		= 0.15,
		MaxTorque	= Gear4ST,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("4Gear-TD-M", "4-Speed", {
		Name		= "4-Speed, Transaxial, Medium, Dual Clutch",
		Description	= "A medium sized, 4 speed gearbox.",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= Gear4MW,
		Switch		= 0.2,
		MaxTorque	= Gear4MT,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("4Gear-TD-L", "4-Speed", {
		Name		= "4-Speed, Transaxial, Large, Dual Clutch",
		Description	= "A large, heavy and sturdy 4 speed gearbox.",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= Gear4LW,
		Switch		= 0.3,
		MaxTorque	= Gear4LT,
		DualClutch	= true,
	})
end

do -- Straight-through Gearboxes
	ACF.RegisterGearbox("4Gear-ST-S", "4-Speed", {
		Name		= "4-Speed, Straight, Small",
		Description	= "A small straight-through gearbox.",
		Model		= "models/engines/t5small.mdl",
		Mass		= math.floor(Gear4SW * StWB),
		Switch		= 0.15,
		MaxTorque	= math.floor(Gear4ST * StTB),
	})

	ACF.RegisterGearbox("4Gear-ST-M", "4-Speed", {
		Name		= "4-Speed, Straight, Medium",
		Description	= "A medium sized, 4 speed straight-through gearbox.",
		Model		= "models/engines/t5med.mdl",
		Mass		= math.floor(Gear4MW * StWB),
		Switch		= 0.2,
		MaxTorque	= math.floor(Gear4MT * StTB),
	})

	ACF.RegisterGearbox("4Gear-ST-L", "4-Speed", {
		Name		= "4-Speed, Straight, Large",
		Description	= "A large sized, 4 speed straight-through gearbox.",
		Model		= "models/engines/t5large.mdl",
		Mass		= math.floor(Gear4LW * StWB),
		Switch		= 0.3,
		MaxTorque	= math.floor(Gear4LT * StTB),
	})
end
