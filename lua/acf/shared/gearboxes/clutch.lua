
-- Clutch

-- Weight
local CTW = 2
local CSW = 5
local CMW = 10
local CLW = 20

-- Torque Rating
local CTT = 75
local CST = 650
local CMT = 1400
local CLT = 8000

-- general description
local CDesc = "A standalone clutch for when a full size gearbox is unnecessary or too long."

-- Straight-through

ACF_DefineGearbox( "Clutch-S-T", {
	name = "Clutch, Straight, Tiny",
	desc = CDesc,
	model = "models/engines/flywheelclutcht.mdl",
	category = "Clutch",
	weight = CTW,
	parentable = true,
	switch = 0.1,
	maxtq = CTT,
	gears = 0,
	geartable = {
		[ 0 ] = 1,
		[ 1 ] = 1,
		[ -1 ] = 1
	}
} )

ACF_DefineGearbox( "Clutch-S-S", {
	name = "Clutch, Straight, Small",
	desc = CDesc,
	model = "models/engines/flywheelclutchs.mdl",
	category = "Clutch",
	weight = CSW,
	parentable = true,
	switch = 0.15,
	maxtq = CST,
	gears = 0,
	geartable = {
		[ 0 ] = 1,
		[ 1 ] = 1,
		[ -1 ] = 1
	}
} )

ACF_DefineGearbox( "Clutch-S-M", {
	name = "Clutch, Straight, Medium",
	desc = CDesc,
	model = "models/engines/flywheelclutchm.mdl",
	category = "Clutch",
	weight = CMW,
	parentable = true,
	switch = 0.2,
	maxtq = CMT,
	gears = 0,
	geartable = {
		[ 0 ] = 1,
		[ 1 ] = 1,
		[ -1 ] = 1
	}
} )

ACF_DefineGearbox( "Clutch-S-L", {
	name = "Clutch, Straight, Large",
	desc = CDesc,
	model = "models/engines/flywheelclutchb.mdl",
	category = "Clutch",
	weight = CLW,
	parentable = true,
	switch = 0.3,
	maxtq = CLT,
	gears = 0,
	geartable = {
		[ 0 ] = 1,
		[ 1 ] = 1,
		[ -1 ] = 1
	}
} )

ACF.RegisterGearboxClass("Clutch", {
	Name		= "Clutch",
	CreateMenu	= ACF.ManualGearboxMenu,
	Gears = {
		Min	= 1,
		Max	= 1,
	}
})

do -- Straight-through Gearboxes
	ACF.RegisterGearbox("Clutch-S-T", "Clutch", {
		Name		= "Clutch, Straight, Tiny",
		Description	= CDesc,
		Model		= "models/engines/flywheelclutcht.mdl",
		Mass		= CTW,
		Switch		= 0.1,
		MaxTorque	= CTT,
	})

	ACF.RegisterGearbox("Clutch-S-S", "Clutch", {
		Name		= "Clutch, Straight, Small",
		Description	= CDesc,
		Model		= "models/engines/flywheelclutchs.mdl",
		Mass		= CSW,
		Switch		= 0.15,
		MaxTorque	= CST,
	})

	ACF.RegisterGearbox("Clutch-S-M", "Clutch", {
		Name		= "Clutch, Straight, Medium",
		Description	= CDesc,
		Model		= "models/engines/flywheelclutchm.mdl",
		Mass		= CMW,
		Switch		= 0.2,
		MaxTorque	= CMT,
	})

	ACF.RegisterGearbox("Clutch-S-L", "Clutch", {
		Name		= "Clutch, Straight, Large",
		Description	= CDesc,
		Model		= "models/engines/flywheelclutchb.mdl",
		Mass		= CLW,
		Switch		= 0.3,
		MaxTorque	= CLT,
	})
end
