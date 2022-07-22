local ACF     = ACF
local Engines = ACF.Classes.Engines


Engines.Register("I5", {
	Name = "Inline 5 Engine",
})

do -- Petrol Engines
	Engines.RegisterItem("2.3-I5", "I5", {
		Name		 = "2.3L I5 Petrol",
		Description	 = "Sedan-grade 5-cylinder, solid and dependable.",
		Model		 = "models/engines/inline5s.mdl",
		Sound		 = "acf_base/engines/i5_petrolsmall.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 100,
		Torque		 = 156,
		FlywheelMass = 0.12,
		RPM = {
			Idle	= 900,
			Limit	= 7000,
		},
		Preview = {
			FOV = 117,
		},
	})

	Engines.RegisterItem("3.9-I5", "I5", {
		Name		 = "3.9L I5 Petrol",
		Description	 = "Truck sized inline 5, strong with a good balance of revs and torque.",
		Model		 = "models/engines/inline5m.mdl",
		Sound		 = "acf_base/engines/i5_petrolmedium.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 250,
		Torque		 = 343,
		FlywheelMass = 0.25,
		RPM = {
			Idle	= 700,
			Limit	= 6500,
		},
		Preview = {
			FOV = 117,
		},
	})
end

do -- Diesel Engines
	Engines.RegisterItem("2.9-I5", "I5", {
		Name		 = "2.9L I5 Diesel",
		Description	 = "Aging fuel-injected diesel, low in horsepower but very forgiving and durable.",
		Model		 = "models/engines/inline5s.mdl",
		Sound		 = "acf_base/engines/i5_dieselsmall2.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 130,
		Torque		 = 225,
		FlywheelMass = 0.5,
		RPM = {
			Idle	= 500,
			Limit	= 4200,
		},
		Preview = {
			FOV = 117,
		},
	})

	Engines.RegisterItem("4.1-I5", "I5", {
		Name		 = "4.1L I5 Diesel",
		Description	 = "Heavier duty diesel, found in things that work hard.",
		Model		 = "models/engines/inline5m.mdl",
		Sound		 = "acf_base/engines/i5_dieselmedium.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 400,
		Torque		 = 550,
		FlywheelMass = 1.5,
		RPM = {
			Idle	= 650,
			Limit	= 3800,
		},
		Preview = {
			FOV = 117,
		},
	})
end

ACF.SetCustomAttachment("models/engines/inline5m.mdl", "driveshaft", Vector(-15, 0, 6.6), Angle(0, 180, 90))
ACF.SetCustomAttachment("models/engines/inline5s.mdl", "driveshaft", Vector(-10, 0, 4.4), Angle(0, 180, 90))

local Models = {
	{ Model = "models/engines/inline5b.mdl", Scale = 2.5 },
	{ Model = "models/engines/inline5m.mdl", Scale = 1.5 },
	{ Model = "models/engines/inline5s.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Shaft = {
			Pos       = Vector(-0.75, 0, 4.75) * Scale,
			Scale     = Vector(28, 7.5, 9) * Scale,
			Sensitive = true
		},
		Pistons = {
			Pos   = Vector(0.25, 0, 13.5) * Scale,
			Scale = Vector(23, 5.25, 8.5) * Scale
		}
	})
end
