
-- Inline 4 engines

-- Petrol

ACF_DefineEngine( "1.5-I4", {
	name = "1.5L I4 Petrol",
	desc = "Small car engine, not a whole lot of git",
	model = "models/engines/inline4s.mdl",
	sound = "acf_engines/i4_petrolsmall2.wav",
	category = "I4",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 50,
	torque = 90,
	flywheelmass = 0.06,
	idlerpm = 900,
	peakminrpm = 4000,
	peakmaxrpm = 6500,
	limitrpm = 7500
} )

ACF_DefineEngine( "3.7-I4", {
	name = "3.7L I4 Petrol",
	desc = "Large inline 4, sees most use in light trucks",
	model = "models/engines/inline4m.mdl",
	sound = "acf_engines/i4_petrolmedium2.wav",
	category = "I4",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 200,
	torque = 240,
	flywheelmass = 0.2,
	idlerpm = 900,
	peakminrpm = 3700,
	peakmaxrpm = 6000,
	limitrpm = 6500
} )

ACF_DefineEngine( "16.0-I4", {
	name = "16.0L I4 Petrol",
	desc = "Giant, thirsty I4 petrol, most commonly used in boats",
	model = "models/engines/inline4l.mdl",
	sound = "acf_engines/i4_petrollarge.wav",
	category = "I4",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 600,
	torque = 850,
	flywheelmass = 4,
	idlerpm = 500,
	peakminrpm = 1750,
	peakmaxrpm = 3250,
	limitrpm = 3500
} )

-- Diesel

ACF_DefineEngine( "1.6-I4", {
	name = "1.6L I4 Diesel",
	desc = "Small and light diesel, for low power applications requiring a wide powerband",
	model = "models/engines/inline4s.mdl",
	sound = "acf_engines/i4_diesel2.wav",
	category = "I4",
	fuel = "Diesel",
	enginetype = "GenericDiesel",
	weight = 90,
	torque = 150,
	flywheelmass = 0.2,
	idlerpm = 650,
	peakminrpm = 1000,
	peakmaxrpm = 3000,
	limitrpm = 5000
} )

ACF_DefineEngine( "3.1-I4", {
	name = "3.1L I4 Diesel",
	desc = "Light truck duty diesel, good overall grunt",
	model = "models/engines/inline4m.mdl",
	sound = "acf_engines/i4_dieselmedium.wav",
	category = "I4",
	fuel = "Diesel",
	enginetype = "GenericDiesel",
	weight = 250,
	torque = 320,
	flywheelmass = 1,
	idlerpm = 500,
	peakminrpm = 1150,
	peakmaxrpm = 3500,
	limitrpm = 4000
} )

ACF_DefineEngine( "15.0-I4", {
	name = "15.0L I4 Diesel",
	desc = "Small boat sized diesel, with large amounts of torque",
	model = "models/engines/inline4l.mdl",
	sound = "acf_engines/i4_diesellarge.wav",
	category = "I4",
	fuel = "Diesel",
	enginetype = "GenericDiesel",
	weight = 800,
	torque = 1400,
	flywheelmass = 5,
	idlerpm = 450,
	peakminrpm = 500,
	peakmaxrpm = 1800,
	limitrpm = 2100
} )

ACF.RegisterEngineClass("I4", {
	Name = "Inline 4 Engine",
})

do -- Petrol Engines
	ACF.RegisterEngine("1.5-I4", "I4", {
		Name		 = "1.5L I4 Petrol",
		Description	 = "Small car engine, not a whole lot of git.",
		Model		 = "models/engines/inline4s.mdl",
		Sound		 = "acf_engines/i4_petrolsmall2.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 50,
		Torque		 = 90,
		FlywheelMass = 0.06,
		RPM = {
			Idle	= 900,
			PeakMin	= 4000,
			PeakMax	= 6500,
			Limit	= 7500,
		}
	})

	ACF.RegisterEngine("3.7-I4", "I4", {
		Name		 = "3.7L I4 Petrol",
		Description	 = "Large inline 4, sees most use in light trucks.",
		Model		 = "models/engines/inline4m.mdl",
		Sound		 = "acf_engines/i4_petrolmedium2.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 200,
		Torque		 = 240,
		FlywheelMass = 0.2,
		RPM = {
			Idle	= 900,
			PeakMin	= 3700,
			PeakMax	= 6000,
			Limit	= 6500
		}
	})

	ACF.RegisterEngine("16.0-I4", "I4", {
		Name		 = "16.0L I4 Petrol",
		Description	 = "Giant, thirsty I4 petrol, most commonly used in boats.",
		Model		 = "models/engines/inline4l.mdl",
		Sound		 = "acf_engines/i4_petrollarge.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 600,
		Torque		 = 850,
		FlywheelMass = 4,
		RPM = {
			Idle	= 500,
			PeakMin	= 1750,
			PeakMax	= 3250,
			Limit	= 3500,
		}
	})
end

do -- Diesel Engines
	ACF.RegisterEngine("1.6-I4", "I4", {
		Name		 = "1.6L I4 Diesel",
		Description	 = "Small and light diesel, for low power applications requiring a wide powerband.",
		Model		 = "models/engines/inline4s.mdl",
		Sound		 = "acf_engines/i4_diesel2.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 90,
		Torque		 = 150,
		FlywheelMass = 0.2,
		RPM = {
			Idle	= 650,
			PeakMin	= 1000,
			PeakMax	= 3000,
			Limit	= 5000,
		}
	})

	ACF.RegisterEngine("3.1-I4", "I4", {
		Name		 = "3.1L I4 Diesel",
		Description	 = "Light truck duty diesel, good overall grunt.",
		Model		 = "models/engines/inline4m.mdl",
		Sound		 = "acf_engines/i4_dieselmedium.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 250,
		Torque		 = 320,
		FlywheelMass = 1,
		RPM = {
			Idle	= 500,
			PeakMin	= 1150,
			PeakMax	= 3500,
			Limit	= 4000,
		}
	})

	ACF.RegisterEngine("15.0-I4", "I4", {
		Name		 = "15.0L I4 Diesel",
		Description	 = "Small boat sized diesel, with large amounts of torque.",
		Model		 = "models/engines/inline4l.mdl",
		Sound		 = "acf_engines/i4_diesellarge.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 800,
		Torque		 = 1400,
		FlywheelMass = 5,
		RPM = {
			Idle	= 450,
			PeakMin	= 500,
			PeakMax	= 1800,
			Limit	= 2100,
		}
	})
end
