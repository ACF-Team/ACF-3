
--definition for the fuel tank that shows on menu
ACF_DefineFuelTank( "Basic_FuelTank", {
	name = "High Grade Fuel Tank",
	desc = "A fuel tank containing high grade fuel. Guaranteed to improve engine performance by " .. ((ACF.TorqueBoost-1) * 100) .. "%.",
	category = "High Grade"
} )

--definitions for the possible tank sizes selectable from the basic tank.
ACF_DefineFuelTankSize( "Tank_1x1x1", { --ID used in code
	name = "1x1x1", --human readable name
	desc = "Seriously consider walking.",
	model = "models/fueltank/fueltank_1x1x1.mdl",
	dims = { S = 590.5, V = 1019.9 } --surface area and volume of prop in gmu, used for capacity calcs in gui
} )

ACF_DefineFuelTankSize( "Tank_1x1x2", {
	name = "1x1x2",
	desc = "Will keep a kart running all day.",
	model = "models/fueltank/fueltank_1x1x2.mdl",
	dims = { S = 974, V = 1983.1 }
} )

ACF_DefineFuelTankSize( "Tank_1x1x4", {
	name = "1x1x4",
	desc = "Dinghy",
	model = "models/fueltank/fueltank_1x1x4.mdl",
	dims = { S = 1777.4, V = 3995.1 }
} )

ACF_DefineFuelTankSize( "Tank_1x2x1", {
	name = "1x2x1",
	desc = "Will keep a kart running all day.",
	model = "models/fueltank/fueltank_1x2x1.mdl",
	dims = { S = 995, V = 2062.5 }
} )

ACF_DefineFuelTankSize( "Tank_1x2x2", {
	name = "1x2x2",
	desc = "Dinghy",
	model = "models/fueltank/fueltank_1x2x2.mdl",
	dims = { S = 1590.8, V = 4070.9 }
} )

ACF_DefineFuelTankSize( "Tank_1x2x4", {
	name = "1x2x4",
	desc = "Outboard motor.",
	model = "models/fueltank/fueltank_1x2x4.mdl",
	dims = { S = 2796.6, V = 8119.2 }
} )

ACF_DefineFuelTankSize( "Tank_1x4x1", {
	name = "1x4x1",
	desc = "Dinghy",
	model = "models/fueltank/fueltank_1x4x1.mdl",
	dims = { S = 1745.6, V = 3962 }
} )

ACF_DefineFuelTankSize( "Tank_1x4x2", {
	name = "1x4x2",
	desc = "Clown car.",
	model = "models/fueltank/fueltank_1x4x2.mdl",
	dims = { S = 2753.9, V = 8018 }
} )

ACF_DefineFuelTankSize( "Tank_1x4x4", {
	name = "1x4x4",
	desc = "Fuel pancake.",
	model = "models/fueltank/fueltank_1x4x4.mdl",
	dims = { S = 4761, V = 16030.4 }
} )

ACF_DefineFuelTankSize( "Tank_1x6x1", {
	name = "1x6x1",
	desc = "Lawn tractors.",
	model = "models/fueltank/fueltank_1x6x1.mdl",
	dims = { S = 2535.3, V = 5973.1 }
} )

ACF_DefineFuelTankSize( "Tank_1x6x2", {
	name = "1x6x2",
	desc = "Small tractor tank.",
	model = "models/fueltank/fueltank_1x6x2.mdl",
	dims = { S = 3954.1, V = 12100.3 }
} )

ACF_DefineFuelTankSize( "Tank_1x6x4", {
	name = "1x6x4",
	desc = "Fuel.  Will keep you going for awhile.",
	model = "models/fueltank/fueltank_1x6x4.mdl",
	dims = { S = 6743.3, V = 24109.4 }
} )

ACF_DefineFuelTankSize( "Tank_1x8x1", {
	name = "1x8x1",
	desc = "Clown car.",
	model = "models/fueltank/fueltank_1x8x1.mdl",
	dims = { S = 3315.5, V = 7962.4 }
} )

