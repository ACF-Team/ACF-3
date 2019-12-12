
-- Gas turbines

ACF_DefineEngine( "Turbine-Small-Trans", {
	name = "Gas Turbine, Small, Transaxial",
	desc = "A small gas turbine, high power and a very wide powerband\n\nThese turbines are optimized for aero use, but can be used in other specialized roles, being powerful but suffering from poor throttle response and fuel consumption.\n\nOutputs to the side instead of rear.",
	model = "models/engines/turbine_s.mdl",
	sound = "acf_engines/turbine_small.wav",
	category = "Turbine",
	fuel = "Multifuel",
	enginetype = "Turbine",
	requiresfuel = true,
	weight = 160,
	torque = 440,
	flywheelmass = 2.3,
	idlerpm = 1400,
	peakminrpm = 1000,
	peakmaxrpm = 1500,
	limitrpm = 10000,
	iselec = true,
	istrans = true,
	flywheeloverride = 4167
} )

ACF_DefineEngine( "Turbine-Medium-Trans", {
	name = "Gas Turbine, Medium, Transaxial",
	desc = "A medium gas turbine, moderate power but a very wide powerband\n\nThese turbines are optimized for aero use, but can be used in other specialized roles, being powerful but suffering from poor throttle response and fuel consumption.\n\nOutputs to the side instead of rear.",
	model = "models/engines/turbine_m.mdl",
	sound = "acf_engines/turbine_medium.wav",
	category = "Turbine",
	fuel = "Multifuel",
	enginetype = "Turbine",
	requiresfuel = true,
	weight = 320,
	torque = 650,
	flywheelmass = 3.4,
	idlerpm = 1800,
	peakminrpm = 1200,
	peakmaxrpm = 1800,
	limitrpm = 12000,
	iselec = true,
	istrans = true,
	flywheeloverride = 5000
} )

ACF_DefineEngine( "Turbine-Large-Trans", {
	name = "Gas Turbine, Large, Transaxial",
	desc = "A large gas turbine, powerful with a wide powerband\n\nThese turbines are optimized for aero use, but can be used in other specialized roles, being powerful but suffering from poor throttle response and fuel consumption.\n\nOutputs to the side instead of rear.",
	model = "models/engines/turbine_l.mdl",
	sound = "acf_engines/turbine_large.wav",
	category = "Turbine",
	fuel = "Multifuel",
	enginetype = "Turbine",
	requiresfuel = true,
	weight = 880,
	torque = 1592,
	flywheelmass = 8.4,
	idlerpm = 2000,
	peakminrpm = 1350,
	peakmaxrpm = 2025,
	limitrpm = 13500,
	iselec = true,
	istrans = true,
	flywheeloverride = 5625
} )

ACF_DefineEngine( "Turbine-Small", {
	name = "Gas Turbine, Small",
	desc = "A small gas turbine, high power and a very wide powerband\n\nThese turbines are optimized for aero use, but can be used in other specialized roles, being powerful but suffering from poor throttle response and fuel consumption.",
	model = "models/engines/gasturbine_s.mdl",
	sound = "acf_engines/turbine_small.wav",
	category = "Turbine",
	fuel = "Multifuel",
	enginetype = "Turbine",
	requiresfuel = true,
	weight = 200,
	torque = 550,
	flywheelmass = 2.9,
	idlerpm = 1400,
	peakminrpm = 1000,
	peakmaxrpm = 1500,
	limitrpm = 10000,
	iselec = true,
	flywheeloverride = 4167
} )

ACF_DefineEngine( "Turbine-Medium", {
	name = "Gas Turbine, Medium",
	desc = "A medium gas turbine, moderate power but a very wide powerband\n\nThese turbines are optimized for aero use, but can be used in other specialized roles, being powerful but suffering from poor throttle response and fuel consumption.",
	model = "models/engines/gasturbine_m.mdl",
	sound = "acf_engines/turbine_medium.wav",
	category = "Turbine",
	fuel = "Multifuel",
	enginetype = "Turbine",
	requiresfuel = true,
	weight = 400,
	torque = 813,
	flywheelmass = 4.3,
	idlerpm = 1800,
	peakminrpm = 1200,
	peakmaxrpm = 1800,
	limitrpm = 12000,
	iselec = true,
	flywheeloverride = 5000
} )

ACF_DefineEngine( "Turbine-Large", {
	name = "Gas Turbine, Large",
	desc = "A large gas turbine, powerful with a wide powerband\n\nThese turbines are optimized for aero use, but can be used in other specialized roles, being powerful but suffering from poor throttle response and fuel consumption.",
	model = "models/engines/gasturbine_l.mdl",
	sound = "acf_engines/turbine_large.wav",
	category = "Turbine",
	fuel = "Multifuel",
	enginetype = "Turbine",
	requiresfuel = true,
	weight = 1100,
	torque = 1990,
	flywheelmass = 10.5,
	idlerpm = 2000,
	peakminrpm = 1350,
	peakmaxrpm = 2025,
	limitrpm = 13500,
	iselec = true,
	flywheeloverride = 5625
} )

--Forward facing ground turbines

ACF_DefineEngine( "Turbine-Ground-Small", {
	name = "Ground Gas Turbine, Small",
	desc = "A small gas turbine, fitted with ground-use air filters and tuned for ground use.\n\nGround-use turbines have excellent low-rev performance and are deceptively powerful, easily propelling loads that would have equivalent reciprocating engines struggling; however, they have sluggish throttle response, high gearbox demands, high fuel usage, and low tolerance to damage.",
	model = "models/engines/gasturbine_s.mdl",
	sound = "acf_engines/turbine_small.wav",
	category = "Turbine",
	fuel = "Multifuel",
	enginetype = "Radial",
	requiresfuel = true,
	weight = 350,
	torque = 800,
	flywheelmass = 14.3,
	idlerpm = 700,
	peakminrpm = 1000,
	peakmaxrpm = 1350,
	limitrpm = 3000,
	iselec = true,
	flywheeloverride = 1667
} )

