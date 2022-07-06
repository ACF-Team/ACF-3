local ACF     = ACF
local Engines = ACF.Classes.Engines


Engines.Register("I6", {
	Name = "Inline 6 Engine",
})

do -- Petrol Engines
	Engines.RegisterItem("2.2-I6", "I6", {
		Name		 = "2.2L I6 Petrol",
		Description	 = "Car sized I6 petrol with power in the high revs.",
		Model		 = "models/engines/inline6s.mdl",
		Sound		 = "acf_base/engines/l6_petrolsmall2.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 120,
		Torque		 = 169,
		FlywheelMass = 0.1,
		RPM = {
			Idle	= 800,
			Limit	= 7500,
		},
		Preview = {
			FOV = 112,
		},
	})

	Engines.RegisterItem("4.8-I6", "I6", {
		Name		 = "4.8L I6 Petrol",
		Description	 = "Light truck duty I6, good for offroad applications.",
		Model		 = "models/engines/inline6m.mdl",
		Sound		 = "acf_base/engines/l6_petrolmedium.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 300,
		Torque		 = 460,
		FlywheelMass = 0.2,
		RPM = {
			Idle	= 900,
			Limit	= 5500,
		},
		Preview = {
			FOV = 112,
		},
	})

	Engines.RegisterItem("17.2-I6", "I6", {
		Name		 = "17.2L I6 Petrol",
		Description	 = "Heavy tractor duty petrol I6, decent overall powerband.",
		Model		 = "models/engines/inline6l.mdl",
		Sound		 = "acf_base/engines/l6_petrollarge2.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 850,
		Torque		 = 1760,
		FlywheelMass = 2.5,
		RPM = {
			Idle	= 800,
			Limit	= 2700,
		},
		Preview = {
			FOV = 112,
		},
	})
end

do -- Diesel Engines
	Engines.RegisterItem("3.0-I6", "I6", {
		Name		 = "3.0L I6 Diesel",
		Description	 = "Car sized I6 diesel, good, wide powerband.",
		Model		 = "models/engines/inline6s.mdl",
		Sound		 = "acf_base/engines/l6_dieselsmall.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 150,
		Torque		 = 250,
		FlywheelMass = 0.5,
		RPM = {
			Idle	= 650,
			Limit	= 4900,
		},
		Preview = {
			FOV = 112,
		},
	})

	Engines.RegisterItem("6.5-I6", "I6", {
		Name		 = "6.5L I6 Diesel",
		Description	 = "Truck duty I6, good overall powerband and torque.",
		Model		 = "models/engines/inline6m.mdl",
		Sound		 = "acf_base/engines/l6_dieselmedium4.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 450,
		Torque		 = 700,
		FlywheelMass = 1.5,
		RPM = {
			Idle	= 600,
			Limit	= 4000,
		},
		Preview = {
			FOV = 112,
		},
	})

	Engines.RegisterItem("20.0-I6", "I6", {
		Name		 = "20.0L I6 Diesel",
		Description	 = "Heavy duty diesel I6, used in generators and heavy movers.",
		Model		 = "models/engines/inline6l.mdl",
		Sound		 = "acf_base/engines/l6_diesellarge2.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 1200,
		Torque		 = 2490,
		FlywheelMass = 8,
		RPM = {
			Idle	= 400,
			Limit	= 2350,
		},
		Preview = {
			FOV = 112,
		},
	})
end

ACF.SetCustomAttachment("models/engines/inline6l.mdl", "driveshaft", Vector(-30, 0, 11), Angle(0, 180, 90))
ACF.SetCustomAttachment("models/engines/inline6m.mdl", "driveshaft", Vector(-18, 0, 6.6), Angle(0, 180, 90))
ACF.SetCustomAttachment("models/engines/inline6s.mdl", "driveshaft", Vector(-12, 0, 4.4), Angle(0, 180, 90))

local Models = {
	{ Model = "models/engines/inline6l.mdl", Scale = 2.5 },
	{ Model = "models/engines/inline6m.mdl", Scale = 1.5 },
	{ Model = "models/engines/inline6s.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Shaft = {
			Pos       = Vector(0.5, 0, 4.75) * Scale,
			Scale     = Vector(32, 7.5, 9) * Scale,
			Sensitive = true
		},
		Pistons = {
			Pos   = Vector(1.25, 0, 13.5) * Scale,
			Scale = Vector(27, 5.25, 8.5) * Scale
		}
	})
end