ACF_DefineFuelTankSize( "Tank_1x8x2", {
	name = "1x8x2",
	desc = "Gas stations?  We don't need no stinking gas stations!",
	model = "models/fueltank/fueltank_1x8x2.mdl",
	dims = { S = 5113.7, V = 16026.2 }
} )

ACF_DefineFuelTankSize( "Tank_1x8x4", {
	name = "1x8x4",
	desc = "Beep beep.",
	model = "models/fueltank/fueltank_1x8x4.mdl",
	dims = { S = 8696, V = 31871 }
} )

ACF_DefineFuelTankSize( "Tank_2x2x1", {
	name = "2x2x1",
	desc = "Dinghy",
	model = "models/fueltank/fueltank_2x2x1.mdl",
	dims = { S = 1592.2, V = 4285.2 }
} )

ACF_DefineFuelTankSize( "Tank_2x2x2", {
	name = "2x2x2",
	desc = "Clown car.",
	model = "models/fueltank/fueltank_2x2x2.mdl",
	dims = { S = 2360.4, V = 8212.9 }
} )

ACF_DefineFuelTankSize( "Tank_2x2x4", {
	name = "2x2x4",
	desc = "Mini Cooper.",
	model = "models/fueltank/fueltank_2x2x4.mdl",
	dims = { S = 3988.6, V = 16362 }
} )

ACF_DefineFuelTankSize( "Tank_2x4x1", {
	name = "2x4x1",
	desc = "Good bit of go-juice.",
	model = "models/fueltank/fueltank_2x4x1.mdl",
	dims = { S = 2808.8, V = 8628 }
} )

ACF_DefineFuelTankSize( "Tank_2x4x2", {
	name = "2x4x2",
	desc = "Mini Cooper.",
	model = "models/fueltank/fueltank_2x4x2.mdl",
	dims = { S = 3996.1, V = 16761.4 }
} )

ACF_DefineFuelTankSize( "Tank_2x4x4", {
	name = "2x4x4",
	desc = "Land boat.",
	model = "models/fueltank/fueltank_2x4x4.mdl",
	dims = { S = 6397.3, V = 32854.4 }
} )

ACF_DefineFuelTankSize( "Tank_2x6x1", {
	name = "2x6x1",
	desc = "Conformal fuel tank, fits narrow spaces.",
	model = "models/fueltank/fueltank_2x6x1.mdl",
	dims = { S = 3861.4, V = 12389.9 }
} )

ACF_DefineFuelTankSize( "Tank_2x6x2", {
	name = "2x6x2",
	desc = "Compact car.",
	model = "models/fueltank/fueltank_2x6x2.mdl",
	dims = { S = 5388, V = 24127.7 }
} )

ACF_DefineFuelTankSize( "Tank_2x6x4", {
	name = "2x6x4",
	desc = "Sedan.",
	model = "models/fueltank/fueltank_2x6x4.mdl",
	dims = { S = 8485.6, V = 47537.2 }
} )

ACF_DefineFuelTankSize( "Tank_2x8x1", {
	name = "2x8x1",
	desc = "Conformal fuel tank, fits into tight spaces",
	model = "models/fueltank/fueltank_2x8x1.mdl",
	dims = { S = 5094.5, V = 16831.8 }
} )

ACF_DefineFuelTankSize( "Tank_2x8x2", {
	name = "2x8x2",
	desc = "Truck.",
	model = "models/fueltank/fueltank_2x8x2.mdl",
	dims = { S = 6980, V = 32275.9 }
} )

ACF_DefineFuelTankSize( "Tank_2x8x4", {
	name = "2x8x4",
	desc = "With great capacity, comes great responsibili--VROOOOM",
	model = "models/fueltank/fueltank_2x8x4.mdl",
	dims = { S = 10898.2, V = 63976 }
} )

ACF_DefineFuelTankSize( "Tank_4x4x1", {
	name = "4x4x1",
	desc = "Sedan.",
	model = "models/fueltank/fueltank_4x4x1.mdl",
	dims = { S = 4619.1, V = 16539.8 }
} )

ACF_DefineFuelTankSize( "Tank_4x4x2", {
	name = "4x4x2",
	desc = "Land boat.",
	model = "models/fueltank/fueltank_4x4x2.mdl",
	dims = { S = 6071.4, V = 32165.2 }
} )

