
--V4 Engines

--Diesel

ACF_DefineEngine( "1.9L-V4", {
	name = "1.9L V4 Diesel",
	desc = "Torquey little lunchbox; for those smaller vehicles that don't agree with petrol powerbands",
	model = "models/engines/v4s.mdl",
	sound = "acf_base/engines/i4_diesel2.wav",
	category = "V4",
	fuel = "Diesel",
	enginetype = "GenericDiesel",
	weight = 110,
	torque = 165,
	flywheelmass = 0.3,
	idlerpm = 650,
	peakminrpm = 950,
	peakmaxrpm = 3000,
	limitrpm = 4000
} )

ACF_DefineEngine( "3.3L-V4", {
	name = "3.3L V4 Diesel",
	desc = "Compact cube of git; for moderate utility applications",
	model = "models/engines/v4m.mdl",
	sound = "acf_base/engines/i4_dieselmedium.wav",
	category = "V4",
	fuel = "Diesel",
	enginetype = "GenericDiesel",
	weight = 275,
	torque = 480,
	flywheelmass = 1.05,
	idlerpm = 600,
	peakminrpm = 1050,
	peakmaxrpm = 3100,
	limitrpm = 3900
} )

ACF.RegisterEngineClass("V4", {
	Name = "V4 Engine",
})

do -- Diesel Engines
	ACF.RegisterEngine("1.9L-V4", "V4", {
		Name		 = "1.9L V4 Diesel",
		Description	 = "Torquey little lunchbox; for those smaller vehicles that don't agree with petrol powerbands",
		Model		 = "models/engines/v4s.mdl",
		Sound		 = "acf_engines/i4_diesel2.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 110,
		Torque		 = 165,
		FlywheelMass = 0.3,
		RPM = {
			Idle	= 650,
			PeakMin	= 950,
			PeakMax	= 3000,
			Limit	= 4000,
		}
	})

	ACF.RegisterEngine("3.3L-V4", "V4", {
		Name		 = "3.3L V4 Diesel",
		Description	 = "Compact cube of git; for moderate utility applications",
		Model		 = "models/engines/v4m.mdl",
		Sound		 = "acf_engines/i4_dieselmedium.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 275,
		Torque		 = 480,
		FlywheelMass = 1.05,
		RPM = {
			Idle	= 600,
			PeakMin	= 1050,
			PeakMax	= 3100,
			Limit	= 3900,
		}
	})
end
