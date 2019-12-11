
-- Automatic Gearboxes

-- Weight
local wmul = 1.5
local Gear3SW = 60 * wmul
local Gear3MW = 120 * wmul
local Gear3LW = 240 * wmul

local Gear5SW = 80 * wmul
local Gear5MW = 160 * wmul
local Gear5LW = 320 * wmul

local Gear7SW = 100 * wmul
local Gear7MW = 200 * wmul
local Gear7LW = 400 * wmul

-- Torque Rating
local Gear3ST = 675
local Gear3MT = 2125
local Gear3LT = 10000

local Gear5ST = 550
local Gear5MT = 1700
local Gear5LT = 10000

local Gear7ST = 425
local Gear7MT = 1250
local Gear7LT = 10000

-- Straight through bonuses
local StWB = 0.75 --straight weight bonus mulitplier
local StTB = 1.25 --straight torque bonus multiplier

-- Shift Time
local ShiftS = 0.25
local ShiftM = 0.35
local ShiftL = 0.5

local blurb = "\n\nAutomatics are controlled by shifting into either forward or reverse drive. In forward drive, the automatic will choose the appropriate gearing based the upshift speed setting for each gear."
blurb = blurb .. " For climbing inclines, automatics have an input to prevent upshifts. There's also an input for adjusting the shiftpoints, if for example you're driving with less throttle and want to shift earlier."
blurb = blurb .. " However, automatics are significantly heavier than their manual counterparts, and lose a bit of output torque due to inefficiency."
--hold gear, shift scale, less efficient
-- 3 Speed
-- Inline

ACF_DefineGearbox( "3Gear-A-L-S", {
	name = "3-Speed Auto, Inline, Small",
	desc = "A small, and light 3 speed automatic inline gearbox, with a somewhat limited max torque rating"..blurb,
	model = "models/engines/linear_s.mdl",
	category = "Automatic",
	weight = Gear3SW,
	switch = ShiftS,
	maxtq = Gear3ST,
	auto = true,
	gears = 3,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ -2 ] = -0.1, --reverse
		[ -1 ] = 0.5 --final drive
	}
} )

ACF_DefineGearbox( "3Gear-A-L-M", {
	name = "3-Speed Auto, Inline, Medium",
	desc = "A medium sized, 3 speed automatic inline gearbox"..blurb,
	model = "models/engines/linear_m.mdl",
	category = "Automatic",
	weight = Gear3MW,
	switch = ShiftM,
	maxtq = Gear3MT,
	auto = true,
	gears = 3,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "3Gear-A-L-L", {
	name = "3-Speed Auto, Inline, Large",
	desc = "A large, heavy and sturdy 3 speed inline gearbox"..blurb,
	model = "models/engines/linear_l.mdl",
	category = "Automatic",
	weight = Gear3LW,
	switch = ShiftL,
	maxtq = Gear3LT,
	auto = true,
	gears = 3,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ -2 ] = -0.1,
		[ -1 ] = 1
	}
} )

-- Inline Dual Clutch

ACF_DefineGearbox( "3Gear-A-LD-S", {
	name = "3-Speed Auto, Inline, Small, Dual Clutch",
	desc = "A small, and light 3 speed automatic inline gearbox, with a somewhat limited max torque rating"..blurb,
	model = "models/engines/linear_s.mdl",
	category = "Automatic",
	weight = Gear3SW,
	switch = ShiftS,
	maxtq = Gear3ST,
	auto = true,
	doubleclutch = true,
	gears = 3,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "3Gear-A-LD-M", {
	name = "3-Speed Auto, Inline, Medium, Dual Clutch",
	desc = "A medium sized, 3 speed automatic inline gearbox"..blurb,
	model = "models/engines/linear_m.mdl",
	category = "Automatic",
	weight = Gear3MW,
	switch = ShiftM,
	maxtq = Gear3MT,
	auto = true,
	doubleclutch = true,
	gears = 3,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "3Gear-A-LD-L", {
	name = "3-Speed Auto, Inline, Large, Dual Clutch",
	desc = "A large, heavy and sturdy 3 speed automatic inline gearbox"..blurb,
	model = "models/engines/linear_l.mdl",
	category = "Automatic",
	weight = Gear3LW,
	switch = ShiftL,
	maxtq = Gear3LT,
	auto = true,
	doubleclutch = true,
	gears = 3,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ -2 ] = -0.1,
		[ -1 ] = 1
	}
} )