ACF_DefineFuelTankSize( "Tank_4x4x4", {
	name = "4x4x4",
	desc = "Popular with arsonists.",
	model = "models/fueltank/fueltank_4x4x4.mdl",
	dims = { S = 9145.3, V = 62900.1 }
} )

ACF_DefineFuelTankSize( "Tank_4x6x1", {
	name = "4x6x1",
	desc = "Conformal fuel tank, fits in tight spaces.",
	model = "models/fueltank/fueltank_4x6x1.mdl",
	dims = { S = 6553.6, V = 24918.6 }
} )

ACF_DefineFuelTankSize( "Tank_4x6x2", {
	name = "4x6x2",
	desc = "Fire juice.",
	model = "models/fueltank/fueltank_4x6x2.mdl",
	dims = { S = 8425.3, V = 48581.2 }
} )

ACF_DefineFuelTankSize( "Tank_4x6x4", {
	name = "4x6x4",
	desc = "Trees are gay anyway.",
	model = "models/fueltank/fueltank_4x6x4.mdl",
	dims = { S = 12200.6, V = 94640 }
} )

ACF_DefineFuelTankSize( "Tank_4x8x1", {
	name = "4x8x1",
	desc = "Arson material.",
	model = "models/fueltank/fueltank_4x8x1.mdl",
	dims = { S = 8328.2, V = 32541.9 }
} )

ACF_DefineFuelTankSize( "Tank_4x8x2", {
	name = "4x8x2",
	desc = "What's a gas station?",
	model = "models/fueltank/fueltank_4x8x2.mdl",
	dims = { S = 10419.5, V = 63167.1 }
} )

ACF_DefineFuelTankSize( "Tank_4x8x4", {
	name = "4x8x4",
	desc = "\'MURRICA  FUCKYEAH!",
	model = "models/fueltank/fueltank_4x8x4.mdl",
	dims = { S = 14993.3, V = 123693.2 }
} )

ACF_DefineFuelTankSize( "Tank_6x6x1", {
	name = "6x6x1",
	desc = "Got gas?",
	model = "models/fueltank/fueltank_6x6x1.mdl",
	dims = { S = 9405.2, V = 37278.5 }
} )

ACF_DefineFuelTankSize( "Tank_6x6x2", {
	name = "6x6x2",
	desc = "Drive across the desert without a fuck to give.",
	model = "models/fueltank/fueltank_6x6x2.mdl",
	dims = { S = 11514.5, V = 73606.2 }
} )

ACF_DefineFuelTankSize( "Tank_6x6x4", {
	name = "6x6x4",
	desc = "May contain Mesozoic ghosts.",
	model = "models/fueltank/fueltank_6x6x4.mdl",
	dims = { S = 16028.8, V = 143269 }
} )

ACF_DefineFuelTankSize( "Tank_6x8x1", {
	name = "6x8x1",
	desc = "Conformal fuel tank, does what all its friends do.",
	model = "models/fueltank/fueltank_6x8x1.mdl",
	dims = { S = 12131.1, V = 48480.2 }
} )

ACF_DefineFuelTankSize( "Tank_6x8x2", {
	name = "6x8x2",
	desc = "Certified 100% dinosaur juice.",
	model = "models/fueltank/fueltank_6x8x2.mdl",
	dims = { S = 14403.8, V = 95065.5 }
} )

ACF_DefineFuelTankSize( "Tank_6x8x4", {
	name = "6x8x4",
	desc = "Will last you a while.",
	model = "models/fueltank/fueltank_6x8x4.mdl",
	dims = { S = 19592.4, V = 187296.4 }
} )

ACF_DefineFuelTankSize( "Tank_8x8x1", {
	name = "8x8x1",
	desc = "Sloshy sloshy!",
	model = "models/fueltank/fueltank_8x8x1.mdl",
	dims = { S = 15524.8, V = 64794.2 }
} )

