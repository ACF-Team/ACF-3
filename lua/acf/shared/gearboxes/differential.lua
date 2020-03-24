
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

ACF.RegisterGearboxClass("Differential", {
	Name	= "Differential",
	Gears = {
		Min	= 1,
		Max	= 1,
	}
})

do -- Inline Gearboxes
	ACF.RegisterGearbox("1Gear-L-S", "Differential", {
		Name		= "Differential, Inline, Small",
		Description	= "Small differential, used to connect power from gearbox to wheels",
		Model		= "models/engines/linear_s.mdl",
		Mass		= Gear1SW,
		Switch		= 0.3,
		MaxTorque	= 25000,
	})

	ACF.RegisterGearbox("1Gear-L-M", "Differential", {
		Name		= "Differential, Inline, Medium",
		Description	= "Medium duty differential",
		Model		= "models/engines/linear_m.mdl",
		Mass		= Gear1MW,
		Switch		= 0.4,
		MaxTorque	= 50000,
	})

	ACF.RegisterGearbox("1Gear-L-L", "Differential", {
		Name		= "Differential, Inline, Large",
		Description	= "Heavy duty differential, for the heaviest of engines",
		Model		= "models/engines/linear_l.mdl",
		Mass		= Gear1LW,
		Switch		= 0.6,
		MaxTorque	= 100000,
	})
end

do -- Inline Dual Clutch Gearboxes
	ACF.RegisterGearbox("1Gear-LD-S", "Differential", {
		Name		= "Differential, Inline, Small, Dual Clutch",
		Description	= "Small differential, used to connect power from gearbox to wheels",
		Model		= "models/engines/linear_s.mdl",
		Mass		= Gear1SW,
		Switch		= 0.3,
		MaxTorque	= 25000,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("1Gear-LD-M", "Differential", {
		Name		= "Differential, Inline, Medium, Dual Clutch",
		Description	= "Medium duty differential",
		Model		= "models/engines/linear_m.mdl",
		Mass		= Gear1MW,
		Switch		= 0.4,
		MaxTorque	= 50000,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("1Gear-LD-L", "Differential", {
		Name		= "Differential, Inline, Large, Dual Clutch",
		Description	= "Heavy duty differential, for the heaviest of engines",
		Model		= "models/engines/linear_l.mdl",
		Mass		= Gear1LW,
		Switch		= 0.6,
		MaxTorque	= 100000,
		DualClutch	= true,
	})
end

do -- Transaxial Gearboxes
	ACF.RegisterGearbox("1Gear-T-S", "Differential", {
		Name		= "Differential, Small",
		Description	= "Small differential, used to connect power from gearbox to wheels",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= Gear1SW,
		Switch		= 0.3,
		MaxTorque	= 25000,
	})

	ACF.RegisterGearbox("1Gear-T-M", "Differential", {
		Name		= "Differential, Medium",
		Description	= "Medium duty differential",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= Gear1MW,
		Switch		= 0.4,
		MaxTorque	= 50000,
	})

	ACF.RegisterGearbox("1Gear-T-L", "Differential", {
		Name		= "Differential, Large",
		Description	= "Heavy duty differential, for the heaviest of engines",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= Gear1LW,
		Switch		= 0.6,
		MaxTorque	= 100000,
	})
end

do -- Transaxial Dual Clutch Gearboxes
	ACF.RegisterGearbox("1Gear-TD-S", "Differential", {
		Name		= "Differential, Small, Dual Clutch",
		Description	= "Small differential, used to connect power from gearbox to wheels",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= Gear1SW,
		Switch		= 0.3,
		MaxTorque	= 25000,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("1Gear-TD-M", "Differential", {
		Name		= "Differential, Medium, Dual Clutch",
		Description	= "Medium duty differential",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= Gear1MW,
		Switch		= 0.4,
		MaxTorque	= 50000,
		DualClutch	= true,
	})

	ACF.RegisterGearbox("1Gear-TD-L", "Differential", {
		Name		= "Differential, Large, Dual Clutch",
		Description	= "Heavy duty differential, for the heaviest of engines",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= Gear1LW,
		Switch		= 0.6,
		MaxTorque	= 100000,
		DualClutch	= true,
	})
end