ACF_DefineEngine( "Turbine-Ground-Medium", {
	name = "Ground Gas Turbine, Medium",
	desc = "A medium gas turbine, fitted with ground-use air filters and tuned for ground use.\n\nGround-use turbines have excellent low-rev performance and are deceptively powerful, easily propelling loads that would have equivalent reciprocating engines struggling; however, they have sluggish throttle response, high gearbox demands, high fuel usage, and low tolerance to damage.",
	model = "models/engines/gasturbine_m.mdl",
	sound = "acf_engines/turbine_medium.wav",
	category = "Turbine",
	fuel = "Multifuel",
	enginetype = "Radial", --This is done to give proper fuel consumption and make the turbines not instant-torque from idle
	requiresfuel = true,
	weight = 600,
	torque = 1200,
	flywheelmass = 29.6,
	idlerpm = 600,
	peakminrpm = 1500,
	peakmaxrpm = 2000,
	limitrpm = 3000,
	iselec = true,
	flywheeloverride = 1450,
	pitch = 1.15
} )

ACF_DefineEngine( "Turbine-Ground-Large", {
	name = "Ground Gas Turbine, Large",
	desc = "A large gas turbine, fitted with ground-use air filters and tuned for ground use. Doesn't have the sheer power output of an aero gas turbine, but compensates with an imperial fuckload of torque.\n\nGround-use turbines have excellent low-rev performance and are deceptively powerful, easily propelling loads that would have equivalent reciprocating engines struggling; however, they have sluggish throttle response, high gearbox demands, high fuel usage, and low tolerance to damage.",
	model = "models/engines/gasturbine_l.mdl",
	sound = "acf_engines/turbine_large.wav",
	category = "Turbine",
	fuel = "Multifuel",
	enginetype = "Radial",
	requiresfuel = true,
	weight = 1650,
	torque = 4000,
	flywheelmass = 75,
	idlerpm = 500,
	peakminrpm = 1000,
	peakmaxrpm = 1250,
	limitrpm = 3000,
	iselec = true,
	flywheeloverride = 1250,
	pitch = 1.35
} )

--Transaxial Ground Turbines

ACF_DefineEngine( "Turbine-Small-Ground-Trans", {
	name = "Ground Gas Turbine, Small, Transaxial",
	desc = "A small gas turbine, fitted with ground-use air filters and tuned for ground use.\n\nGround-use turbines have excellent low-rev performance and are deceptively powerful, easily propelling loads that would have equivalent reciprocating engines struggling; however, they have sluggish throttle response, high gearbox demands, high fuel usage, and low tolerance to damage.  Outputs to the side instead of rear.",
	model = "models/engines/turbine_s.mdl",
	sound = "acf_engines/turbine_small.wav",
	category = "Turbine",
	fuel = "Multifuel",
	enginetype = "Radial",
	requiresfuel = true,
	weight = 280,
	torque = 600,
	flywheelmass = 11.4,
	idlerpm = 700,
	peakminrpm = 1000,
	peakmaxrpm = 1350,
	limitrpm = 3000,
	iselec = true,
	istrans = true,
	flywheeloverride = 1667
} )

ACF_DefineEngine( "Turbine-Medium-Ground-Trans", {
	name = "Ground Gas Turbine, Medium, Transaxial",
	desc = "A medium gas turbine, fitted with ground-use air filters and tuned for ground use.\n\nGround-use turbines have excellent low-rev performance and are deceptively powerful, easily propelling loads that would have equivalent reciprocating engines struggling; however, they have sluggish throttle response, high gearbox demands, high fuel usage, and low tolerance to damage.  Outputs to the side instead of rear.",
	model = "models/engines/turbine_m.mdl",
	sound = "acf_engines/turbine_medium.wav",
	category = "Turbine",
	fuel = "Multifuel",
	enginetype = "Radial",
	requiresfuel = true,
	weight = 480,
	torque = 900,
	flywheelmass = 23.7,
	idlerpm = 600,
	peakminrpm = 1500,
	peakmaxrpm = 2000,
	limitrpm = 3000,
	iselec = true,
	istrans = true,
	flywheeloverride = 1450,
	pitch = 1.15
} )

ACF_DefineEngine( "Turbine-Large-Ground-Trans", {
	name = "Ground Gas Turbine, Large, Transaxial",
	desc = "A large gas turbine, fitted with ground-use air filters and tuned for ground use.  Doesn't have the sheer power output of an aero gas turbine, but compensates with an imperial fuckload of torque.\n\nGround-use turbines have excellent low-rev performance and are deceptively powerful, easily propelling loads that would have equivalent reciprocating engines struggling; however, they have sluggish throttle response, high gearbox demands, high fuel usage, and low tolerance to damage.  Outputs to the side instead of rear.",
	model = "models/engines/turbine_l.mdl",
	sound = "acf_engines/turbine_large.wav",
	category = "Turbine",
	fuel = "Multifuel",
	enginetype = "Radial",
	requiresfuel = true,
	weight = 1320,
	torque = 3000,
	flywheelmass = 60,
	idlerpm = 500,
	peakminrpm = 1000,
	peakmaxrpm = 1250,
	limitrpm = 3000,
	iselec = true,
	istrans = true,
	flywheeloverride = 1250,
	pitch = 1.35
} )