ACF_DefineFuelTankSize( "Tank_8x8x2", {
	name = "8x8x2",
	desc = "What's global warming?",
	model = "models/fueltank/fueltank_8x8x2.mdl",
	dims = { S = 18086.4, V = 125868.9 }
} )

ACF_DefineFuelTankSize( "Tank_8x8x4", {
	name = "8x8x4",
	desc = "Tank Tank.",
	model = "models/fueltank/fueltank_8x8x4.mdl",
	dims = { S = 23957.6, V = 246845.3 }
} )

ACF_DefineFuelTankSize( "Fuel_Drum", {
	name = "Fuel Drum",
	desc = "Tends to explode when shot.",
	model = "models/props_c17/oildrum001_explosive.mdl",
	dims = { S = 5128.9, V = 26794.4 }
} )

ACF_DefineFuelTankSize( "Jerry_Can", {
	name = "Jerry Can",
	desc = "Handy portable fuel container.",
	model = "models/props_junk/gascan001a.mdl",
	dims = { S = 1839.7, V = 4384.1 },
} )

ACF_DefineFuelTankSize( "Transport_Tank", {
	name = "Transport Tank",
	desc = "Disappointingly non-explosive.",
	model = "models/props_wasteland/horizontalcoolingtank04.mdl",
	dims = { S = 127505.5, V = 2102493.3 },
	explosive = false,
	nolinks = true
} )

ACF_DefineFuelTankSize( "Storage_Tank", {
	name = "Storage Tank",
	desc = "Disappointingly non-explosive.",
	model = "models/props_wasteland/coolingtank02.mdl",
	dims = { S = 144736.3, V = 2609960 },
	explosive = false,
	nolinks = true
} )

