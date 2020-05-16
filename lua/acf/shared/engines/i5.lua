
-- Inline 5 engines

-- Petrol

ACF_DefineEngine( "2.3-I5", {
	name = "2.3L I5 Petrol",
	desc = "Sedan-grade 5-cylinder, solid and dependable",
	model = "models/engines/inline5s.mdl",
	sound = "acf_base/engines/i5_petrolsmall.wav",
	category = "I5",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 100,
	torque = 125,
	flywheelmass = 0.12,
	idlerpm = 900,
	peakminrpm = 3600,
	peakmaxrpm = 5900,
	limitrpm = 7000
} )

ACF_DefineEngine( "3.9-I5", {
	name = "3.9L I5 Petrol",
	desc = "Truck sized inline 5, strong with a good balance of revs and torques",
	model = "models/engines/inline5m.mdl",
	sound = "acf_base/engines/i5_petrolmedium.wav",
	category = "I5",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 250,
	torque = 275,
	flywheelmass = 0.25,
	idlerpm = 700,
	peakminrpm = 3700,
	peakmaxrpm = 6000,
	limitrpm = 6500
} )

-- Diesel

ACF_DefineEngine( "2.9-I5", {
	name = "2.9L I5 Diesel",
	desc = "Aging fuel-injected diesel, low in horsepower but very forgiving and durable",
	model = "models/engines/inline5s.mdl",
	sound = "acf_base/engines/i5_dieselsmall2.wav",
	category = "I5",
	fuel = "Diesel",
	enginetype = "GenericDiesel",
	weight = 130,
	torque = 180,
	flywheelmass = 0.5,
	idlerpm = 500,
	peakminrpm = 900,
	peakmaxrpm = 2800,
	limitrpm = 4200
} )

ACF_DefineEngine( "4.1-I5", {
	name = "4.1L I5 Diesel",
	desc = "Heavier duty diesel, found in things that work hard",
	model = "models/engines/inline5m.mdl",
	sound = "acf_base/engines/i5_dieselmedium.wav",
	category = "I5",
	fuel = "Diesel",
	enginetype = "GenericDiesel",
	weight = 400,
	torque = 440,
	flywheelmass = 1.5,
	idlerpm = 650,
	peakminrpm = 1000,
	peakmaxrpm = 3200,
	limitrpm = 3800
} )

ACF.RegisterEngineClass("I5", {
	Name = "Inline 5 Engine",
})

do -- Petrol Engines
	ACF.RegisterEngine("2.3-I5", "I5", {
		Name		 = "2.3L I5 Petrol",
		Description	 = "Sedan-grade 5-cylinder, solid and dependable.",
		Model		 = "models/engines/inline5s.mdl",
		Sound		 = "acf_engines/i5_petrolsmall.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 100,
		Torque		 = 125,
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
		Sound		 = "acf_engines/i5_petrolmedium.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 250,
		Torque		 = 275,
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
		Sound		 = "acf_engines/i5_dieselsmall2.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 130,
		Torque		 = 180,
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
		Sound		 = "acf_engines/i5_dieselmedium.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 400,
		Torque		 = 440,
		FlywheelMass = 1.5,
		RPM = {
			Idle	= 650,
			PeakMin	= 1000,
			PeakMax	= 3200,
			Limit	= 3800,
		}
	})
end
