
-- 8-Speed Gearboxes

-- Weight
local Gear8SW = 100
local Gear8MW = 200
local Gear8LW = 400
local StWB = 0.75 --straight weight bonus mulitplier

-- Torque Rating
local Gear8ST = 340
local Gear8MT = 1000
local Gear8LT = 10000
local StTB = 1.25 --straight torque bonus multiplier

-- Inline

ACF_DefineGearbox( "8Gear-L-S", {
	name = "8-Speed, Inline, Small",
	desc = "A small and light 8 speed gearbox.",
	model = "models/engines/linear_s.mdl",
	category = "8-Speed",
	weight = Gear8SW,
	switch = 0.15,
	maxtq = Gear8ST,
	gears = 8,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ 8 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "8Gear-L-M", {
	name = "8-Speed, Inline, Medium",
	desc = "A medium duty 8 speed gearbox..",
	model = "models/engines/linear_m.mdl",
	category = "8-Speed",
	weight = Gear8MW,
	switch = 0.2,
	maxtq = Gear8MT,
	gears = 8,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ 8 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "8Gear-L-L", {
	name = "8-Speed, Inline, Large",
	desc = "Heavy duty 8 speed gearbox, however rather heavy.",
	model = "models/engines/linear_l.mdl",
	category = "8-Speed",
	weight = Gear8LW,
	switch = 0.3,
	maxtq = Gear8LT,
	gears = 8,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ 8 ] = -0.1,
		[ -1 ] = 1
	}
} )

-- Inline Dual Clutch

ACF_DefineGearbox( "8Gear-LD-S", {
	name = "8-Speed, Inline, Small, Dual Clutch",
	desc = "A small and light 8 speed gearbox The dual clutch allows you to apply power and brake each side independently\n\nThe Final Drive slider is a multiplier applied to all the other gear ratios",
	model = "models/engines/linear_s.mdl",
	category = "8-Speed",
	weight = Gear8SW,
	switch = 0.15,
	maxtq = Gear8ST,
	gears = 8,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ 8 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "8Gear-LD-M", {
	name = "8-Speed, Inline, Medium, Dual Clutch",
	desc = "A a medium duty 8 speed gearbox. The dual clutch allows you to apply power and brake each side independently\n\nThe Final Drive slider is a multiplier applied to all the other gear ratios",
	model = "models/engines/linear_m.mdl",
	category = "8-Speed",
	weight = Gear8MW,
	switch = 0.2,
	maxtq = Gear8MT,
	gears = 8,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ 8 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "8Gear-LD-L", {
	name = "8-Speed, Inline, Large, Dual Clutch",
	desc = "Heavy duty 8 speed gearbox. The dual clutch allows you to apply power and brake each side independently\n\nThe Final Drive slider is a multiplier applied to all the other gear ratios",
	model = "models/engines/linear_l.mdl",
	category = "8-Speed",
	weight = Gear8LW,
	switch = 0.3,
	maxtq = Gear8LT,
	gears = 8,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ 8 ] = -0.1,
		[ -1 ] = 1
	}
} )

-- Transaxial

ACF_DefineGearbox( "8Gear-T-S", {
	name = "8-Speed, Transaxial, Small",
	desc = "A small and light 8 speed gearbox..",
	model = "models/engines/transaxial_s.mdl",
	category = "8-Speed",
	weight = Gear8SW,
	switch = 0.15,
	maxtq = Gear8ST,
	gears = 8,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ 8 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "8Gear-T-M", {
	name = "8-Speed, Transaxial, Medium",
	desc = "A medium duty 8 speed gearbox..",
	model = "models/engines/transaxial_m.mdl",
	category = "8-Speed",
	weight = Gear8MW,
	switch = 0.2,
	maxtq = Gear8MT,
	gears = 8,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ 8 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "8Gear-T-L", {
	name = "8-Speed, Transaxial, Large",
	desc = "Heavy duty 8 speed gearbox, however rather heavy.",
	model = "models/engines/transaxial_l.mdl",
	category = "8-Speed",
	weight = Gear8LW,
	switch = 0.3,
	maxtq = Gear8LT,
	gears = 8,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ 8 ] = -0.1,
		[ -1 ] = 1
	}
} )

-- Transaxial Dual Clutch

ACF_DefineGearbox( "8Gear-TD-S", {
	name = "8-Speed, Transaxial, Small, Dual Clutch",
	desc = "A small and light 8 speed gearbox The dual clutch allows you to apply power and brake each side independently\n\nThe Final Drive slider is a multiplier applied to all the other gear ratios",
	model = "models/engines/transaxial_s.mdl",
	category = "8-Speed",
	weight = Gear8SW,
	switch = 0.15,
	maxtq = Gear8ST,
	gears = 8,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ 8 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "8Gear-TD-M", {
	name = "8-Speed, Transaxial, Medium, Dual Clutch",
	desc = "A a medium duty 8 speed gearbox. The dual clutch allows you to apply power and brake each side independently\n\nThe Final Drive slider is a multiplier applied to all the other gear ratios",
	model = "models/engines/transaxial_m.mdl",
	category = "8-Speed",
	weight = Gear8MW,
	switch = 0.2,
	maxtq = Gear8MT,
	gears = 8,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ 8 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "8Gear-TD-L", {
	name = "8-Speed, Transaxial, Large, Dual Clutch",
	desc = "Heavy duty 8 speed gearbox. The dual clutch allows you to apply power and brake each side independently\n\nThe Final Drive slider is a multiplier applied to all the other gear ratios",
	model = "models/engines/transaxial_l.mdl",
	category = "8-Speed",
	weight = Gear8LW,
	switch = 0.3,
	maxtq = Gear8LT,
	gears = 8,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ 8 ] = -0.1,
		[ -1 ] = 1
	}
} )

-- Straight-through gearboxes

ACF_DefineGearbox( "8Gear-ST-S", {
	name = "8-Speed, Straight, Small",
	desc = "A small and light 8 speed straight-through gearbox.",
	model = "models/engines/t5small.mdl",
	category = "8-Speed",
	weight = math.floor(Gear8SW * StWB),
	switch = 0.15,
	maxtq = math.floor(Gear8ST * StTB),
	gears = 8,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ 8 ] = 0.8,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "8Gear-ST-M", {
	name = "8-Speed, Straight, Medium",
	desc = "A medium 8 speed straight-through gearbox.",
	model = "models/engines/t5med.mdl",
	category = "8-Speed",
	weight = math.floor(Gear8MW * StWB),
	switch = 0.2,
	maxtq = math.floor(Gear8MT * StTB),
	gears = 8,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ 8 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "8Gear-ST-L", {
	name = "8-Speed, Straight, Large",
	desc = "A large 8 speed straight-through gearbox.",
	model = "models/engines/t5large.mdl",
	category = "8-Speed",
	weight = math.floor(Gear8LW * StWB),
	switch = 0.3,
	maxtq = math.floor(Gear8LT * StTB),
	gears = 8,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ 8 ] = -0.1,
		[ -1 ] = 0.5
	}
} )