do -- Fuel tanks
	ACF.RegisterFuelTank("Tank_1x1x1", { --ID used in code
		Name		= "1x1x1",
		Description	= "Seriously consider walking.",
		Model		= "models/fueltank/fueltank_1x1x1.mdl",
		SurfaceArea	= 590.5,
		Volume		= 1019.9,
	})

	ACF.RegisterFuelTank("Tank_1x1x2", {
		Name		= "1x1x2",
		Description	= "Will keep a kart running all day.",
		Model		= "models/fueltank/fueltank_1x1x2.mdl",
		SurfaceArea	= 974,
		Volume		= 1983.1,
	})

	ACF.RegisterFuelTank("Tank_1x1x4", {
		Name		= "1x1x4",
		Description	= "Dinghy",
		Model		= "models/fueltank/fueltank_1x1x4.mdl",
		SurfaceArea	= 1777.4,
		Volume		= 3995.1,
	})

	ACF.RegisterFuelTank("Tank_1x2x1", {
		Name		= "1x2x1",
		Description	= "Will keep a kart running all day.",
		Model		= "models/fueltank/fueltank_1x2x1.mdl",
		SurfaceArea	= 995,
		Volume		= 2062.5,
	})

	ACF.RegisterFuelTank("Tank_1x2x2", {
		Name		= "1x2x2",
		Description	= "Dinghy",
		Model		= "models/fueltank/fueltank_1x2x2.mdl",
		SurfaceArea	= 1590.8,
		Volume		= 4070.9,
	})

	ACF.RegisterFuelTank("Tank_1x2x4", {
		Name		= "1x2x4",
		Description	= "Outboard motor.",
		Model		= "models/fueltank/fueltank_1x2x4.mdl",
		SurfaceArea	= 2796.6,
		Volume		= 8119.2,
	})

	ACF.RegisterFuelTank("Tank_1x4x1", {
		Name		= "1x4x1",
		Description	= "Dinghy",
		Model		= "models/fueltank/fueltank_1x4x1.mdl",
		SurfaceArea	= 1745.6,
		Volume		= 3962,
	})

	ACF.RegisterFuelTank("Tank_1x4x2", {
		Name		= "1x4x2",
		Description	= "Clown car.",
		Model		= "models/fueltank/fueltank_1x4x2.mdl",
		SurfaceArea	= 2753.9,
		Volume		= 8018,
	})

	ACF.RegisterFuelTank("Tank_1x4x4", {
		Name		= "1x4x4",
		Description	= "Fuel pancake.",
		Model		= "models/fueltank/fueltank_1x4x4.mdl",
		SurfaceArea	= 4761,
		Volume		= 16030.4,
	})

	ACF.RegisterFuelTank("Tank_1x6x1", {
		Name		= "1x6x1",
		Description	= "Lawn tractors.",
		Model		= "models/fueltank/fueltank_1x6x1.mdl",
		SurfaceArea	= 2535.3,
		Volume		= 5973.1,
	})

	ACF.RegisterFuelTank("Tank_1x6x2", {
		Name		= "1x6x2",
		Description	= "Small tractor tank.",
		Model		= "models/fueltank/fueltank_1x6x2.mdl",
		SurfaceArea	= 3954.1,
		Volume		= 12100.3,
	})

	ACF.RegisterFuelTank("Tank_1x6x4", {
		Name		= "1x6x4",
		Description	= "Fuel.  Will keep you going for awhile.",
		Model		= "models/fueltank/fueltank_1x6x4.mdl",
		SurfaceArea	= 6743.3,
		Volume		= 24109.4,
	})

	ACF.RegisterFuelTank("Tank_1x8x1", {
		Name		= "1x8x1",
		Description	= "Clown car.",
		Model		= "models/fueltank/fueltank_1x8x1.mdl",
		SurfaceArea	= 3315.5,
		Volume		= 7962.4,
	})

	ACF.RegisterFuelTank("Tank_1x8x2", {
		Name		= "1x8x2",
		Description	= "Gas stations?  We don't need no stinking gas stations!",
		Model		= "models/fueltank/fueltank_1x8x2.mdl",
		SurfaceArea	= 5113.7,
		Volume		= 16026.2,
	})

	ACF.RegisterFuelTank("Tank_1x8x4", {
		Name		= "1x8x4",
		Description	= "Beep beep.",
		Model		= "models/fueltank/fueltank_1x8x4.mdl",
		SurfaceArea	= 8696,
		Volume		= 31871,
	})

	ACF.RegisterFuelTank("Tank_2x2x1", {
		Name		= "2x2x1",
		Description	= "Dinghy",
		Model		= "models/fueltank/fueltank_2x2x1.mdl",
		SurfaceArea	= 1592.2,
		Volume		= 4285.2,
	})

	ACF.RegisterFuelTank("Tank_2x2x2", {
		Name		= "2x2x2",
		Description	= "Clown car.",
		Model		= "models/fueltank/fueltank_2x2x2.mdl",
		SurfaceArea	= 2360.4,
		Volume		= 8212.9,
	})

	ACF.RegisterFuelTank("Tank_2x2x4", {
		Name		= "2x2x4",
		Description	= "Mini Cooper.",
		Model		= "models/fueltank/fueltank_2x2x4.mdl",
		SurfaceArea	= 3988.6,
		Volume		= 16362,
	})

	ACF.RegisterFuelTank("Tank_2x4x1", {
		Name		= "2x4x1",
		Description	= "Good bit of go-juice.",
		Model		= "models/fueltank/fueltank_2x4x1.mdl",
		SurfaceArea	= 2808.8,
		Volume		= 8628,
	})

	ACF.RegisterFuelTank("Tank_2x4x2", {
		Name		= "2x4x2",
		Description	= "Mini Cooper.",
		Model		= "models/fueltank/fueltank_2x4x2.mdl",
		SurfaceArea	= 3996.1,
		Volume		= 16761.4,
	})

	ACF.RegisterFuelTank("Tank_2x4x4", {
		Name		= "2x4x4",
		Description	= "Land boat.",
		Model		= "models/fueltank/fueltank_2x4x4.mdl",
		SurfaceArea	= 6397.3,
		Volume		= 32854.4,
	})

	ACF.RegisterFuelTank("Tank_2x6x1", {
		Name		= "2x6x1",
		Description	= "Conformal fuel tank, fits narrow spaces.",
		Model		= "models/fueltank/fueltank_2x6x1.mdl",
		SurfaceArea	= 3861.4,
		Volume		= 12389.9,
	})

	ACF.RegisterFuelTank("Tank_2x6x2", {
		Name		= "2x6x2",
		Description	= "Compact car.",
		Model		= "models/fueltank/fueltank_2x6x2.mdl",
		SurfaceArea	= 5388,
		Volume		= 24127.7,
	})

	ACF.RegisterFuelTank("Tank_2x6x4", {
		Name		= "2x6x4",
		Description	= "Sedan.",
		Model		= "models/fueltank/fueltank_2x6x4.mdl",
		SurfaceArea	= 8485.6,
		Volume		= 47537.2,
	})

	ACF.RegisterFuelTank("Tank_2x8x1", {
		Name		= "2x8x1",
		Description	= "Conformal fuel tank, fits into tight spaces",
		Model		= "models/fueltank/fueltank_2x8x1.mdl",
		SurfaceArea	= 5094.5,
		Volume		= 16831.8,
	})

	ACF.RegisterFuelTank("Tank_2x8x2", {
		Name		= "2x8x2",
		Description	= "Truck.",
		Model		= "models/fueltank/fueltank_2x8x2.mdl",
		SurfaceArea	= 6980,
		Volume		= 32275.9,
	})

	ACF.RegisterFuelTank("Tank_2x8x4", {
		Name		= "2x8x4",
		Description	= "With great capacity, comes great responsibili--VROOOOM",
		Model		= "models/fueltank/fueltank_2x8x4.mdl",
		SurfaceArea	= 10898.2,
		Volume		= 63976,
	})

	ACF.RegisterFuelTank("Tank_4x4x1", {
		Name		= "4x4x1",
		Description	= "Sedan.",
		Model		= "models/fueltank/fueltank_4x4x1.mdl",
		SurfaceArea	= 4619.1,
		Volume		= 16539.8,
	})

	ACF.RegisterFuelTank("Tank_4x4x2", {
		Name		= "4x4x2",
		Description	= "Land boat.",
		Model		= "models/fueltank/fueltank_4x4x2.mdl",
		SurfaceArea	= 6071.4,
		Volume		= 32165.2,
	})

	ACF.RegisterFuelTank("Tank_4x4x4", {
		Name		= "4x4x4",
		Description	= "Popular with arsonists.",
		Model		= "models/fueltank/fueltank_4x4x4.mdl",
		SurfaceArea	= 9145.3,
		Volume		= 62900.1,
	})

	ACF.RegisterFuelTank("Tank_4x6x1", {
		Name		= "4x6x1",
		Description	= "Conformal fuel tank, fits in tight spaces.",
		Model		= "models/fueltank/fueltank_4x6x1.mdl",
		SurfaceArea	= 6553.6,
		Volume		= 24918.6,
	})

	ACF.RegisterFuelTank("Tank_4x6x2", {
		Name		= "4x6x2",
		Description	= "Fire juice.",
		Model		= "models/fueltank/fueltank_4x6x2.mdl",
		SurfaceArea	= 8425.3,
		Volume		= 48581.2,
	})

	ACF.RegisterFuelTank("Tank_4x6x4", {
		Name		= "4x6x4",
		Description	= "Trees are gay anyway.",
		Model		= "models/fueltank/fueltank_4x6x4.mdl",
		SurfaceArea	= 12200.6,
		Volume		= 94640,
	})

	ACF.RegisterFuelTank("Tank_4x8x1", {
		Name		= "4x8x1",
		Description	= "Arson material.",
		Model		= "models/fueltank/fueltank_4x8x1.mdl",
		SurfaceArea	= 8328.2,
		Volume		= 32541.9,
	})

	ACF.RegisterFuelTank("Tank_4x8x2", {
		Name		= "4x8x2",
		Description	= "What's a gas station?",
		Model		= "models/fueltank/fueltank_4x8x2.mdl",
		SurfaceArea	= 10419.5,
		Volume		= 63167.1,
	})

	ACF.RegisterFuelTank("Tank_4x8x4", {
		Name		= "4x8x4",
		Description	= "\'MURRICA  FUCKYEAH!",
		Model		= "models/fueltank/fueltank_4x8x4.mdl",
		SurfaceArea	= 14993.3,
		Volume		= 123693.2,
	})

	ACF.RegisterFuelTank("Tank_6x6x1", {
		Name		= "6x6x1",
		Description	= "Got gas?",
		Model		= "models/fueltank/fueltank_6x6x1.mdl",
		SurfaceArea	= 9405.2,
		Volume		= 37278.5,
	})

	ACF.RegisterFuelTank("Tank_6x6x2", {
		Name		= "6x6x2",
		Description	= "Drive across the desert without a fuck to give.",
		Model		= "models/fueltank/fueltank_6x6x2.mdl",
		SurfaceArea	= 11514.5,
		Volume		= 73606.2,
	})

	ACF.RegisterFuelTank("Tank_6x6x4", {
		Name		= "6x6x4",
		Description	= "May contain Mesozoic ghosts.",
		Model		= "models/fueltank/fueltank_6x6x4.mdl",
		SurfaceArea	= 16028.8,
		Volume		= 143269,
	})

	ACF.RegisterFuelTank("Tank_6x8x1", {
		Name		= "6x8x1",
		Description	= "Conformal fuel tank, does what all its friends do.",
		Model		= "models/fueltank/fueltank_6x8x1.mdl",
		SurfaceArea	= 12131.1,
		Volume		= 48480.2,
	})

	ACF.RegisterFuelTank("Tank_6x8x2", {
		Name		= "6x8x2",
		Description	= "Certified 100% dinosaur juice.",
		Model		= "models/fueltank/fueltank_6x8x2.mdl",
		SurfaceArea	= 14403.8,
		Volume		= 95065.5,
	})

	ACF.RegisterFuelTank("Tank_6x8x4", {
		Name		= "6x8x4",
		Description	= "Will last you a while.",
		Model		= "models/fueltank/fueltank_6x8x4.mdl",
		SurfaceArea	= 19592.4,
		Volume		= 187296.4,
	})

	ACF.RegisterFuelTank("Tank_8x8x1", {
		Name		= "8x8x1",
		Description	= "Sloshy sloshy!",
		Model		= "models/fueltank/fueltank_8x8x1.mdl",
		SurfaceArea	= 15524.8,
		Volume		= 64794.2,
	})

	ACF.RegisterFuelTank("Tank_8x8x2", {
		Name		= "8x8x2",
		Description	= "What's global warming?",
		Model		= "models/fueltank/fueltank_8x8x2.mdl",
		SurfaceArea	= 18086.4,
		Volume		= 125868.9,
	})

	ACF.RegisterFuelTank("Tank_8x8x4", {
		Name		= "8x8x4",
		Description	= "Tank Tank.",
		Model		= "models/fueltank/fueltank_8x8x4.mdl",
		SurfaceArea	= 23957.6,
		Volume		= 246845.3,
	})

	ACF.RegisterFuelTank("Fuel_Drum", {
		Name		= "Fuel Drum",
		Description	= "Tends to explode when shot.",
		Model		= "models/props_c17/oildrum001_explosive.mdl",
		SurfaceArea	= 5128.9,
		Volume		= 26794.4,
	})

	ACF.RegisterFuelTank("Jerry_Can", {
		Name		= "Jerry Can",
		Description	= "Handy portable fuel container.",
		Model		= "models/props_junk/gascan001a.mdl",
		SurfaceArea	= 1839.7,
		Volume		= 4384.1,,
	})

	ACF.RegisterFuelTank("Transport_Tank", {
		Name		= "Transport Tank",
		Description	= "Disappointingly non-explosive.",
		Model		= "models/props_wasteland/horizontalcoolingtank04.mdl",
		SurfaceArea	= 127505.5,
		Volume		= 2102493.3,
		IsExplosive	= false,
		Unlinkable	= true,
	})

	ACF.RegisterFuelTank("Storage_Tank", {
		Name		= "Storage Tank",
		Description	= "Disappointingly non-explosive.",
		Model		= "models/props_wasteland/coolingtank02.mdl",
		SurfaceArea	= 144736.3,
		Volume		= 2609960,
		IsExplosive	= false,
		Unlinkable	= true,
	})
end
