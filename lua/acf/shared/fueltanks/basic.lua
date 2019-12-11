
--definition for the fuel tank that shows on menu
ACF_DefineFuelTank( "Basic_FuelTank", {
	name = "High Grade Fuel Tank",
	desc = "A fuel tank containing high grade fuel. Guaranteed to improve engine performance by "..((ACF.TorqueBoost-1)*100).."%.",
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