-- Transaxial

ACF_DefineGearbox( "3Gear-A-T-S", {
	name = "3-Speed Auto, Transaxial, Small",
	desc = "A small, and light 3 speed automatic gearbox, with a somewhat limited max torque rating"..blurb,
	model = "models/engines/transaxial_s.mdl",
	category = "Automatic",
	weight = Gear3SW,
	switch = ShiftS,
	maxtq = Gear3ST,
	auto = true,
	gears = 3,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "3Gear-A-T-M", {
	name = "3-Speed Auto, Transaxial, Medium",
	desc = "A medium sized, 3 speed automatic gearbox"..blurb,
	model = "models/engines/transaxial_m.mdl",
	category = "Automatic",
	weight = Gear3MW,
	switch = ShiftM,
	maxtq = Gear3MT,
	auto = true,
	gears = 3,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "3Gear-A-T-L", {
	name = "3-Speed Auto, Transaxial, Large",
	desc = "A large, heavy and sturdy 3 speed automatic gearbox"..blurb,
	model = "models/engines/transaxial_l.mdl",
	category = "Automatic",
	weight = Gear3LW,
	switch = ShiftL,
	maxtq = Gear3LT,
	auto = true,
	gears = 3,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ -2 ] = -0.1,
		[ -1 ] = 1
	}
} )

-- Transaxial Dual Clutch

ACF_DefineGearbox( "3Gear-A-TD-S", {
	name = "3-Speed Auto, Transaxial, Small, Dual Clutch",
	desc = "A small, and light 3 speed automatic gearbox, with a somewhat limited max torque rating"..blurb,
	model = "models/engines/transaxial_s.mdl",
	category = "Automatic",
	weight = Gear3SW,
	switch = ShiftS,
	maxtq = Gear3ST,
	auto = true,
	doubleclutch = true,
	gears = 3,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "3Gear-A-TD-M", {
	name = "3-Speed Auto, Transaxial, Medium, Dual Clutch",
	desc = "A medium sized, 3 speed automatic gearbox"..blurb,
	model = "models/engines/transaxial_m.mdl",
	category = "Automatic",
	weight = Gear3MW,
	switch = ShiftM,
	maxtq = Gear3MT,
	auto = true,
	doubleclutch = true,
	gears = 3,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "3Gear-A-TD-L", {
	name = "3-Speed Auto, Transaxial, Large, Dual Clutch",
	desc = "A large, heavy and sturdy 3 speed automatic gearbox"..blurb,
	model = "models/engines/transaxial_l.mdl",
	category = "Automatic",
	weight = Gear3LW,
	switch = ShiftL,
	maxtq = Gear3LT,
	auto = true,
	doubleclutch = true,
	gears = 3,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ -2 ] = -0.1,
		[ -1 ] = 1
	}
} )

-- Straight-through gearboxes

ACF_DefineGearbox( "3Gear-A-ST-S", {
	name = "3-Speed Auto, Straight, Small",
	desc = "A small straight-through automatic gearbox"..blurb,
	model = "models/engines/t5small.mdl",
	category = "Automatic",
	weight = math.floor(Gear3SW * StWB),
	switch = ShiftS,
	maxtq = math.floor(Gear3ST * StTB),
	auto = true,
	gears = 3,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ -2 ] = -0.1,
		[ -1 ] = 1
	}
} )

