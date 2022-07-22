local ACF     = ACF
local Engines = ACF.Classes.Engines


Engines.Register("I4", {
	Name = "Inline 4 Engine",
})

do -- Petrol Engines
	Engines.RegisterItem("1.5-I4", "I4", {
		Name		 = "1.5L I4 Petrol",
		Description	 = "Small car engine, not a whole lot of git.",
		Model		 = "models/engines/inline4s.mdl",
		Sound		 = "acf_base/engines/i4_petrolsmall2.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 50,
		Torque		 = 119,
		FlywheelMass = 0.06,
		RPM = {
			Idle	= 900,
			Limit	= 8000,
		},
		Preview = {
			FOV = 120,
		},
	})

	Engines.RegisterItem("3.7-I4", "I4", {
		Name		 = "3.7L I4 Petrol",
		Description	 = "Large inline 4, sees most use in light trucks.",
		Model		 = "models/engines/inline4m.mdl",
		Sound		 = "acf_base/engines/i4_petrolmedium2.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 200,
		Torque		 = 305,
		FlywheelMass = 0.2,
		RPM = {
			Idle	= 900,
			Limit	= 6500
		},
		Preview = {
			FOV = 120,
		},
	})

	Engines.RegisterItem("16.0-I4", "I4", {
		Name		 = "16.0L I4 Petrol",
		Description	 = "Giant, thirsty I4 petrol, most commonly used in boats.",
		Model		 = "models/engines/inline4l.mdl",
		Sound		 = "acf_base/engines/i4_petrollarge.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 600,
		Torque		 = 1165,
		FlywheelMass = 4,
		RPM = {
			Idle	= 500,
			Limit	= 3400,
		},
		Preview = {
			FOV = 120,
		},
	})
end

do -- Diesel Engines
	Engines.RegisterItem("1.6-I4", "I4", {
		Name		 = "1.6L I4 Diesel",
		Description	 = "Small and light diesel, for low power applications requiring a wide powerband.",
		Model		 = "models/engines/inline4s.mdl",
		Sound		 = "acf_base/engines/i4_diesel2.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 90,
		Torque		 = 184,
		FlywheelMass = 0.2,
		RPM = {
			Idle	= 650,
			Limit	= 5000,
		},
		Preview = {
			FOV = 120,
		},
	})

	Engines.RegisterItem("3.1-I4", "I4", {
		Name		 = "3.1L I4 Diesel",
		Description	 = "Light truck duty diesel, good overall grunt.",
		Model		 = "models/engines/inline4m.mdl",
		Sound		 = "acf_base/engines/i4_dieselmedium.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 250,
		Torque		 = 510,
		FlywheelMass = 1,
		RPM = {
			Idle	= 500,
			Limit	= 4000,
		},
		Preview = {
			FOV = 120,
		},
	})

	Engines.RegisterItem("15.0-I4", "I4", {
		Name		 = "15.0L I4 Diesel",
		Description	 = "Small boat sized diesel, with large amounts of torque.",
		Model		 = "models/engines/inline4l.mdl",
		Sound		 = "acf_base/engines/i4_diesellarge.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 800,
		Torque		 = 2060,
		FlywheelMass = 5,
		RPM = {
			Idle	= 450,
			Limit	= 2100,
		},
		Preview = {
			FOV = 120,
		},
	})
end

ACF.SetCustomAttachment("models/engines/inline4l.mdl", "driveshaft", Vector(-15, 0, 10), Angle(0, 180, 90))
ACF.SetCustomAttachment("models/engines/inline4m.mdl", "driveshaft", Vector(-9, 0, 6), Angle(0, 180, 90))
ACF.SetCustomAttachment("models/engines/inline4s.mdl", "driveshaft", Vector(-6, 0, 4), Angle(0, 180, 90))

local Models = {
	{ Model = "models/engines/inline4l.mdl", Scale = 2.5 },
	{ Model = "models/engines/inline4m.mdl", Scale = 1.5 },
	{ Model = "models/engines/inline4s.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Shaft = {
			Pos       = Vector(0.5, 0, 4.75) * Scale,
			Scale     = Vector(23, 7.5, 9) * Scale,
			Sensitive = true
		},
		Pistons = {
			Pos   = Vector(1.25, 0, 13.25) * Scale,
			Scale = Vector(18.25, 5.25, 8) * Scale
		}
	})
end
