
-- V-Twin engines

ACF_DefineEngine( "0.6-V2", {
	name = "600cc V-Twin",
	desc = "Twin cylinder bike engine, torquey for its size",
	model = "models/engines/v-twins2.mdl",
	sound = "acf_base/engines/vtwin_small.wav",
	category = "V-Twin",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 30,
	torque = 50,
	flywheelmass = 0.01,
	idlerpm = 900,
	peakminrpm = 4000,
	peakmaxrpm = 6500,
	limitrpm = 7000
} )

ACF_DefineEngine( "1.2-V2", {
	name = "1200cc V-Twin",
	desc = "Large displacement vtwin engine",
	model = "models/engines/v-twinm2.mdl",
	sound = "acf_base/engines/vtwin_medium.wav",
	category = "V-Twin",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 50,
	torque = 85,
	flywheelmass = 0.02,
	idlerpm = 725,
	peakminrpm = 3300,
	peakmaxrpm = 5500,
	limitrpm = 6250
} )

ACF_DefineEngine( "2.4-V2", {
	name = "2400cc V-Twin",
	desc = "Huge fucking Vtwin 'MURRICA FUCK YEAH",
	model = "models/engines/v-twinl2.mdl",
	sound = "acf_base/engines/vtwin_large.wav",
	category = "V-Twin",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 100,
	torque = 160,
	flywheelmass = 0.075,
	idlerpm = 900,
	peakminrpm = 3300,
	peakmaxrpm = 5500,
	limitrpm = 6000
} )

ACF.RegisterEngineClass("V2", {
	Name = "V-Twin Engine",
})

do -- Petrol Engines
	ACF.RegisterEngine("0.6-V2", "V2", {
		Name		 = "600cc V-Twin",
		Description	 = "Twin cylinder bike engine, torquey for its size",
		Model		 = "models/engines/v-twins2.mdl",
		Sound		 = "acf_engines/vtwin_small.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 30,
		Torque		 = 50,
		FlywheelMass = 0.01,
		RPM = {
			Idle	= 900,
			PeakMin	= 4000,
			PeakMax	= 6500,
			Limit	= 7000,
		}
	})

	ACF.RegisterEngine("1.2-V2", "V2", {
		Name		 = "1200cc V-Twin",
		Description	 = "Large displacement vtwin engine",
		Model		 = "models/engines/v-twinm2.mdl",
		Sound		 = "acf_engines/vtwin_medium.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 50,
		Torque		 = 85,
		FlywheelMass = 0.02,
		RPM = {
			Idle	= 725,
			PeakMin	= 3300,
			PeakMax	= 5500,
			Limit	= 6250,
		}
	})

	ACF.RegisterEngine("2.4-V2", "V2", {
		Name		 = "2400cc V-Twin",
		Description	 = "Huge fucking Vtwin 'MURRICA FUCK YEAH",
		Model		 = "models/engines/v-twinl2.mdl",
		Sound		 = "acf_engines/vtwin_large.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 100,
		Torque		 = 160,
		FlywheelMass = 0.075,
		RPM = {
			Idle	= 900,
			PeakMin	= 3300,
			PeakMax	= 5500,
			Limit	= 6000,
		}
	})
end
