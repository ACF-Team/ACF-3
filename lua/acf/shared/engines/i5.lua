
-- Inline 5 engines

ACF.RegisterEngineClass("I5", {
	Name = "Inline 5 Engine",
})

do -- Petrol Engines
	ACF.RegisterEngine("2.3-I5", "I5", {
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
			PeakMin	= 3600,
			PeakMax	= 5900,
			Limit	= 7000,
		}
	})

	ACF.RegisterEngine("3.9-I5", "I5", {
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
			PeakMin	= 3700,
			PeakMax	= 6000,
			Limit	= 6500,
		}
	})
end

do -- Diesel Engines
	ACF.RegisterEngine("2.9-I5", "I5", {
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
			PeakMin	= 900,
			PeakMax	= 2800,
			Limit	= 4200,
		}
	})

	ACF.RegisterEngine("4.1-I5", "I5", {
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
			PeakMin	= 1000,
			PeakMax	= 3200,
			Limit	= 3800,
		}
	})
end
