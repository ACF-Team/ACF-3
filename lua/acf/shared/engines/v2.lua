
-- V-Twin engines

ACF.RegisterEngineClass("V2", {
	Name = "V-Twin Engine",
})

do -- Petrol Engines
	ACF.RegisterEngine("0.6-V2", "V2", {
		Name		 = "600cc V-Twin",
		Description	 = "Twin cylinder bike engine, torquey for its size",
		Model		 = "models/engines/v-twins2.mdl",
		Sound		 = "acf_base/engines/vtwin_small.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 30,
		Torque		 = 62,
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
		Sound		 = "acf_base/engines/vtwin_medium.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 50,
		Torque		 = 106,
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
		Sound		 = "acf_base/engines/vtwin_large.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 100,
		Torque		 = 200,
		FlywheelMass = 0.075,
		RPM = {
			Idle	= 900,
			PeakMin	= 3300,
			PeakMax	= 5500,
			Limit	= 6000,
		}
	})
end

ACF.SetCustomAttachment("models/engines/v-twinl2.mdl", "driveshaft", Vector(), Angle(0, 90, 90))
ACF.SetCustomAttachment("models/engines/v-twinm2.mdl", "driveshaft", Vector(), Angle(0, 90, 90))
ACF.SetCustomAttachment("models/engines/v-twins2.mdl", "driveshaft", Vector(), Angle(0, 90, 90))
