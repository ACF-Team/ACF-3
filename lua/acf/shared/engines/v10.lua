--V10s

ACF_DefineEngine( "4.3-V10", {
	name = "4.3L V10 Petrol",
	desc = "Small-block V-10 gasoline engine, great for powering a hot rod lincoln",
	model = "models/engines/v10sml.mdl",
	sound = "acf_engines/v10_petrolsmall.wav",
	category = "V10",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 160,
	torque = 288,
	flywheelmass = 0.2,
	idlerpm = 900,
	peakminrpm = 3500,
	peakmaxrpm = 5800,
	limitrpm = 6250
} )

ACF_DefineEngine( "8.0-V10", {
	name = "8.0L V10 Petrol",
	desc = "Beefy 10-cylinder gas engine, gets 9 kids to soccer practice",
	model = "models/engines/v10med.mdl",
	sound = "acf_engines/v10_petrolmedium.wav",
	category = "V10",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 300,
	torque = 490,
	flywheelmass = 0.5,
	idlerpm = 750,
	peakminrpm = 3400,
	peakmaxrpm = 5500,
	limitrpm = 6500
} )

ACF_DefineEngine( "22.0-V10", {
	name = "22.0L V10 Multifuel",
	desc = "Heavy multifuel V-10, gearbox-shredding torque but very heavy.",
	model = "models/engines/v10big.mdl",
	sound = "acf_engines/v10_diesellarge.wav",
	category = "V10",
	fuel = "Multifuel",
	enginetype = "GenericDiesel",
	weight = 1600,
	torque = 2605,
	flywheelmass = 5,
	idlerpm = 525,
	peakminrpm = 750,
	peakmaxrpm = 1900,
	limitrpm = 2500
} )

ACF.RegisterEngineClass("V10", {
	Name = "V10 Engine",
})

do
	ACF.RegisterEngine("4.3-V10", "V10", {
		Name		 = "4.3L V10 Petrol",
		Description	 = "Small-block V-10 gasoline engine, great for powering a hot rod lincoln",
		Model		 = "models/engines/v10sml.mdl",
		Sound		 = "acf_engines/v10_petrolsmall.wav",
		Fuel		 = "Petrol",
		Type		 = "GenericPetrol",
		Mass		 = 160,
		Torque		 = 288,
		FlywheelMass = 0.2,
		RPM = {
			Idle	= 900,
			PeakMin	= 3500,
			PeakMax	= 5800,
			Limit	= 6250,
		}
	})

	ACF.RegisterEngine("8.0-V10", "V10", {
		Name		 = "8.0L V10 Petrol",
		Description	 = "Beefy 10-cylinder gas engine, gets 9 kids to soccer practice",
		Model		 = "models/engines/v10med.mdl",
		Sound		 = "acf_engines/v10_petrolmedium.wav",
		Fuel		 = "Petrol",
		Type		 = "GenericPetrol",
		Mass		 = 300,
		Torque		 = 490,
		FlywheelMass = 0.5,
		RPM = {
			Idle	= 750,
			PeakMin	= 3400,
			PeakMax	= 5500,
			Limit	= 6500,
		}
	})

	ACF.RegisterEngine("22.0-V10", "V10", {
		Name		 = "22.0L V10 Multifuel",
		Description	 = "Heavy multifuel V-10, gearbox-shredding torque but very heavy.",
		Model		 = "models/engines/v10big.mdl",
		Sound		 = "acf_engines/v10_diesellarge.wav",
		Fuel		 = "Multifuel",
		Type		 = "GenericDiesel",
		Mass		 = 1600,
		Torque		 = 2605,
		FlywheelMass = 5,
		RPM = {
			Idle	= 525,
			PeakMin	= 750,
			PeakMax	= 1900,
			Limit	= 2500,
		}
	})
end
