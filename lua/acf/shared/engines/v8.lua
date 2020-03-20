
-- V8 engines

-- Petrol

ACF_DefineEngine( "5.7-V8", {
	name = "5.7L V8 Petrol",
	desc = "Car sized petrol engine, good power and mid range torque",
	model = "models/engines/v8s.mdl",
	sound = "acf_engines/v8_petrolsmall.wav",
	category = "V8",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 260,
	torque = 320,
	flywheelmass = 0.15,
	idlerpm = 800,
	peakminrpm = 3000,
	peakmaxrpm = 5000,
	limitrpm = 6500
} )

ACF_DefineEngine( "9.0-V8", {
	name = "9.0L V8 Petrol",
	desc = "Thirsty, giant V8, for medium applications",
	model = "models/engines/v8m.mdl",
	sound = "acf_engines/v8_petrolmedium.wav",
	category = "V8",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 400,
	torque = 460,
	flywheelmass = 0.25,
	idlerpm = 700,
	peakminrpm = 3100,
	peakmaxrpm = 5000,
	limitrpm = 5500
} )

ACF_DefineEngine( "18.0-V8", {
	name = "18.0L V8 Petrol",
	desc = "American gasoline tank V8, good overall power and torque and fairly lightweight",
	model = "models/engines/v8l.mdl",
	sound = "acf_engines/v8_petrollarge.wav",
	category = "V8",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 850,
	torque = 1458,
	flywheelmass = 2.8,
	idlerpm = 600,
	peakminrpm = 2000,
	peakmaxrpm = 3300,
	limitrpm = 3800
} )

-- Diesel

ACF_DefineEngine( "4.5-V8", {
	name = "4.5L V8 Diesel",
	desc = "Light duty diesel v8, good for light vehicles that require a lot of torque",
	model = "models/engines/v8s.mdl",
	sound = "acf_engines/v8_dieselsmall.wav",
	category = "V8",
	fuel = "Diesel",
	enginetype = "GenericDiesel",
	weight = 320,
	torque = 415,
	flywheelmass = 0.75,
	idlerpm = 800,
	peakminrpm = 1000,
	peakmaxrpm = 3000,
	limitrpm = 5000
} )

ACF_DefineEngine( "7.8-V8", {
	name = "7.8L V8 Diesel",
	desc = "Redneck chariot material. Truck duty V8 diesel, has a good, wide powerband",
	model = "models/engines/v8m.mdl",
	sound = "acf_engines/v8_dieselmedium2.wav",
	category = "V8",
	fuel = "Diesel",
	enginetype = "GenericDiesel",
	weight = 520,
	torque = 700,
	flywheelmass = 1.6,
	idlerpm = 650,
	peakminrpm = 1000,
	peakmaxrpm = 3000,
	limitrpm = 4000
} )

ACF_DefineEngine( "19.0-V8", {
	name = "19.0L V8 Diesel",
	desc = "Heavy duty diesel V8, used in heavy construction equipment and tanks",
	model = "models/engines/v8l.mdl",
	sound = "acf_engines/v8_diesellarge.wav",
	category = "V8",
	fuel = "Diesel",
	enginetype = "GenericDiesel",
	weight = 1200,
	torque = 2300,
	flywheelmass = 4.5,
	idlerpm = 500,
	peakminrpm = 600,
	peakmaxrpm = 1800,
	limitrpm = 2500
} )

ACF.RegisterEngineClass("V8", {
	Name = "V8 Engine",
})

do -- Petrol Engines
	ACF.RegisterEngine("5.7-V8", "V8", {
		Name		 = "5.7L V8 Petrol",
		Description	 = "Car sized petrol engine, good power and mid range torque",
		Model		 = "models/engines/v8s.mdl",
		Sound		 = "acf_engines/v8_petrolsmall.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 260,
		Torque		 = 320,
		FlywheelMass = 0.15,
		RPM = {
			Idle	= 800,
			PeakMin	= 3000,
			PeakMax	= 5000,
			Limit	= 6500,
		}
	})

	ACF.RegisterEngine("9.0-V8", "V8", {
		Name		 = "9.0L V8 Petrol",
		Description	 = "Thirsty, giant V8, for medium applications",
		Model		 = "models/engines/v8m.mdl",
		Sound		 = "acf_engines/v8_petrolmedium.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 400,
		Torque		 = 460,
		FlywheelMass = 0.25,
		RPM = {
			Idle	= 700,
			PeakMin	= 3100,
			PeakMax	= 5000,
			Limit	= 5500,
		}
	})

	ACF.RegisterEngine("18.0-V8", "V8", {
		Name		 = "18.0L V8 Petrol",
		Description	 = "American gasoline tank V8, good overall power and torque and fairly lightweight",
		Model		 = "models/engines/v8l.mdl",
		Sound		 = "acf_engines/v8_petrollarge.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 850,
		Torque		 = 1458,
		FlywheelMass = 2.8,
		RPM = {
			Idle	= 600,
			PeakMin	= 2000,
			PeakMax	= 3300,
			Limit	= 3800,
		}
	})
end

do -- Diesel Engines
	ACF.RegisterEngine("4.5-V8", "V8", {
		Name		 = "4.5L V8 Diesel",
		Description	 = "Light duty diesel v8, good for light vehicles that require a lot of torque",
		Model		 = "models/engines/v8s.mdl",
		Sound		 = "acf_engines/v8_dieselsmall.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 320,
		Torque		 = 415,
		FlywheelMass = 0.75,
		RPM = {
			Idle	= 800,
			PeakMin	= 1000,
			PeakMax	= 3000,
			Limit	= 5000,
		}
	})

	ACF.RegisterEngine("7.8-V8", "V8", {
		Name		 = "7.8L V8 Diesel",
		Description	 = "Redneck chariot material. Truck duty V8 diesel, has a good, wide powerband",
		Model		 = "models/engines/v8m.mdl",
		Sound		 = "acf_engines/v8_dieselmedium2.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 520,
		Torque		 = 700,
		FlywheelMass = 1.6,
		RPM = {
			Idle	= 650,
			PeakMin	= 1000,
			PeakMax	= 3000,
			Limit	= 4000,
		}
	})

	ACF.RegisterEngine("19.0-V8", "V8", {
		Name		 = "19.0L V8 Diesel",
		Description	 = "Heavy duty diesel V8, used in heavy construction equipment and tanks",
		Model		 = "models/engines/v8l.mdl",
		Sound		 = "acf_engines/v8_diesellarge.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 1200,
		Torque		 = 2300,
		FlywheelMass = 4.5,
		RPM = {
			Idle	= 500,
			PeakMin	= 600,
			PeakMax	= 1800,
			Limit	= 2500,
		}
	})
end
