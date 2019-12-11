
-- Differentials

local Gear1SW = 10
local Gear1MW = 20
local Gear1LW = 40

-- Inline

ACF_DefineGearbox( "1Gear-L-S", {
	name = "Differential, Inline, Small",
	desc = "Small differential, used to connect power from gearbox to wheels",
	model = "models/engines/linear_s.mdl",
	category = "Differential",
	weight = Gear1SW,
	parentable = true,
	switch = 0.3,
	maxtq = 25000,
	gears = 1,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.5,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "1Gear-L-M", {
	name = "Differential, Inline, Medium",
	desc = "Medium duty differential",
	model = "models/engines/linear_m.mdl",
	category = "Differential",
	weight = Gear1MW,
	parentable = true,
	switch = 0.4,
	maxtq = 50000,
	gears = 1,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.5,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "1Gear-L-L", {
	name = "Differential, Inline, Large",
	desc = "Heavy duty differential, for the heaviest of engines",
	model = "models/engines/linear_l.mdl",
	category = "Differential",
	weight = Gear1LW,
	parentable = true,
	switch = 0.6,
	maxtq = 100000,
	gears = 1,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.5,
		[ -1 ] = 1
	}
} )

-- Inline Dual Clutch

ACF_DefineGearbox( "1Gear-LD-S", {
	name = "Differential, Inline, Small, Dual Clutch",
	desc = "Small differential, used to connect power from gearbox to wheels",
	model = "models/engines/linear_s.mdl",
	category = "Differential",
	weight = Gear1SW,
	parentable = true,
	switch = 0.3,
	maxtq = 25000,
	gears = 1,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.5,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "1Gear-LD-M", {
	name = "Differential, Inline, Medium, Dual Clutch",
	desc = "Medium duty differential",
	model = "models/engines/linear_m.mdl",
	category = "Differential",
	weight = Gear1MW,
	parentable = true,
	switch = 0.4,
	maxtq = 50000,
	gears = 1,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.5,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "1Gear-LD-L", {
	name = "Differential, Inline, Large, Dual Clutch",
	desc = "Heavy duty differential, for the heaviest of engines",
	model = "models/engines/linear_l.mdl",
	category = "Differential",
	weight = Gear1LW,
	parentable = true,
	switch = 0.6,
	maxtq = 100000,
	gears = 1,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.5,
		[ -1 ] = 1
	}
} )

-- Transaxial

ACF_DefineGearbox( "1Gear-T-S", {
	name = "Differential, Small",
	desc = "Small differential, used to connect power from gearbox to wheels",
	model = "models/engines/transaxial_s.mdl",
	category = "Differential",
	weight = Gear1SW,
	parentable = true,
	switch = 0.3,
	maxtq = 25000,
	gears = 1,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.5,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "1Gear-T-M", {
	name = "Differential, Medium",
	desc = "Medium duty differential",
	model = "models/engines/transaxial_m.mdl",
	category = "Differential",
	weight = Gear1MW,
	parentable = true,
	switch = 0.4,
	maxtq = 50000,
	gears = 1,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.5,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "1Gear-T-L", {
	name = "Differential, Large",
	desc = "Heavy duty differential, for the heaviest of engines",
	model = "models/engines/transaxial_l.mdl",
	category = "Differential",
	parentable = true,
	weight = Gear1LW,
	switch = 0.6,
	maxtq = 100000,
	gears = 1,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.5,
		[ -1 ] = 1
	}
} )

-- Transaxial Dual Clutch

ACF_DefineGearbox( "1Gear-TD-S", {
	name = "Differential, Small, Dual Clutch",
	desc = "Small differential, used to connect power from gearbox to wheels",
	model = "models/engines/transaxial_s.mdl",
	category = "Differential",
	weight = Gear1SW,
	parentable = true,
	switch = 0.3,
	maxtq = 25000,
	gears = 1,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.5,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "1Gear-TD-M", {
	name = "Differential, Medium, Dual Clutch",
	desc = "Medium duty differential",
	model = "models/engines/transaxial_m.mdl",
	category = "Differential",
	weight = Gear1MW,
	parentable = true,
	switch = 0.4,
	maxtq = 50000,
	gears = 1,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.5,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "1Gear-TD-L", {
	name = "Differential, Large, Dual Clutch",
	desc = "Heavy duty differential, for the heaviest of engines",
	model = "models/engines/transaxial_l.mdl",
	category = "Differential",
	weight = Gear1LW,
	parentable = true,
	switch = 0.6,
	maxtq = 100000,
	gears = 1,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.5,
		[ -1 ] = 1
	}
} )
