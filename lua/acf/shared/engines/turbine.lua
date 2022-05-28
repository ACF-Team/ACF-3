
-- Gas turbines

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
		Torque		 = 589,
		FlywheelMass = 2.9,
		IsElectric	 = true,
		RPM = {
			Idle	 = 1400,
			Limit	 = 14000,
			Override = 4167,
		},
		Preview = {
			FOV = 100,
		},
	})

	ACF.RegisterEngine("Turbine-Medium", "GT", {
		Name		 = "Medium Gas Turbine",
		Description	 = "A medium gas turbine, moderate power but a very wide powerband.",
		Model		 = "models/engines/gasturbine_m.mdl",
		Sound		 = "acf_base/engines/turbine_medium.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "Turbine",
		Mass		 = 400,
		Torque		 = 1312,
		FlywheelMass = 4.3,
		IsElectric	 = true,
		RPM = {
			Idle	 = 1800,
			Limit	 = 12000,
			Override = 5000,
		},
		Preview = {
			FOV = 100,
		},
	})

	ACF.RegisterEngine("Turbine-Large", "GT", {
		Name		 = "Large Gas Turbine",
		Description	 = "A large gas turbine, powerful with a wide powerband.",
		Model		 = "models/engines/gasturbine_l.mdl",
		Sound		 = "acf_base/engines/turbine_large.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "Turbine",
		Mass		 = 1100,
		Torque		 = 2500,
		FlywheelMass = 10.5,
		IsElectric	 = true,
		RPM = {
			Idle	 = 2000,
			Limit	 = 13000,
			Override = 5625,
		},
		Preview = {
			FOV = 100,
		},
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
		Torque		 = 387,
		FlywheelMass = 2.3,
		IsElectric	 = true,
		IsTrans		 = true,
		RPM = {
			Idle	 = 1400,
			Limit	 = 12000,
			Override = 4167,
		},
		Preview = {
			FOV = 75,
		},
	})

	ACF.RegisterEngine("Turbine-Medium-Trans", "GT", {
		Name		 = "Medium Transaxial Gas Turbine",
		Description	 = "A medium gas turbine, moderate power but a very wide powerband. Outputs to the side instead of rear.",
		Model		 = "models/engines/turbine_m.mdl",
		Sound		 = "acf_base/engines/turbine_medium.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "Turbine",
		Mass		 = 320,
		Torque		 = 750,
		FlywheelMass = 3.4,
		IsElectric	 = true,
		IsTrans		 = true,
		RPM = {
			Idle	 = 1800,
			Limit	 = 12000,
			Override = 5000,
		},
		Preview = {
			FOV = 75,
		},
	})

	ACF.RegisterEngine("Turbine-Large-Trans", "GT", {
		Name		 = "Large Transaxial Gas Turbine",
		Description	 = "A large gas turbine, powerful with a wide powerband. Outputs to the side instead of rear.",
		Model		 = "models/engines/turbine_l.mdl",
		Sound		 = "acf_base/engines/turbine_large.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "Turbine",
		Mass		 = 880,
		Torque		 = 1710,
		FlywheelMass = 8.4,
		IsElectric	 = true,
		IsTrans		 = true,
		RPM = {
			Idle	 = 2000,
			Limit	 = 10000,
			Override = 5625,
		},
		Preview = {
			FOV = 75,
		},
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
		Type		 = "Turbine",
		Mass		 = 350,
		Torque		 = 990,
		FlywheelMass = 14.3,
		IsElectric	 = true,
		RPM = {
			Idle	 = 700,
			Limit	 = 4000,
			Override = 1667,
		},
		Preview = {
			FOV = 100,
		},
	})

	ACF.RegisterEngine("Turbine-Ground-Medium", "GGT", {
		Name		 = "Medium Ground Gas Turbine",
		Description	 = "A medium gas turbine, fitted with ground-use air filters and tuned for ground use.",
		Model		 = "models/engines/gasturbine_m.mdl",
		Sound		 = "acf_base/engines/turbine_medium.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "Turbine",
		Mass		 = 600,
		Torque		 = 1970,
		FlywheelMass = 29.6,
		IsElectric	 = true,
		Pitch		 = 1.15,
		RPM = {
			Idle	 = 600,
			Limit	 = 4000,
			Override = 1450,
		},
		Preview = {
			FOV = 100,
		},
	})

	ACF.RegisterEngine("Turbine-Ground-Large", "GGT", {
		Name		 = "Large Ground Gas Turbine",
		Description	 = "A large gas turbine, fitted with ground-use air filters and tuned for ground use.",
		Model		 = "models/engines/gasturbine_l.mdl",
		Sound		 = "acf_base/engines/turbine_large.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "Turbine",
		Mass		 = 1650,
		Torque		 = 5000,
		FlywheelMass = 75,
		IsElectric	 = true,
		Pitch		 = 1.35,
		RPM = {
			Idle	 = 500,
			Limit	 = 3250,
			Override = 1250,
		},
		Preview = {
			FOV = 100,
		},
	})
