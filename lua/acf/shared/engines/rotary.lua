
-- Wankel engines

ACF_DefineEngine( "900cc-R", {
	name = "0.9L Rotary",
	desc = "Small 2-rotor Wankel; suited for yard use\n\nWankels have rather wide powerbands, but are very high strung",
	model = "models/engines/wankel_2_small.mdl",
	sound = "acf_base/engines/wankel_small.wav",
	category = "Rotary",
	fuel = "Petrol",
	enginetype = "Wankel",
	weight = 50,
	torque = 78,
	flywheelmass = 0.06,
	idlerpm = 950,
	peakminrpm = 4500,
	peakmaxrpm = 9000,
	limitrpm = 9200
} )

ACF_DefineEngine( "1.3L-R", {
	name = "1.3L Rotary",
	desc = "Medium 2-rotor Wankel\n\nWankels have rather wide powerbands, but are very high strung",
	model = "models/engines/wankel_2_med.mdl",
	sound = "acf_base/engines/wankel_medium.wav",
	category = "Rotary",
	fuel = "Petrol",
	enginetype = "Wankel",
	weight = 140,
	torque = 124,
	flywheelmass = 0.06,
	idlerpm = 950,
	peakminrpm = 4100,
	peakmaxrpm = 8500,
	limitrpm = 9000
} )

ACF_DefineEngine( "2.0L-R", {
	name = "2.0L Rotary",
	desc = "High performance 3-rotor Wankel\n\nWankels have rather wide powerbands, but are very high strung",
	model = "models/engines/wankel_3_med.mdl",
	sound = "acf_base/engines/wankel_large.wav",
	category = "Rotary",
	fuel = "Petrol",
	enginetype = "Wankel",
	weight = 200,
	torque = 188,
	flywheelmass = 0.1,
	idlerpm = 950,
	peakminrpm = 4100,
	peakmaxrpm = 8500,
	limitrpm = 9500
} )

ACF.RegisterEngineClass("R", {
	Name		= "Rotary Engine",
	Description	= "Wankels have rather wide powerbands, but are very high strung."
})

do
	ACF.RegisterEngine("900cc-R", "R", {
		Name		 = "0.9L Rotary",
		Description	 = "Small 2-rotor Wankel, suited for yard use.",
		Model		 = "models/engines/wankel_2_small.mdl",
		Sound		 = "acf_base/engines/wankel_small.wav",
		Fuel		 = { Petrol = true },
		Type		 = "Wankel",
		Mass		 = 50,
		Torque		 = 78,
		FlywheelMass = 0.06,
		RPM = {
			Idle	= 950,
			PeakMin	= 4500,
			PeakMax	= 9000,
			Limit	= 9200,
		}
	})

	ACF.RegisterEngine("1.3L-R", "R", {
		Name		 = "1.3L Rotary",
		Description	 = "Medium 2-rotor Wankel.",
		Model		 = "models/engines/wankel_2_med.mdl",
		Sound		 = "acf_base/engines/wankel_medium.wav",
		Fuel		 = { Petrol = true },
		Type		 = "Wankel",
		Mass		 = 140,
		Torque		 = 124,
		FlywheelMass = 0.06,
		RPM = {
			Idle	= 950,
			PeakMin	= 4100,
			PeakMax	= 8500,
			Limit	= 9000,
		}
	})

	ACF.RegisterEngine("2.0L-R", "R", {
		Name		 = "2.0L Rotary",
		Description	 = "High performance 3-rotor Wankel.",
		Model		 = "models/engines/wankel_3_med.mdl",
		Sound		 = "acf_base/engines/wankel_large.wav",
		Fuel		 = { Petrol = true },
		Type		 = "Wankel",
		Mass		 = 200,
		Torque		 = 188,
		FlywheelMass = 0.1,
		RPM = {
			Idle	= 950,
			PeakMin	= 4100,
			PeakMax	= 8500,
			Limit	= 9500,
		}
	})
end