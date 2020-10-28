
-- Transfer cases

local Gear2SW = 20
local Gear2MW = 40
local Gear2LW = 80

-- Inline

ACF_DefineGearbox( "2Gear-L-S", {
	name = "Transfer case, Inline, Small",
	desc = "2 speed gearbox, useful for low/high range and tank turning",
	model = "models/engines/linear_s.mdl",
	category = "Transfer",
	weight = Gear2SW,
	parentable = true,
	switch = 0.3,
	maxtq = 25000,
	gears = 2,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.5,
		[ 2 ] = -0.5,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "2Gear-L-M", {
	name = "Transfer case, Inline, Medium",
	desc = "2 speed gearbox, useful for low/high range and tank turning",
	model = "models/engines/linear_m.mdl",
	category = "Transfer",
	weight = Gear2MW,
	parentable = true,
	switch = 0.4,
	maxtq = 50000,
	gears = 2,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.5,
		[ 2 ] = -0.5,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "2Gear-L-L", {
	name = "Transfer case, Inline, Large",
	desc = "2 speed gearbox, useful for low/high range and tank turning",
	model = "models/engines/linear_l.mdl",
	category = "Transfer",
	weight = Gear2LW,
	parentable = true,
	switch = 0.6,
	maxtq = 100000,
	gears = 2,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.5,
		[ 2 ] = -0.5,
		[ -1 ] = 1
	}
} )

-- Transaxial

ACF_DefineGearbox( "2Gear-T-S", {
	name = "Transfer case, Small",
	desc = "2 speed gearbox, useful for low/high range and tank turning",
	model = "models/engines/transaxial_s.mdl",
	category = "Transfer",
	weight = Gear2SW,
	parentable = true,
	switch = 0.3,
	maxtq = 25000,
	gears = 2,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.5,
		[ 2 ] = -0.5,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "2Gear-T-M", {
	name = "Transfer case, Medium",
	desc = "2 speed gearbox, useful for low/high range and tank turning",
	model = "models/engines/transaxial_m.mdl",
	category = "Transfer",
	weight = Gear2MW,
	parentable = true,
	switch = 0.4,
	maxtq = 50000,
	gears = 2,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.5,
		[ 2 ] = -0.5,
		[ -1 ] = 0.5
	}
} )

ACF_DefineGearbox( "2Gear-T-L", {
	name = "Transfer case, Large",
	desc = "2 speed gearbox, useful for low/high range and tank turning",
	model = "models/engines/transaxial_l.mdl",
	category = "Transfer",
	weight = Gear2LW,
	parentable = true,
	switch = 0.6,
	maxtq = 100000,
	gears = 2,
	doubleclutch = true,
	geartable = {
		[ 0 ] = 0,
		[ 1 ] = 0.5,
		[ 2 ] = -0.5,
		[ -1 ] = 1
	}
} )

ACF.RegisterGearboxClass("Transfer", {
	Name		= "Transfer Case",
	CreateMenu	= ACF.ManualGearboxMenu,
	Gears = {
		Min	= 0,
		Max	= 2,
	}
})

do -- Inline Gearboxes
	ACF.RegisterGearbox("2Gear-L-S", "Transfer", {
		Name		= "Transfer case, Inline, Small",
		Description	= "2 speed gearbox, useful for low/high range and tank turning",
		Model		= "models/engines/linear_s.mdl",
		Mass		= Gear2SW,
		Switch		= 0.3,
		MaxTorque	= 25000,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("2Gear-L-M", "Transfer", {
		Name		= "Transfer case, Inline, Medium",
		Description	= "2 speed gearbox, useful for low/high range and tank turning",
		Model		= "models/engines/linear_m.mdl",
		Mass		= Gear2MW,
		Switch		= 0.4,
		MaxTorque	= 50000,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("2Gear-L-L", "Transfer", {
		Name		= "Transfer case, Inline, Large",
		Description	= "2 speed gearbox, useful for low/high range and tank turning",
		Model		= "models/engines/linear_l.mdl",
		Mass		= Gear2LW,
		Switch		= 0.6,
		MaxTorque	= 100000,
		DualClutch	= true,
	})
end

do -- Transaxial Gearboxes
	ACF.RegisterGearbox("2Gear-T-S", "Transfer", {
		Name		= "Transfer case, Small",
		Description	= "2 speed gearbox, useful for low/high range and tank turning",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= Gear2SW,
		Switch		= 0.3,
		MaxTorque	= 25000,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("2Gear-T-M", "Transfer", {
		Name		= "Transfer case, Medium",
		Description	= "2 speed gearbox, useful for low/high range and tank turning",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= Gear2MW,
		Switch		= 0.4,
		MaxTorque	= 50000,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("2Gear-T-L", "Transfer", {
		Name		= "Transfer case, Large",
		Description	= "2 speed gearbox, useful for low/high range and tank turning",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= Gear2LW,
		Switch		= 0.6,
		MaxTorque	= 100000,
		DualClutch	= true,
	})
end
