
-- Single-cylinder engines

ACF_DefineEngine( "0.25-I1", {
	name = "250cc Single",
	desc = "Tiny bike engine",
	model = "models/engines/1cylsml.mdl",
	sound = "acf_base/engines/i1_small.wav",
	category = "Single",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 15,
	torque = 25,
	flywheelmass = 0.005,
	idlerpm = 1200,
	peakminrpm = 4000,
	peakmaxrpm = 6500,
	limitrpm = 7500
} )

ACF_DefineEngine( "0.5-I1", {
	name = "500cc Single",
	desc = "Large single cylinder bike engine",
	model = "models/engines/1cylmed.mdl",
	sound = "acf_base/engines/i1_medium.wav",
	category = "Single",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 20,
	torque = 50,
	flywheelmass = 0.005,
	idlerpm = 900,
	peakminrpm = 4300,
	peakmaxrpm = 7000,
	limitrpm = 8000
} )

ACF_DefineEngine( "1.3-I1", {
	name = "1300cc Single",
	desc = "Ridiculously large single cylinder engine, seriously what the fuck",
	model = "models/engines/1cylbig.mdl",
	sound = "acf_base/engines/i1_large.wav",
	category = "Single",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 50,
	torque = 112,
	flywheelmass = 0.1,
	idlerpm = 600,
	peakminrpm = 3600,
	peakmaxrpm = 6000,
	limitrpm = 6700
} )

ACF.RegisterEngineClass("I1", {
	Name = "Single Cylinder Engine",
})

do
	ACF.RegisterEngine("0.25-I1", "I1", {
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
			PeakMin	= 4000,
			PeakMax	= 6500,
			Limit	= 7500,
		}
	})

	ACF.RegisterEngine("0.5-I1", "I1", {
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
			PeakMin	= 4300,
			PeakMax	= 7000,
			Limit	= 8000,
		}
	})

	ACF.RegisterEngine("1.3-I1", "I1", {
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
			PeakMin	= 3600,
			PeakMax	= 6000,
			Limit	= 6700,
		}
	})
end