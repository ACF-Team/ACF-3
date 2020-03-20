
-- V12 engines

-- Petrol

ACF_DefineEngine( "4.6-V12", {
	name = "4.6L V12 Petrol",
	desc = "An elderly racecar engine; low on torque, but plenty of power",
	model = "models/engines/v12s.mdl",
	sound = "acf_engines/v12_petrolsmall.wav",
	category = "V12",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 188,
	torque = 235,
	flywheelmass = 0.2,
	idlerpm = 1000,
	peakminrpm = 4500,
	peakmaxrpm = 7500,
	limitrpm = 8000
} )

ACF_DefineEngine( "7.0-V12", {
	name = "7.0L V12 Petrol",
	desc = "A high end V12; primarily found in very expensive cars",
	model = "models/engines/v12m.mdl",
	sound = "acf_engines/v12_petrolmedium.wav",
	category = "V12",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 360,
	torque = 500,
	flywheelmass = 0.45,
	idlerpm = 800,
	peakminrpm = 3600,
	peakmaxrpm = 6000,
	limitrpm = 7500
} )

ACF_DefineEngine( "23.0-V12", {
	name = "23.0L V12 Petrol",
	desc = "A large, thirsty gasoline V12, found in early cold war tanks",
	model = "models/engines/v12l.mdl",
	sound = "acf_engines/v12_petrollarge.wav",
	category = "V12",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 1350,
	torque = 1925,
	flywheelmass = 5,
	idlerpm = 600,
	peakminrpm = 1500,
	peakmaxrpm = 3000,
	limitrpm = 3250
} )

-- Diesel

ACF_DefineEngine( "4.0-V12", {
	name = "4.0L V12 Diesel",
	desc = "Reliable truck-duty diesel; a lot of smooth torque",
	model = "models/engines/v12s.mdl",
	sound = "acf_engines/v12_dieselsmall.wav",
	category = "V12",
	fuel = "Diesel",
	enginetype = "GenericDiesel",
	weight = 305,
	torque = 375,
	flywheelmass = 0.475,
	idlerpm = 650,
	peakminrpm = 1200,
	peakmaxrpm = 3800,
	limitrpm = 4000
} )

ACF_DefineEngine( "9.2-V12", {
	name = "9.2L V12 Diesel",
	desc = "High torque light-tank V12, used mainly for vehicles that require balls",
	model = "models/engines/v12m.mdl",
	sound = "acf_engines/v12_dieselmedium.wav",
	category = "V12",
	fuel = "Diesel",
	enginetype = "GenericDiesel",
	weight = 600,
	torque = 750,
	flywheelmass = 2.5,
	idlerpm = 675,
	peakminrpm = 1100,
	peakmaxrpm = 3300,
	limitrpm = 3500
} )

ACF_DefineEngine( "21.0-V12", {
	name = "21.0L V12 Diesel",
	desc = "AVDS-1790-2 tank engine; massively powerful, but enormous and heavy",
	model = "models/engines/v12l.mdl",
	sound = "acf_engines/v12_diesellarge.wav",
	category = "V12",
	fuel = "Diesel",
	enginetype = "GenericDiesel",
	weight = 1800,
	torque = 3560,
	flywheelmass = 7,
	idlerpm = 400,
	peakminrpm = 500,
	peakmaxrpm = 1500,
	limitrpm = 2500
} )

ACF_DefineEngine( "13.0-V12", {
	name = "13.0L V12 Petrol",
	desc = "Thirsty gasoline v12, good torque and power for medium applications.",
	model = "models/engines/v12m.mdl",
	sound = "acf_engines/v12_special.wav",
	category = "V12",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 520,
	torque = 660,
	flywheelmass = 1,
	idlerpm = 700,
	peakminrpm = 2500,
	peakmaxrpm = 4000,
	limitrpm = 4250
} )

ACF.RegisterEngineClass("V12", {
	Name = "V12 Engine",
})

do -- Petrol Engines
	ACF.RegisterEngine("4.6-V12", "V12", {
		Name		 = "4.6L V12 Petrol",
		Description	 = "An elderly racecar engine; low on torque, but plenty of power",
		Model		 = "models/engines/v12s.mdl",
		Sound		 = "acf_engines/v12_petrolsmall.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 188,
		Torque		 = 235,
		FlywheelMass = 0.2,
		RPM = {
			Idle	= 1000,
			PeakMin	= 4500,
			PeakMax	= 7500,
			Limit	= 8000,
		}
	})

	ACF.RegisterEngine("7.0-V12", "V12", {
		Name		 = "7.0L V12 Petrol",
		Description	 = "A high end V12; primarily found in very expensive cars",
		Model		 = "models/engines/v12m.mdl",
		Sound		 = "acf_engines/v12_petrolmedium.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 360,
		Torque		 = 500,
		FlywheelMass = 0.45,
		RPM = {
			Idle	= 800,
			PeakMin	= 3600,
			PeakMax	= 6000,
			Limit	= 7500,
		}
	})

	ACF.RegisterEngine("13.0-V12", "V12", {
		Name		 = "13.0L V12 Petrol",
		Description	 = "Thirsty gasoline v12, good torque and power for medium applications.",
		Model		 = "models/engines/v12m.mdl",
		Sound		 = "acf_engines/v12_special.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 520,
		Torque		 = 660,
		FlywheelMass = 1,
		RPM = {
			Idle	= 700,
			PeakMin	= 2500,
			PeakMax	= 4000,
			Limit	= 4250,
		}
	})

	ACF.RegisterEngine("23.0-V12", "V12", {
		Name		 = "23.0L V12 Petrol",
		Description	 = "A large, thirsty gasoline V12, found in early cold war tanks",
		Model		 = "models/engines/v12l.mdl",
		Sound		 = "acf_engines/v12_petrollarge.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 1350,
		Torque		 = 1925,
		FlywheelMass = 5,
		RPM = {
			Idle	= 600,
			PeakMin	= 1500,
			PeakMax	= 3000,
			Limit	= 3250,
		}
	})
end

do -- Diesel Engines
	ACF.RegisterEngine("4.0-V12", "V12", {
		Name		 = "4.0L V12 Diesel",
		Description	 = "Reliable truck-duty diesel; a lot of smooth torque",
		Model		 = "models/engines/v12s.mdl",
		Sound		 = "acf_engines/v12_dieselsmall.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 305,
		Torque		 = 375,
		FlywheelMass = 0.475,
		RPM = {
			Idle	= 650,
			PeakMin	= 1200,
			PeakMax	= 3800,
			Limit	= 4000,
		}
	})

	ACF.RegisterEngine("9.2-V12", "V12", {
		Name		 = "9.2L V12 Diesel",
		Description	 = "High torque light-tank V12, used mainly for vehicles that require balls",
		Model		 = "models/engines/v12m.mdl",
		Sound		 = "acf_engines/v12_dieselmedium.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 600,
		Torque		 = 750,
		FlywheelMass = 2.5,
		RPM = {
			Idle	= 675,
			PeakMin	= 1100,
			PeakMax	= 3300,
			Limit	= 3500,
		}
	})

	ACF.RegisterEngine("21.0-V12", "V12", {
		Name		 = "21.0L V12 Diesel",
		Description	 = "AVDS-1790-2 tank engine; massively powerful, but enormous and heavy",
		Model		 = "models/engines/v12l.mdl",
		Sound		 = "acf_engines/v12_diesellarge.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 1800,
		Torque		 = 3560,
		FlywheelMass = 7,
		RPM = {
			Idle	= 400,
			PeakMin	= 500,
			PeakMax	= 1500,
			Limit	= 2500,
		}
	})
end
