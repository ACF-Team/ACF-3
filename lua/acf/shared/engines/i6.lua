
-- Inline 6 engines

-- Petrol

ACF_DefineEngine( "2.2-I6", {
	name = "2.2L I6 Petrol",
	desc = "Car sized I6 petrol with power in the high revs",
	model = "models/engines/inline6s.mdl",
	sound = "acf_base/engines/l6_petrolsmall2.wav",
	category = "I6",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 120,
	torque = 130,
	flywheelmass = 0.1,
	idlerpm = 800,
	peakminrpm = 4000,
	peakmaxrpm = 6500,
	limitrpm = 7200
} )

ACF_DefineEngine( "4.8-I6", {
	name = "4.8L I6 Petrol",
	desc = "Light truck duty I6, good for offroad applications",
	model = "models/engines/inline6m.mdl",
	sound = "acf_base/engines/l6_petrolmedium.wav",
	category = "I6",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 300,
	torque = 360,
	flywheelmass = 0.2,
	idlerpm = 900,
	peakminrpm = 3100,
	peakmaxrpm = 5000,
	limitrpm = 5500
} )

ACF_DefineEngine( "17.2-I6", {
	name = "17.2L I6 Petrol",
	desc = "Heavy tractor duty petrol I6, decent overall powerband",
	model = "models/engines/inline6l.mdl",
	sound = "acf_base/engines/l6_petrollarge2.wav",
	category = "I6",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 850,
	torque = 960,
	flywheelmass = 2.5,
	idlerpm = 800,
	peakminrpm = 2000,
	peakmaxrpm = 4000,
	limitrpm = 4250
} )

-- Diesel

ACF_DefineEngine( "3.0-I6", {
	name = "3.0L I6 Diesel",
	desc = "Car sized I6 diesel, good, wide powerband",
	model = "models/engines/inline6s.mdl",
	sound = "acf_base/engines/l6_dieselsmall.wav",
	category = "I6",
	fuel = "Diesel",
	enginetype = "GenericDiesel",
	weight = 150,
	torque = 200,
	flywheelmass = 0.5,
	idlerpm = 650,
	peakminrpm = 1000,
	peakmaxrpm = 3000,
	limitrpm = 4500
} )

ACF_DefineEngine( "6.5-I6", {
	name = "6.5L I6 Diesel",
	desc = "Truck duty I6, good overall powerband and torque",
	model = "models/engines/inline6m.mdl",
	sound = "acf_base/engines/l6_dieselmedium4.wav",
	category = "I6",
	fuel = "Diesel",
	enginetype = "GenericDiesel",
	weight = 450,
	torque = 520,
	flywheelmass = 1.5,
	idlerpm = 600,
	peakminrpm = 1000,
	peakmaxrpm = 3000,
	limitrpm = 4000
} )

ACF_DefineEngine( "20.0-I6", {
	name = "20.0L I6 Diesel",
	desc = "Heavy duty diesel I6, used in generators and heavy movers",
	model = "models/engines/inline6l.mdl",
	sound = "acf_base/engines/l6_diesellarge2.wav",
	category = "I6",
	fuel = "Diesel",
	enginetype = "GenericDiesel",
	weight = 1200,
	torque = 1700,
	flywheelmass = 8,
	idlerpm = 400,
	peakminrpm = 650,
	peakmaxrpm = 2100,
	limitrpm = 2600
} )

ACF.RegisterEngineClass("I6", {
	Name = "Inline 6 Engine",
})

do -- Petrol Engines
	ACF.RegisterEngine("2.2-I6", "I6", {
		Name		 = "2.2L I6 Petrol",
		Description	 = "Car sized I6 petrol with power in the high revs.",
		Model		 = "models/engines/inline6s.mdl",
		Sound		 = "acf_engines/l6_petrolsmall2.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 120,
		Torque		 = 130,
		FlywheelMass = 0.1,
		RPM = {
			Idle	= 800,
			PeakMin	= 4000,
			PeakMax	= 6500,
			Limit	= 7200,
		}
	})

	ACF.RegisterEngine("4.8-I6", "I6", {
		Name		 = "4.8L I6 Petrol",
		Description	 = "Light truck duty I6, good for offroad applications.",
		Model		 = "models/engines/inline6m.mdl",
		Sound		 = "acf_engines/l6_petrolmedium.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 300,
		Torque		 = 360,
		FlywheelMass = 0.2,
		RPM = {
			Idle	= 900,
			PeakMin	= 3100,
			PeakMax	= 5000,
			Limit	= 5500,
		}
	})

	ACF.RegisterEngine("17.2-I6", "I6", {
		Name		 = "17.2L I6 Petrol",
		Description	 = "Heavy tractor duty petrol I6, decent overall powerband.",
		Model		 = "models/engines/inline6l.mdl",
		Sound		 = "acf_engines/l6_petrollarge2.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 850,
		Torque		 = 960,
		FlywheelMass = 2.5,
		RPM = {
			Idle	= 800,
			PeakMin	= 2000,
			PeakMax	= 4000,
			Limit	= 4250,
		}
	})
end

do -- Diesel Engines
	ACF.RegisterEngine("3.0-I6", "I6", {
		Name		 = "3.0L I6 Diesel",
		Description	 = "Car sized I6 diesel, good, wide powerband.",
		Model		 = "models/engines/inline6s.mdl",
		Sound		 = "acf_engines/l6_dieselsmall.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 150,
		Torque		 = 200,
		FlywheelMass = 0.5,
		RPM = {
			Idle	= 650,
			PeakMin	= 1000,
			PeakMax	= 3000,
			Limit	= 4500,
		}
	})

	ACF.RegisterEngine("6.5-I6", "I6", {
		Name		 = "6.5L I6 Diesel",
		Description	 = "Truck duty I6, good overall powerband and torque.",
		Model		 = "models/engines/inline6m.mdl",
		Sound		 = "acf_engines/l6_dieselmedium4.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 450,
		Torque		 = 520,
		FlywheelMass = 1.5,
		RPM = {
			Idle	= 600,
			PeakMin	= 1000,
			PeakMax	= 3000,
			Limit	= 4000,
		}
	})

	ACF.RegisterEngine("20.0-I6", "I6", {
		Name		 = "20.0L I6 Diesel",
		Description	 = "Heavy duty diesel I6, used in generators and heavy movers.",
		Model		 = "models/engines/inline6l.mdl",
		Sound		 = "acf_engines/l6_diesellarge2.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 1200,
		Torque		 = 1700,
		FlywheelMass = 8,
		RPM = {
			Idle	= 400,
			PeakMin	= 650,
			PeakMax	= 2100,
			Limit	= 2600,
		}
	})
end