ACF_DefineGearbox( "3Gear-A-ST-M", {
	name = "3-Speed Auto, Straight, Medium",
	desc = "A medium sized, 3 speed automatic straight-through gearbox."..blurb,
	model = "models/engines/t5med.mdl",
	category = "Automatic",
	weight = math.floor(Gear3MW * StWB),
	switch = ShiftM,
	maxtq = math.floor(Gear3MT * StTB),
	auto = true,
	gears = 3,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "3Gear-A-ST-L", {
	name = "3-Speed Auto, Straight, Large",
	desc = "A large sized, 3 speed automatic straight-through gearbox."..blurb,
	model = "models/engines/t5large.mdl",
	category = "Automatic",
	weight = math.floor(Gear3LW * StWB),
	switch = ShiftL,
	maxtq = math.floor(Gear3LT * StTB),
	auto = true,
	gears = 3,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )


-- 5 Speed
-- Inline

ACF_DefineGearbox( "5Gear-A-L-S", {
	name = "5-Speed Auto, Inline, Small",
	desc = "A small, and light 5 speed automatic inline gearbox, with a somewhat limited max torque rating"..blurb,
	model = "models/engines/linear_s.mdl",
	category = "Automatic",
	weight = Gear5SW,
	switch = ShiftS,
	maxtq = Gear5ST,
	auto = true,
	gears = 5,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "5Gear-A-L-M", {
	name = "5-Speed Auto, Inline, Medium",
	desc = "A medium sized, 5 speed automatic inline gearbox"..blurb,
	model = "models/engines/linear_m.mdl",
	category = "Automatic",
	weight = Gear5MW,
	switch = ShiftM,
	maxtq = Gear5MT,
	auto = true,
	gears = 5,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "5Gear-A-L-L", {
	name = "5-Speed Auto, Inline, Large",
	desc = "A large, heavy and sturdy 5 speed inline gearbox"..blurb,
	model = "models/engines/linear_l.mdl",
	category = "Automatic",
	weight = Gear5LW,
	switch = ShiftL,
	maxtq = Gear5LT,
	auto = true,
	gears = 5,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

-- Inline Dual Clutch

ACF_DefineGearbox( "5Gear-A-LD-S", {
	name = "5-Speed Auto, Inline, Small, Dual Clutch",
	desc = "A small, and light 5 speed automatic inline gearbox, with a somewhat limited max torque rating"..blurb,
	model = "models/engines/linear_s.mdl",
	category = "Automatic",
	weight = Gear5SW,
	switch = ShiftS,
	maxtq = Gear5ST,
	auto = true,
	doubleclutch = true,
	gears = 5,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "5Gear-A-LD-M", {
	name = "5-Speed Auto, Inline, Medium, Dual Clutch",
	desc = "A medium sized, 5 speed automatic inline gearbox"..blurb,
	model = "models/engines/linear_m.mdl",
	category = "Automatic",
	weight = Gear5MW,
	switch = ShiftM,
	maxtq = Gear5MT,
	auto = true,
	doubleclutch = true,
	gears = 5,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "5Gear-A-LD-L", {
	name = "5-Speed Auto, Inline, Large, Dual Clutch",
	desc = "A large, heavy and sturdy 5 speed automatic inline gearbox"..blurb,
	model = "models/engines/linear_l.mdl",
	category = "Automatic",
	weight = Gear5LW,
	switch = ShiftL,
	maxtq = Gear5LT,
	auto = true,
	doubleclutch = true,
	gears = 5,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

-- Transaxial

ACF_DefineGearbox( "5Gear-A-T-S", {
	name = "5-Speed Auto, Transaxial, Small",
	desc = "A small, and light 5 speed automatic gearbox, with a somewhat limited max torque rating"..blurb,
	model = "models/engines/transaxial_s.mdl",
	category = "Automatic",
	weight = Gear5SW,
	switch = ShiftS,
	maxtq = Gear5ST,
	auto = true,
	gears = 5,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "5Gear-A-T-M", {
	name = "5-Speed Auto, Transaxial, Medium",
	desc = "A medium sized, 5 speed automatic gearbox"..blurb,
	model = "models/engines/transaxial_m.mdl",
	category = "Automatic",
	weight = Gear5MW,
	switch = ShiftM,
	maxtq = Gear5MT,
	auto = true,
	gears = 5,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "5Gear-A-T-L", {
	name = "5-Speed Auto, Transaxial, Large",
	desc = "A large, heavy and sturdy 5 speed automatic gearbox"..blurb,
	model = "models/engines/transaxial_l.mdl",
	category = "Automatic",
	weight = Gear5LW,
	switch = ShiftL,
	maxtq = Gear5LT,
	auto = true,
	gears = 5,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

-- Transaxial Dual Clutch

ACF_DefineGearbox( "5Gear-A-TD-S", {
	name = "5-Speed Auto, Transaxial, Small, Dual Clutch",
	desc = "A small, and light 5 speed automatic gearbox, with a somewhat limited max torque rating"..blurb,
	model = "models/engines/transaxial_s.mdl",
	category = "Automatic",
	weight = Gear5SW,
	switch = ShiftS,
	maxtq = Gear5ST,
	auto = true,
	doubleclutch = true,
	gears = 5,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "5Gear-A-TD-M", {
	name = "5-Speed Auto, Transaxial, Medium, Dual Clutch",
	desc = "A medium sized, 5 speed automatic gearbox"..blurb,
	model = "models/engines/transaxial_m.mdl",
	category = "Automatic",
	weight = Gear5MW,
	switch = ShiftM,
	maxtq = Gear5MT,
	auto = true,
	doubleclutch = true,
	gears = 5,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "5Gear-A-TD-L", {
	name = "5-Speed Auto, Transaxial, Large, Dual Clutch",
	desc = "A large, heavy and sturdy 5 speed automatic gearbox"..blurb,
	model = "models/engines/transaxial_l.mdl",
	category = "Automatic",
	weight = Gear5LW,
	switch = ShiftL,
	maxtq = Gear5LT,
	auto = true,
	doubleclutch = true,
	gears = 5,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

-- Straight-through gearboxes

ACF_DefineGearbox( "5Gear-A-ST-S", {
	name = "5-Speed Auto, Straight, Small",
	desc = "A small straight-through automatic gearbox"..blurb,
	model = "models/engines/t5small.mdl",
	category = "Automatic",
	weight = math.floor(Gear5SW * StWB),
	switch = ShiftS,
	maxtq = math.floor(Gear5ST * StTB),
	auto = true,
	gears = 5,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "5Gear-A-ST-M", {
	name = "5-Speed Auto, Straight, Medium",
	desc = "A medium sized, 5 speed automatic straight-through gearbox."..blurb,
	model = "models/engines/t5med.mdl",
	category = "Automatic",
	weight = math.floor(Gear5MW * StWB),
	switch = ShiftM,
	maxtq = math.floor(Gear5MT * StTB),
	auto = true,
	gears = 5,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "5Gear-A-ST-L", {
	name = "5-Speed Auto, Straight, Large",
	desc = "A large sized, 5 speed automatic straight-through gearbox."..blurb,
	model = "models/engines/t5large.mdl",
	category = "Automatic",
	weight = math.floor(Gear5LW * StWB),
	switch = ShiftL,
	maxtq = math.floor(Gear5LT * StTB),
	auto = true,
	gears = 5,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )


-- 7 Speed
-- Inline

ACF_DefineGearbox( "7Gear-A-L-S", {
	name = "7-Speed Auto, Inline, Small",
	desc = "A small, and light 7 speed automatic inline gearbox, with a somewhat limited max torque rating"..blurb,
	model = "models/engines/linear_s.mdl",
	category = "Automatic",
	weight = Gear7SW,
	switch = ShiftS,
	maxtq = Gear7ST,
	auto = true,
	gears = 7,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "7Gear-A-L-M", {
	name = "7-Speed Auto, Inline, Medium",
	desc = "A medium sized, 7 speed automatic inline gearbox"..blurb,
	model = "models/engines/linear_m.mdl",
	category = "Automatic",
	weight = Gear7MW,
	switch = ShiftM,
	maxtq = Gear7MT,
	auto = true,
	gears = 7,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "7Gear-A-L-L", {
	name = "7-Speed Auto, Inline, Large",
	desc = "A large, heavy and sturdy 7 speed inline gearbox"..blurb,
	model = "models/engines/linear_l.mdl",
	category = "Automatic",
	weight = Gear7LW,
	switch = ShiftL,
	maxtq = Gear7LT,
	auto = true,
	gears = 7,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

-- Inline Dual Clutch

ACF_DefineGearbox( "7Gear-A-LD-S", {
	name = "7-Speed Auto, Inline, Small, Dual Clutch",
	desc = "A small, and light 7 speed automatic inline gearbox, with a somewhat limited max torque rating"..blurb,
	model = "models/engines/linear_s.mdl",
	category = "Automatic",
	weight = Gear7SW,
	switch = ShiftS,
	maxtq = Gear7ST,
	auto = true,
	doubleclutch = true,
	gears = 7,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "7Gear-A-LD-M", {
	name = "7-Speed Auto, Inline, Medium, Dual Clutch",
	desc = "A medium sized, 7 speed automatic inline gearbox"..blurb,
	model = "models/engines/linear_m.mdl",
	category = "Automatic",
	weight = Gear7MW,
	switch = ShiftM,
	maxtq = Gear7MT,
	auto = true,
	doubleclutch = true,
	gears = 7,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "7Gear-A-LD-L", {
	name = "7-Speed Auto, Inline, Large, Dual Clutch",
	desc = "A large, heavy and sturdy 7 speed automatic inline gearbox"..blurb,
	model = "models/engines/linear_l.mdl",
	category = "Automatic",
	weight = Gear7LW,
	switch = ShiftL,
	maxtq = Gear7LT,
	auto = true,
	doubleclutch = true,
	gears = 7,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

-- Transaxial

ACF_DefineGearbox( "7Gear-A-T-S", {
	name = "7-Speed Auto, Transaxial, Small",
	desc = "A small, and light 7 speed automatic gearbox, with a somewhat limited max torque rating"..blurb,
	model = "models/engines/transaxial_s.mdl",
	category = "Automatic",
	weight = Gear7SW,
	switch = ShiftS,
	maxtq = Gear7ST,
	auto = true,
	gears = 7,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "7Gear-A-T-M", {
	name = "7-Speed Auto, Transaxial, Medium",
	desc = "A medium sized, 7 speed automatic gearbox"..blurb,
	model = "models/engines/transaxial_m.mdl",
	category = "Automatic",
	weight = Gear7MW,
	switch = ShiftM,
	maxtq = Gear7MT,
	auto = true,
	gears = 7,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "7Gear-A-T-L", {
	name = "7-Speed Auto, Transaxial, Large",
	desc = "A large, heavy and sturdy 7 speed automatic gearbox"..blurb,
	model = "models/engines/transaxial_l.mdl",
	category = "Automatic",
	weight = Gear7LW,
	switch = ShiftL,
	maxtq = Gear7LT,
	auto = true,
	gears = 7,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

-- Transaxial Dual Clutch

ACF_DefineGearbox( "7Gear-A-TD-S", {
	name = "7-Speed Auto, Transaxial, Small, Dual Clutch",
	desc = "A small, and light 7 speed automatic gearbox, with a somewhat limited max torque rating"..blurb,
	model = "models/engines/transaxial_s.mdl",
	category = "Automatic",
	weight = Gear7SW,
	switch = ShiftS,
	maxtq = Gear7ST,
	auto = true,
	doubleclutch = true,
	gears = 7,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "7Gear-A-TD-M", {
	name = "7-Speed Auto, Transaxial, Medium, Dual Clutch",
	desc = "A medium sized, 7 speed automatic gearbox"..blurb,
	model = "models/engines/transaxial_m.mdl",
	category = "Automatic",
	weight = Gear7MW,
	switch = ShiftM,
	maxtq = Gear7MT,
	auto = true,
	doubleclutch = true,
	gears = 7,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "7Gear-A-TD-L", {
	name = "7-Speed Auto, Transaxial, Large, Dual Clutch",
	desc = "A large, heavy and sturdy 7 speed automatic gearbox"..blurb,
	model = "models/engines/transaxial_l.mdl",
	category = "Automatic",
	weight = Gear7LW,
	switch = ShiftL,
	maxtq = Gear7LT,
	auto = true,
	doubleclutch = true,
	gears = 7,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

-- Straight-through gearboxes

ACF_DefineGearbox( "7Gear-A-ST-S", {
	name = "7-Speed Auto, Straight, Small",
	desc = "A small straight-through automatic gearbox"..blurb,
	model = "models/engines/t5small.mdl",
	category = "Automatic",
	weight = math.floor(Gear7SW * StWB),
	switch = ShiftS,
	maxtq = math.floor(Gear7ST * StTB),
	auto = true,
	gears = 7,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "7Gear-A-ST-M", {
	name = "7-Speed Auto, Straight, Medium",
	desc = "A medium sized, 7 speed automatic straight-through gearbox."..blurb,
	model = "models/engines/t5med.mdl",
	category = "Automatic",
	weight = math.floor(Gear7MW * StWB),
	switch = ShiftM,
	maxtq = math.floor(Gear7MT * StTB),
	auto = true,
	gears = 7,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "7Gear-A-ST-L", {
	name = "7-Speed Auto, Straight, Large",
	desc = "A large sized, 7 speed automatic straight-through gearbox."..blurb,
	model = "models/engines/t5large.mdl",
	category = "Automatic",
	weight = math.floor(Gear7LW * StWB),
	switch = ShiftL,
	maxtq = math.floor(Gear7LT * StTB),
	auto = true,
	gears = 7,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.1,
		[ 2 ] = 0.2,
		[ 3 ] = 0.3,
		[ 4 ] = 0.4,
		[ 5 ] = 0.5,
		[ 6 ] = 0.6,
		[ 7 ] = 0.7,
		[ -2 ] = -0.1,
		[ -1 ] = 0.5
	}
} )
