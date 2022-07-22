local ACF     = ACF
local Engines = ACF.Classes.Engines


Engines.Register("I3", {
	Name = "Inline 3 Engine",
})

do -- Petrol Engines
	Engines.RegisterItem("1.2-I3", "I3", {
		Name		 = "1.2L I3 Petrol",
		Description	 = "Tiny microcar engine, efficient but weak.",
		Model		 = "models/engines/inline3s.mdl",
		Sound		 = "acf_base/engines/i4_petrolsmall2.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 40,
		Torque		 = 118,
		FlywheelMass = 0.05,
		RPM = {
			Idle	= 1100,
			Limit	= 6000,
		},
		Preview = {
			FOV = 125,
		},
	})

	Engines.RegisterItem("3.4-I3", "I3", {
		Name		 = "3.4L I3 Petrol",
		Description	 = "Short block engine for light utility use.",
		Model		 = "models/engines/inline3m.mdl",
		Sound		 = "acf_base/engines/i4_petrolmedium2.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 170,
		Torque		 = 243,
		FlywheelMass = 0.2,
		RPM = {
			Idle	= 900,
			Limit	= 6800,
		},
		Preview = {
			FOV = 125,
		},
	})

	Engines.RegisterItem("13.5-I3", "I3", {
		Name		 = "13.5L I3 Petrol",
		Description	 = "Short block light tank engine, likes sideways mountings.",
		Model		 = "models/engines/inline3b.mdl",
		Sound		 = "acf_base/engines/i4_petrollarge.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 500,
		Torque		 = 893,
		FlywheelMass = 3.7,
		RPM = {
			Idle	= 500,
			Limit	= 3900,
		},
		Preview = {
			FOV = 125,
		},
	})
end

do -- Diesel Engines
	Engines.RegisterItem("1.1-I3", "I3", {
		Name		 = "1.1L I3 Diesel",
		Description	 = "ATV grade 3-banger, enormous rev band but a choppy idle, great for light utility work.",
		Model		 = "models/engines/inline3s.mdl",
		Sound		 = "acf_base/engines/i4_diesel2.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 65,
		Torque		 = 187,
		FlywheelMass = 0.2,
		RPM = {
			Idle	= 550,
			Limit	= 3000,
		},
		Preview = {
			FOV = 125,
		},
	})

	Engines.RegisterItem("2.8-I3", "I3", {
		Name		 = "2.8L I3 Diesel",
		Description	 = "Medium utility grade I3 diesel, for tractors",
		Model		 = "models/engines/inline3m.mdl",
		Sound		 = "acf_base/engines/i4_dieselmedium.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 200,
		Torque		 = 362,
		FlywheelMass = 1,
		RPM = {
			Idle	= 600,
			Limit	= 3800
		},
		Preview = {
			FOV = 125,
		},
	})

	Engines.RegisterItem("11.0-I3", "I3", {
		Name		 = "11.0L I3 Diesel",
		Description	 = "Light tank duty engine, compact yet grunts hard.",
		Model		 = "models/engines/inline3b.mdl",
		Sound		 = "acf_base/engines/i4_diesellarge.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 650,
		Torque		 = 1500,
		FlywheelMass = 5,
		RPM = {
			Idle	= 550,
			Limit	= 2000
		},
		Preview = {
			FOV = 125,
		},
	})
end

ACF.SetCustomAttachment("models/engines/inline3b.mdl", "driveshaft", Vector(-15, 0, 11), Angle(0, 180, 90))
ACF.SetCustomAttachment("models/engines/inline3m.mdl", "driveshaft", Vector(-9, 0, 6.6), Angle(0, 180, 90))
ACF.SetCustomAttachment("models/engines/inline3s.mdl", "driveshaft", Vector(-6, 0, 4.4), Angle(0, 180, 90))

local Models = {
	{ Model = "models/engines/inline3b.mdl", Scale = 2.5 },
	{ Model = "models/engines/inline3m.mdl", Scale = 1.5 },
	{ Model = "models/engines/inline3s.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Shaft = {
			Pos       = Vector(0.5, 0, 4.75) * Scale,
			Scale     = Vector(18.5, 8, 9) * Scale,
			Sensitive = true
		},
		Pistons = {
			Pos   = Vector(1, 0.25, 13.25) * Scale,
			Scale = Vector(14, 5.5, 8) * Scale
		}
	})
end
