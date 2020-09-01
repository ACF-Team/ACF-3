
-- V6 engines

ACF_DefineEngine( "3.6-V6", {
	name = "3.6L V6 Petrol",
	desc = "Meaty Car sized V6, lots of torque\n\nV6s are more torquey than the Boxer and Inline 6s but suffer in power",
	model = "models/engines/v6small.mdl",
	sound = "acf_base/engines/v6_petrolsmall.wav",
	category = "V6",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 190,
	torque = 316,
	flywheelmass = 0.25,
	idlerpm = 700,
	peakminrpm = 2200,
	peakmaxrpm = 3500,
	limitrpm = 5000
} )

ACF_DefineEngine( "6.2-V6", {
	name = "6.2L V6 Petrol",
	desc = "Heavy duty 6V71 v6, throatier than an LA whore, but loaded with torque\n\nV6s are more torquey than the Boxer and Inline 6s but suffer in power",
	model = "models/engines/v6med.mdl",
	sound = "acf_base/engines/v6_petrolmedium.wav",
	category = "V6",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 360,
	torque = 590,
	flywheelmass = 0.45,
	idlerpm = 800,
	peakminrpm = 2200,
	peakmaxrpm = 3600,
	limitrpm = 5000
} )

ACF_DefineEngine( "5.2-V6", {
	name = "5.2L V6 Diesel",
	desc = "Light AFV-grade two-stroke multifuel, high output but heavy",
	model = "models/engines/v6med.mdl",
	sound = "acf_base/engines/i5_dieselmedium.wav",
	category = "V6",
	fuel = "Multifuel",
	enginetype = "GenericDiesel",
	weight = 520,
	torque = 606,
	flywheelmass = 0.8,
	idlerpm = 650,
	peakminrpm = 1800,
	peakmaxrpm = 4200,
	limitrpm = 4300
} )

ACF_DefineEngine( "12.0-V6", {
	name = "12.0L V6 Petrol",
	desc = "Fuck duty V6, guts ripped from god himself diluted in salt and shaped into an engine.\n\nV6s are more torquey than the Boxer and Inline 6s but suffer in power",
	model = "models/engines/v6large.mdl",
	sound = "acf_base/engines/v6_petrollarge.wav",
	category = "V6",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 675,
	torque = 1806,
	flywheelmass = 4,
	idlerpm = 600,
	peakminrpm = 1575,
	peakmaxrpm = 2650,
	limitrpm = 3800
} )

ACF_DefineEngine( "15.0-V6", {
	name = "15.0L V6 Diesel",
	desc = "Powerful military-grade large V6, with impressive output.  Well suited to moderately-sized AFVs and able to handle multiple fuel types.\n\nV6s are more torquey than the Boxer and Inline 6s but suffer in power",
	model = "models/engines/v6large.mdl",
	sound = "acf_base/engines/v6_diesellarge.wav",
	category = "V6",
	fuel = "Multifuel",
	enginetype = "GenericDiesel",
	weight = 900,
	torque = 2208,
	flywheelmass = 6.4,
	idlerpm = 400,
	peakminrpm = 1150,
	peakmaxrpm = 1950,
	limitrpm = 3100
} )

ACF.RegisterEngineClass("V6", {
	Name		= "V6 Engine",
	Description	= "V6s are more torquey than the Boxer and Inline 6s but suffer in power."
})

do -- Petrol Engines
	ACF.RegisterEngine("3.6-V6", "V6", {
		Name		 = "3.6L V6 Petrol",
		Description	 = "Meaty Car sized V6, lots of torque.",
		Model		 = "models/engines/v6small.mdl",
		Sound		 = "acf_base/engines/v6_petrolsmall.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 190,
		Torque		 = 316,
		FlywheelMass = 0.25,
		RPM = {
			Idle	= 700,
			PeakMin	= 2200,
			PeakMax	= 3500,
			Limit	= 5000,
		}
	})

	ACF.RegisterEngine("6.2-V6", "V6", {
		Name		 = "6.2L V6 Petrol",
		Description	 = "Heavy duty 6V71 v6, throatier than an LA whore, but loaded with torque.",
		Model		 = "models/engines/v6med.mdl",
		Sound		 = "acf_base/engines/v6_petrolmedium.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 360,
		Torque		 = 590,
		FlywheelMass = 0.45,
		RPM = {
			Idle	= 800,
			PeakMin	= 2200,
			PeakMax	= 3600,
			Limit	= 5000,
		}
	})

	ACF.RegisterEngine("12.0-V6", "V6", {
		Name		 = "12.0L V6 Petrol",
		Description	 = "Fuck duty V6, guts ripped from god himself diluted in salt and shaped into an engine.",
		Model		 = "models/engines/v6large.mdl",
		Sound		 = "acf_base/engines/v6_petrollarge.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 675,
		Torque		 = 1806,
		FlywheelMass = 4,
		RPM = {
			Idle	= 600,
			PeakMin	= 1575,
			PeakMax	= 2650,
			Limit	= 3800,
		}
	})
end

do -- Diesel Engines
	ACF.RegisterEngine("5.2-V6", "V6", {
		Name		 = "5.2L V6 Diesel",
		Description	 = "Light AFV-grade two-stroke diesel, high output but heavy.",
		Model		 = "models/engines/v6med.mdl",
		Sound		 = "acf_base/engines/i5_dieselmedium.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 520,
		Torque		 = 606,
		FlywheelMass = 0.8,
		RPM = {
			Idle	= 650,
			PeakMin	= 1800,
			PeakMax	= 4200,
			Limit	= 4300,
		}
	})

	ACF.RegisterEngine("15.0-V6", "V6", {
		Name		 = "15.0L V6 Diesel",
		Description	 = "Powerful military-grade large V6, with impressive output. Well suited to medium-sized AFVs.",
		Model		 = "models/engines/v6large.mdl",
		Sound		 = "acf_base/engines/v6_diesellarge.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 900,
		Torque		 = 2208,
		FlywheelMass = 6.4,
		RPM = {
			Idle	= 400,
			PeakMin	= 1150,
			PeakMax	= 1950,
			Limit	= 3100,
		}
	})
end
