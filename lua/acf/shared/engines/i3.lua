
-- Inline 3 engines

-- Petrol

ACF_DefineEngine( "1.2-I3", {
	name = "1.2L I3 Petrol",
	desc = "Tiny microcar engine, efficient but weak",
	model = "models/engines/inline3s.mdl",
	sound = "acf_base/engines/i4_petrolsmall2.wav",
	category = "I3",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 40,
	torque = 118,
	flywheelmass = 0.05,
	idlerpm = 1100,
	peakminrpm = 3300,
	peakmaxrpm = 5400,
	limitrpm = 6000
} )

ACF_DefineEngine( "3.4-I3", {
	name = "3.4L I3 Petrol",
	desc = "Short block engine for light utility use",
	model = "models/engines/inline3m.mdl",
	sound = "acf_base/engines/i4_petrolmedium2.wav",
	category = "I3",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 170,
	torque = 243,
	flywheelmass = 0.2,
	idlerpm = 900,
	peakminrpm = 3500,
	peakmaxrpm = 6600,
	limitrpm = 6800
} )

ACF_DefineEngine( "13.5-I3", {
	name = "13.5L I3 Petrol",
	desc = "Short block light tank engine, likes sideways mountings",
	model = "models/engines/inline3b.mdl",
	sound = "acf_base/engines/i4_petrollarge.wav",
	category = "I3",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 500,
	torque = 893,
	flywheelmass = 3.7,
	idlerpm = 500,
	peakminrpm = 1900,
	peakmaxrpm = 3500,
	limitrpm = 3900
} )

-- Diesel

ACF_DefineEngine( "1.1-I3", {
	name = "1.1L I3 Diesel",
	desc = "ATV grade 3-banger, enormous rev band but a choppy idle, great for light utility work",
	model = "models/engines/inline3s.mdl",
	sound = "acf_base/engines/i4_diesel2.wav",
	category = "I3",
	fuel = "Diesel",
	enginetype = "GenericDiesel",
	weight = 65,
	torque = 187,
	flywheelmass = 0.2,
	idlerpm = 550,
	peakminrpm = 800,
	peakmaxrpm = 2500,
	limitrpm = 3000
} )

ACF_DefineEngine( "2.8-I3", {
	name = "2.8L I3 Diesel",
	desc = "Medium utility grade I3 diesel, for tractors",
	model = "models/engines/inline3m.mdl",
	sound = "acf_base/engines/i4_dieselmedium.wav",
	category = "I3",
	fuel = "Diesel",
	enginetype = "GenericDiesel",
	weight = 200,
	torque = 362,
	flywheelmass = 1,
	idlerpm = 600,
	peakminrpm = 1200,
	peakmaxrpm = 3600,
	limitrpm = 3800
} )

ACF_DefineEngine( "11.0-I3", {
	name = "11.0L I3 Diesel",
	desc = "Light tank duty engine, compact yet grunts hard",
	model = "models/engines/inline3b.mdl",
	sound = "acf_base/engines/i4_diesellarge.wav",
	category = "I3",
	fuel = "Diesel",
	enginetype = "GenericDiesel",
	weight = 650,
	torque = 1500,
	flywheelmass = 5,
	idlerpm = 550,
	peakminrpm = 650,
	peakmaxrpm = 1800,
	limitrpm = 2000
} )

ACF.RegisterEngineClass("I3", {
	Name = "Inline 3 Engine",
})

do -- Petrol Engines
	ACF.RegisterEngine("1.2-I3", "I3", {
		Name		 = "1.2L I3 Petrol",
		Description	 = "Tiny microcar engine, efficient but weak.",
		Model		 = "models/engines/inline3s.mdl",
		Sound		 = "acf_base/engines/i4_petrolsmall2.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 40,
		Torque		 = 95,
		FlywheelMass = 0.05,
		RPM = {
			Idle	= 1100,
			PeakMin	= 3300,
			PeakMax	= 5400,
			Limit	= 6000,
		}
	})

	ACF.RegisterEngine("3.4-I3", "I3", {
		Name		 = "3.4L I3 Petrol",
		Description	 = "Short block engine for light utility use.",
		Model		 = "models/engines/inline3m.mdl",
		Sound		 = "acf_base/engines/i4_petrolmedium2.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 170,
		Torque		 = 195,
		FlywheelMass = 0.2,
		RPM = {
			Idle	= 900,
			PeakMin	= 3500,
			PeakMax	= 6600,
			Limit	= 6800,
		}
	})

	ACF.RegisterEngine("13.5-I3", "I3", {
		Name		 = "13.5L I3 Petrol",
		Description	 = "Short block light tank engine, likes sideways mountings.",
		Model		 = "models/engines/inline3b.mdl",
		Sound		 = "acf_base/engines/i4_petrollarge.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 500,
		Torque		 = 715,
		FlywheelMass = 3.7,
		RPM = {
			Idle	= 500,
			PeakMin	= 1900,
			PeakMax	= 3500,
			Limit	= 3900,
		}
	})
end

do -- Diesel Engines
	ACF.RegisterEngine("1.1-I3", "I3", {
		Name		 = "1.1L I3 Diesel",
		Description	 = "ATV grade 3-banger, enormous rev band but a choppy idle, great for light utility work.",
		Model		 = "models/engines/inline3s.mdl",
		Sound		 = "acf_base/engines/i4_diesel2.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 65,
		Torque		 = 150,
		FlywheelMass = 0.2,
		RPM = {
			Idle	= 550,
			PeakMin	= 800,
			PeakMax	= 2500,
			Limit	= 3000,
		}
	})

	ACF.RegisterEngine("2.8-I3", "I3", {
		Name		 = "2.8L I3 Diesel",
		Description	 = "Medium utility grade I3 diesel, for tractors",
		Model		 = "models/engines/inline3m.mdl",
		Sound		 = "acf_base/engines/i4_dieselmedium.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 200,
		Torque		 = 290,
		FlywheelMass = 1,
		RPM = {
			Idle	= 600,
			PeakMin	= 1200,
			PeakMax	= 3600,
			Limit	= 3800
		}
	})

	ACF.RegisterEngine("11.0-I3", "I3", {
		Name		 = "11.0L I3 Diesel",
		Description	 = "Light tank duty engine, compact yet grunts hard.",
		Model		 = "models/engines/inline3b.mdl",
		Sound		 = "acf_base/engines/i4_diesellarge.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 650,
		Torque		 = 1200,
		FlywheelMass = 5,
		RPM = {
			Idle	= 550,
			PeakMin	= 650,
			PeakMax	= 1800,
			Limit	= 2000
		}
	})
end