end

do -- Transaxial Ground Gas Turbines
	ACF.RegisterEngine("Turbine-Small-Ground-Trans", "GGT", {
		Name		 = "Small Transaxial Ground Gas Turbine",
		Description	 = "A small gas turbine fitted with ground-use air filters and tuned for ground use. Outputs to the side instead of rear.",
		Model		 = "models/engines/turbine_s.mdl",
		Sound		 = "acf_base/engines/turbine_small.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "Turbine",
		Mass		 = 280,
		Torque		 = 550,
		FlywheelMass = 11.4,
		IsElectric	 = true,
		IsTrans		 = true,
		RPM = {
			Idle	 = 700,
			Limit	 = 4000,
			Override = 1667,
		},
		Preview = {
			FOV = 75,
		},
	})

	ACF.RegisterEngine("Turbine-Medium-Ground-Trans", "GGT", {
		Name		 = "Medium Transaxial Ground Gas Turbine",
		Description	 = "A medium gas turbine fitted with ground-use air filters and tuned for ground use. Outputs to the side instead of rear.",
		Model		 = "models/engines/turbine_m.mdl",
		Sound		 = "acf_base/engines/turbine_medium.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "Turbine",
		Mass		 = 480,
		Torque		 = 1123,
		FlywheelMass = 23.7,
		IsElectric	 = true,
		IsTrans		 = true,
		Pitch		 = 1.15,
		RPM = {
			Idle	 = 600,
			Limit	 = 4000,
			Override = 1450,
		},
		Preview = {
			FOV = 75,
		},
	})

	ACF.RegisterEngine("Turbine-Large-Ground-Trans", "GGT", {
		Name		 = "Large Transaxial Ground Gas Turbine",
		Description	 = "A large gas turbine fitted with ground-use air filters and tuned for ground use. Outputs to the side instead of rear.",
		Model		 = "models/engines/turbine_l.mdl",
		Sound		 = "acf_base/engines/turbine_large.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "Turbine",
		Mass		 = 1320,
		Torque		 = 2760,
		FlywheelMass = 60,
		IsElectric	 = true,
		IsTrans		 = true,
		Pitch		 = 1.35,
		RPM = {
			Idle	 = 500,
			Limit	 = 3250,
			Override = 1250,
		},
		Preview = {
			FOV = 75,
		},
	})
end

ACF.SetCustomAttachment("models/engines/turbine_l.mdl", "driveshaft", Vector(0, -15), Angle(0, -90))
ACF.SetCustomAttachment("models/engines/turbine_m.mdl", "driveshaft", Vector(0, -11.25), Angle(0, -90))
ACF.SetCustomAttachment("models/engines/turbine_s.mdl", "driveshaft", Vector(0, -7.5), Angle(0, -90))
ACF.SetCustomAttachment("models/engines/gasturbine_l.mdl", "driveshaft", Vector(-42), Angle(0, -180))
ACF.SetCustomAttachment("models/engines/gasturbine_m.mdl", "driveshaft", Vector(-31.5), Angle(0, -180))
ACF.SetCustomAttachment("models/engines/gasturbine_s.mdl", "driveshaft", Vector(-21), Angle(0, -180))

local Straight = {
	{ Model = "models/engines/turbine_l.mdl", Scale = 2 },
	{ Model = "models/engines/turbine_m.mdl", Scale = 1.5 },
	{ Model = "models/engines/turbine_s.mdl", Scale = 1 },
}

local Transaxial = {
	{ Model = "models/engines/gasturbine_l.mdl", Scale = 2 },
	{ Model = "models/engines/gasturbine_m.mdl", Scale = 1.5 },
	{ Model = "models/engines/gasturbine_s.mdl", Scale = 1 },
}

for _, Data in ipairs(Straight) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Main = {
			Pos       = Vector(2) * Scale,
			Scale     = Vector(26, 11, 11) * Scale,
			Sensitive = true
		},
		Intake = {
			Pos   = Vector(20) * Scale,
			Scale = Vector(10, 15, 15) * Scale
		},
		Output = {
			Pos   = Vector(-16, 0, 4) * Scale,
			Scale = Vector(10, 15, 24) * Scale
		}
	})
end

for _, Data in ipairs(Transaxial) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Main = {
			Pos   = Vector(6) * Scale,
			Scale = Vector(22, 10, 10) * Scale,
			Sensitive = true
		},
		Intake = {
			Pos   = Vector(19.5) * Scale,
			Scale = Vector(5, 12, 12) * Scale
		},
		Chamber = {
			Pos   = Vector(-9.5) * Scale,
			Scale = Vector(9, 13, 13) * Scale
		},
		Output = {
			Pos   = Vector(0, -6.5) * Scale,
			Scale = Vector(7, 3, 7) * Scale
		},
		Exhaust = {
			Pos   = Vector(-19) * Scale,
			Scale = Vector(10, 10, 10) * Scale
		}
	})
end
