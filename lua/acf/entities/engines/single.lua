local ACF     = ACF
local Engines = ACF.Classes.Engines


Engines.Register("I1", {
	Name = "Single Cylinder Engine",
})

do
	Engines.RegisterItem("0.25-I1", "I1", {
		Name		 = "250cc Single Cylinder",
		Description	 = "Tiny bike engine.",
		Model		 = "models/engines/1cylsml.mdl",
		Sound		 = "acf_base/engines/i1_small.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 15,
		Torque		 = 25,
		FlywheelMass = 0.005,
		RPM = {
			Idle	= 1200,
			Limit	= 7500,
		},
		Preview = {
			FOV = 125,
		},
	})

	Engines.RegisterItem("0.5-I1", "I1", {
		Name		 = "500cc Single Cylinder",
		Description	 = "Large single cylinder bike engine.",
		Model		 = "models/engines/1cylmed.mdl",
		Sound		 = "acf_base/engines/i1_medium.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 20,
		Torque		 = 50,
		FlywheelMass = 0.005,
		RPM = {
			Idle	= 900,
			Limit	= 8000,
		},
		Preview = {
			FOV = 125,
		},
	})

	Engines.RegisterItem("1.3-I1", "I1", {
		Name		 = "1300cc Single Cylinder",
		Description	 = "Ridiculously large single cylinder engine, seriously what the fuck.",
		Model		 = "models/engines/1cylbig.mdl",
		Sound		 = "acf_base/engines/i1_large.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 50,
		Torque		 = 112,
		FlywheelMass = 0.1,
		RPM = {
			Idle	= 600,
			Limit	= 6700,
		},
		Preview = {
			FOV = 125,
		},
	})
end

ACF.SetCustomAttachment("models/engines/1cylbig.mdl", "driveshaft", Vector(), Angle(0, -90, 90))
ACF.SetCustomAttachment("models/engines/1cylmed.mdl", "driveshaft", Vector(), Angle(0, -90, 90))
ACF.SetCustomAttachment("models/engines/1cylsml.mdl", "driveshaft", Vector(), Angle(0, -90, 90))

local Models = {
	{ Model = "models/engines/1cylbig.mdl", Scale = 1.69 },
	{ Model = "models/engines/1cylmed.mdl", Scale = 1.35 },
	{ Model = "models/engines/1cylsml.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Shaft = {
			Pos       = Vector(4, 0, 0) * Scale,
			Scale     = Vector(16, 8, 8) * Scale,
			Sensitive = true
		},
		Piston = {
			Pos   = Vector(7.5, 0, 9.5) * Scale,
			Scale = Vector(9, 8, 11) * Scale
		}
	})
end
