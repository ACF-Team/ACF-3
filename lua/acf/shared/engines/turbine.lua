
-- Gas turbines

ACF_DefineEngine( "Turbine-Small-Trans", {
	name = "Gas Turbine, Small, Transaxial",
	desc = "A small gas turbine, high power and a very wide powerband\n\nThese turbines are optimized for aero use, but can be used in other specialized roles, being powerful but suffering from poor throttle response and fuel consumption.\n\nOutputs to the side instead of rear.",
	model = "models/engines/turbine_s.mdl",
	sound = "acf_base/engines/turbine_small.wav",
	category = "Turbine",
	fuel = "Multifuel",
	enginetype = "Turbine",
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
	sound = "acf_base/engines/turbine_medium.wav",
	category = "Turbine",
	fuel = "Multifuel",
	enginetype = "Turbine",
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
	sound = "acf_base/engines/turbine_large.wav",
	category = "Turbine",
	fuel = "Multifuel",
	enginetype = "Turbine",
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
	sound = "acf_base/engines/turbine_small.wav",
	category = "Turbine",
	fuel = "Multifuel",
	enginetype = "Turbine",
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
	sound = "acf_base/engines/turbine_medium.wav",
	category = "Turbine",
	fuel = "Multifuel",
	enginetype = "Turbine",
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
	sound = "acf_base/engines/turbine_large.wav",
	category = "Turbine",
	fuel = "Multifuel",
	enginetype = "Turbine",
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
	sound = "acf_base/engines/turbine_small.wav",
	category = "Turbine",
	fuel = "Multifuel",
	enginetype = "Radial",
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
	sound = "acf_base/engines/turbine_medium.wav",
	category = "Turbine",
	fuel = "Multifuel",
	enginetype = "Radial", --This is done to give proper fuel consumption and make the turbines not instant-torque from idle
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
	sound = "acf_base/engines/turbine_large.wav",
	category = "Turbine",
	fuel = "Multifuel",
	enginetype = "Radial",
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
	sound = "acf_base/engines/turbine_small.wav",
	category = "Turbine",
	fuel = "Multifuel",
	enginetype = "Radial",
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
	sound = "acf_base/engines/turbine_medium.wav",
	category = "Turbine",
	fuel = "Multifuel",
	enginetype = "Radial",
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
	sound = "acf_base/engines/turbine_large.wav",
	category = "Turbine",
	fuel = "Multifuel",
	enginetype = "Radial",
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

ACF.RegisterEngineClass("GT", {
	Name		= "Gas Turbine",
	Description	= "These turbines are optimized for aero use due to them being powerful but suffering from poor throttle response and fuel consumption."
})

do -- Forward-facing Gas Turbines
	ACF.RegisterEngine("Turbine-Small", "GT", {
		Name		 = "Small Gas Turbine",
		Description	 = "A small gas turbine, high power and a very wide powerband.",
		Model		 = "models/engines/gasturbine_s.mdl",
		Sound		 = "acf_base/engines/turbine_small.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "Turbine",
		Mass		 = 200,
		Torque		 = 550,
		FlywheelMass = 2.9,
		RequiresFuel = true,
		IsElectric	 = true,
		RPM = {
			Idle	 = 1400,
			PeakMin	 = 1000,
			PeakMax	 = 1500,
			Limit	 = 10000,
			Override = 4167,
		}
	})

	ACF.RegisterEngine("Turbine-Medium", "GT", {
		Name		 = "Medium Gas Turbine",
		Description	 = "A medium gas turbine, moderate power but a very wide powerband.",
		Model		 = "models/engines/gasturbine_m.mdl",
		Sound		 = "acf_base/engines/turbine_medium.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "Turbine",
		Mass		 = 400,
		Torque		 = 813,
		FlywheelMass = 4.3,
		RequiresFuel = true,
		IsElectric	 = true,
		RPM = {
			Idle	 = 1800,
			PeakMin	 = 1200,
			PeakMax	 = 1800,
			Limit	 = 12000,
			Override = 5000,
		}
	})

	ACF.RegisterEngine("Turbine-Large", "GT", {
		Name		 = "Large Gas Turbine",
		Description	 = "A large gas turbine, powerful with a wide powerband.",
		Model		 = "models/engines/gasturbine_l.mdl",
		Sound		 = "acf_base/engines/turbine_large.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "Turbine",
		Mass		 = 1100,
		Torque		 = 1990,
		FlywheelMass = 10.5,
		RequiresFuel = true,
		IsElectric	 = true,
		RPM = {
			Idle	 = 2000,
			PeakMin	 = 1350,
			PeakMax	 = 2025,
			Limit	 = 13500,
			Override = 5625,
		}
	})
end

do -- Transaxial Gas Turbines
	ACF.RegisterEngine("Turbine-Small-Trans", "GT", {
		Name		 = "Small Transaxial Gas Turbine",
		Description	 = "A small gas turbine, high power and a very wide powerband. Outputs to the side instead of rear.",
		Model		 = "models/engines/turbine_s.mdl",
		Sound		 = "acf_base/engines/turbine_small.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "Turbine",
		Mass		 = 160,
		Torque		 = 440,
		FlywheelMass = 2.3,
		RequiresFuel = true,
		IsElectric	 = true,
		IsTrans		 = true,
		RPM = {
			Idle	 = 1400,
			PeakMin	 = 1000,
			PeakMax	 = 1500,
			Limit	 = 10000,
			Override = 4167,
		}
	})

	ACF.RegisterEngine("Turbine-Medium-Trans", "GT", {
		Name		 = "Medium Transaxial Gas Turbine",
		Description	 = "A medium gas turbine, moderate power but a very wide powerband. Outputs to the side instead of rear.",
		Model		 = "models/engines/turbine_m.mdl",
		Sound		 = "acf_base/engines/turbine_medium.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "Turbine",
		Mass		 = 320,
		Torque		 = 650,
		FlywheelMass = 3.4,
		RequiresFuel = true,
		IsElectric	 = true,
		IsTrans		 = true,
		RPM = {
			Idle	 = 1800,
			PeakMin	 = 1200,
			PeakMax	 = 1800,
			Limit	 = 12000,
			Override = 5000,
		}
	})

	ACF.RegisterEngine("Turbine-Large-Trans", "GT", {
		Name		 = "Large Transaxial Gas Turbine",
		Description	 = "A large gas turbine, powerful with a wide powerband. Outputs to the side instead of rear.",
		Model		 = "models/engines/turbine_l.mdl",
		Sound		 = "acf_base/engines/turbine_large.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "Turbine",
		Mass		 = 880,
		Torque		 = 1592,
		FlywheelMass = 8.4,
		RequiresFuel = true,
		IsElectric	 = true,
		IsTrans		 = true,
		RPM = {
			Idle	 = 2000,
			PeakMin	 = 1350,
			PeakMax	 = 2025,
			Limit	 = 13500,
			Override = 5625,
		}
	})
end

ACF.RegisterEngineClass("GGT", {
	Name		= "Ground Gas Turbine",
	Description	= "Ground-use turbines have excellent low-rev performance and are deceptively powerful. However, they have high gearbox demands, high fuel usage and low tolerance to damage."
})

do -- Forward-facing Ground Gas Turbines
	ACF.RegisterEngine("Turbine-Ground-Small", "GGT", {
		Name		 = "Small Ground Gas Turbine",
		Description	 = "A small gas turbine, fitted with ground-use air filters and tuned for ground use.",
		Model		 = "models/engines/gasturbine_s.mdl",
		Sound		 = "acf_base/engines/turbine_small.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "Radial",
		Mass		 = 350,
		Torque		 = 800,
		FlywheelMass = 14.3,
		RequiresFuel = true,
		IsElectric	 = true,
		RPM = {
			Idle	 = 700,
			PeakMin	 = 1000,
			PeakMax	 = 1350,
			Limit	 = 3000,
			Override = 1667,
		}
	})

	ACF.RegisterEngine("Turbine-Ground-Medium", "GGT", {
		Name		 = "Medium Ground Gas Turbine",
		Description	 = "A medium gas turbine, fitted with ground-use air filters and tuned for ground use.",
		Model		 = "models/engines/gasturbine_m.mdl",
		Sound		 = "acf_base/engines/turbine_medium.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "Radial", --This is done to give proper fuel consumption and make the turbines not instant-torque from idle
		Mass		 = 600,
		Torque		 = 1200,
		FlywheelMass = 29.6,
		RequiresFuel = true,
		IsElectric	 = true,
		Pitch		 = 1.15,
		RPM = {
			Idle	 = 600,
			PeakMin	 = 1500,
			PeakMax	 = 2000,
			Limit	 = 3000,
			Override = 1450,
		}
	})

	ACF.RegisterEngine("Turbine-Ground-Large", "GGT", {
		Name		 = "Large Ground Gas Turbine",
		Description	 = "A large gas turbine, fitted with ground-use air filters and tuned for ground use.",
		Model		 = "models/engines/gasturbine_l.mdl",
		Sound		 = "acf_base/engines/turbine_large.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "Radial",
		Mass		 = 1650,
		Torque		 = 4000,
		FlywheelMass = 75,
		RequiresFuel = true,
		IsElectric	 = true,
		Pitch		 = 1.35,
		RPM = {
			Idle	 = 500,
			PeakMin	 = 1000,
			PeakMax	 = 1250,
			Limit	 = 3000,
			Override = 1250,
		}
	})
end

do -- Transaxial Ground Gas Turbines
	ACF.RegisterEngine("Turbine-Small-Ground-Trans", "GGT", {
		Name		 = "Small Transaxial Ground Gas Turbine",
		Description	 = "A small gas turbine fitted with ground-use air filters and tuned for ground use. Outputs to the side instead of rear.",
		Model		 = "models/engines/turbine_s.mdl",
		Sound		 = "acf_base/engines/turbine_small.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "Radial",
		Mass		 = 280,
		Torque		 = 600,
		FlywheelMass = 11.4,
		RequiresFuel = true,
		IsElectric	 = true,
		IsTrans		 = true,
		RPM = {
			Idle	 = 700,
			PeakMin	 = 1000,
			PeakMax	 = 1350,
			Limit	 = 3000,
			Override = 1667,
		}
	})

	ACF.RegisterEngine("Turbine-Medium-Ground-Trans", "GGT", {
		Name		 = "Medium Transaxial Ground Gas Turbine",
		Description	 = "A medium gas turbine fitted with ground-use air filters and tuned for ground use. Outputs to the side instead of rear.",
		Model		 = "models/engines/turbine_m.mdl",
		Sound		 = "acf_base/engines/turbine_medium.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "Radial",
		Mass		 = 480,
		Torque		 = 900,
		FlywheelMass = 23.7,
		RequiresFuel = true,
		IsElectric	 = true,
		IsTrans		 = true,
		Pitch		 = 1.15,
		RPM = {
			Idle	 = 600,
			PeakMin	 = 1500,
			PeakMax	 = 2000,
			Limit	 = 3000,
			Override = 1450,
		}
	})

	ACF.RegisterEngine("Turbine-Large-Ground-Trans", "GGT", {
		Name		 = "Large Transaxial Ground Gas Turbine",
		Description	 = "A large gas turbine fitted with ground-use air filters and tuned for ground use. Outputs to the side instead of rear.",
		Model		 = "models/engines/turbine_l.mdl",
		Sound		 = "acf_base/engines/turbine_large.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "Radial",
		Mass		 = 1320,
		Torque		 = 3000,
		FlywheelMass = 60,
		RequiresFuel = true,
		IsElectric	 = true,
		IsTrans		 = true,
		Pitch		 = 1.35,
		RPM = {
			Idle	 = 500,
			PeakMin	 = 1000,
			PeakMax	 = 1250,
			Limit	 = 3000,
			Override = 1250,
		}
	})
end
