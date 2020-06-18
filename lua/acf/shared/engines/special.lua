
-- Special engines

ACF_DefineEngine( "0.9L-I2", {
	name = "0.9L I2 Petrol",
	desc = "Turbocharged inline twin engine that delivers surprising pep for its size.",
	model = "models/engines/inline2s.mdl",
	sound = "acf_extra/vehiclefx/engines/ponyengine.wav",
	category = "Special",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 60,
	torque = 116,
	flywheelmass = 0.085,
	idlerpm = 750,
	peakminrpm = 3125,
	peakmaxrpm = 5100,
	limitrpm = 6000
} )

ACF_DefineEngine( "1.0L-I4", {
	name = "1.0L I4 Petrol",
	desc = "Tiny I4 designed for racing bikes. Doesn't pack much torque, but revs ludicrously high.",
	model = "models/engines/inline4s.mdl",
	sound = "acf_extra/vehiclefx/engines/l4/mini_onhigh.wav",
	pitch = 0.75,
	category = "Special",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 78,
	torque = 68,
	flywheelmass = 0.031,
	idlerpm = 1200,
	peakminrpm = 7500,
	peakmaxrpm = 11500,
	limitrpm = 12000
} )

ACF_DefineEngine( "1.8L-V4", {
	name = "1.8L V4 Petrol",
	desc = "Naturally aspirated rally-tuned V4 with enlarged bore and stroke.",
	model = "models/engines/v4s.mdl",
	sound = "acf_extra/vehiclefx/engines/l4/elan_onlow.wav",
	category = "Special",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 92,
	torque = 124.8,
	flywheelmass = 0.04,
	idlerpm = 900,
	peakminrpm = 4600,
	peakmaxrpm = 7000,
	limitrpm = 7500
} )

ACF_DefineEngine( "2.4L-V6", {
	name = "2.4L V6 Petrol",
	desc = "Although the cast iron engine block is fairly weighty, this tiny v6 makes up for it with impressive power.  The unique V angle allows uncharacteristically high RPM for a V6.",
	model = "models/engines/v6small.mdl",
	sound = "acf_extra/vehiclefx/engines/l6/capri_onmid.wav",
	category = "Special",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 134,
	torque = 172,
	flywheelmass = 0.075,
	idlerpm = 950,
	peakminrpm = 4500,
	peakmaxrpm = 7100,
	limitrpm = 8000
} )

ACF_DefineEngine( "1.9L-I4", {
	name = "1.9L I4 Petrol",
	desc = "Supercharged racing 4 cylinder, most of the power in the high revs.",
	model = "models/engines/inline4s.mdl",
	sound = "acf_base/engines/i4_special.wav",
	category = "Special",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 150,
	torque = 176,
	flywheelmass = 0.06,
	idlerpm = 950,
	peakminrpm = 5200,
	peakmaxrpm = 8500,
	limitrpm = 9000
} )

ACF_DefineEngine( "2.6L-Wankel", {
	name = "2.6L Rotary",
	desc = "4 rotor racing Wankel, high revving and high strung.",
	model = "models/engines/wankel_4_med.mdl",
	sound = "acf_base/engines/wankel_large.wav",
	category = "Special",
	fuel = "Petrol",
	enginetype = "Wankel",
	weight = 260,
	torque = 250,
	flywheelmass = 0.11,
	idlerpm = 1200,
	peakminrpm = 4500,
	peakmaxrpm = 9000,
	limitrpm = 9500
} )

ACF_DefineEngine( "2.9-V8", {
	name = "2.9L V8 Petrol",
	desc = "Racing V8, very high revving and loud",
	model = "models/engines/v8s.mdl",
	sound = "acf_base/engines/v8_special.wav",
	category = "Special",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 180,
	torque = 200,
	flywheelmass = 0.075,
	idlerpm = 1000,
	peakminrpm = 5500,
	peakmaxrpm = 9000,
	limitrpm = 10000
} )

ACF_DefineEngine( "3.8-I6", {
	name = "3.8L I6 Petrol",
	desc = "Large racing straight six, powerful and high revving, but lacking in torque.",
	model = "models/engines/inline6m.mdl",
	sound = "acf_base/engines/l6_special.wav",
	category = "Special",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 180,
	torque = 224,
	flywheelmass = 0.1,
	idlerpm = 1100,
	peakminrpm = 5200,
	peakmaxrpm = 8500,
	limitrpm = 9000
} )

ACF_DefineEngine( "5.3-V10", {
	name = "5.3L V10 Special",
	desc = "Extreme performance v10",
	model = "models/engines/v10sml.mdl",
	sound = "acf_base/engines/v10_special.wav",
	category = "Special",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 300,
	torque = 320,
	flywheelmass = 0.15,
	idlerpm = 1100,
	peakminrpm = 5750,
	peakmaxrpm = 8000,
	limitrpm = 9000
} )

ACF_DefineEngine( "7.2-V8", {
	name = "7.2L V8 Petrol",
	desc = "Very high revving, glorious v8 of ear rapetasticalness.",
	model = "models/engines/v8m.mdl",
	sound = "acf_base/engines/v8_special2.wav",
	category = "Special",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 400,
	torque = 340,
	flywheelmass = 0.15,
	idlerpm = 1000,
	peakminrpm = 5000,
	peakmaxrpm = 8000,
	limitrpm = 8500
} )

ACF_DefineEngine( "3.0-V12", {
	name = "3.0L V12 Petrol",
	desc = "A purpose-built racing v12, not known for longevity.",
	model = "models/engines/v12s.mdl",
	sound = "acf_extra/vehiclefx/engines/v12/gtb4_onmid.wav",
	pitch = 0.85,
	category = "Special",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 175,
	torque = 248,
	flywheelmass = 0.1,
	idlerpm = 1200,
	peakminrpm = 6875,
	peakmaxrpm = 11000,
	limitrpm = 12500
} )

ACF.RegisterEngineClass("SP", {
	Name = "Special Engine",
})

do -- Special Rotary Engines
	ACF.RegisterEngine("2.6L-Wankel", "SP", {
		Name		 = "2.6L Rotary",
		Description	 = "4 rotor racing Wankel, high revving and high strung.",
		Model		 = "models/engines/wankel_4_med.mdl",
		Sound		 = "acf_base/engines/wankel_large.wav",
		Fuel		 = { Petrol = true },
		Type		 = "Wankel",
		Mass		 = 260,
		Torque		 = 250,
		FlywheelMass = 0.11,
		RPM = {
			Idle	= 1200,
			PeakMin	= 4500,
			PeakMax	= 9000,
			Limit	= 9500,
		}
	})
end

do -- Special I2 Engines
	ACF.RegisterEngine("0.9L-I2", "SP", {
		Name		 = "0.9L I2 Petrol",
		Description	 = "Turbocharged inline twin engine that delivers surprising pep for its size.",
		Model		 = "models/engines/inline2s.mdl",
		Sound		 = "acf_extra/vehiclefx/engines/ponyengine.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 60,
		Torque		 = 116,
		FlywheelMass = 0.085,
		RPM = {
			Idle	= 750,
			PeakMin	= 3125,
			PeakMax	= 5100,
			Limit	= 6000,
		}
	})
end

do -- Special I4 Engines
	ACF.RegisterEngine("1.0L-I4", "SP", {
		Name		 = "1.0L I4 Petrol",
		Description	 = "Tiny I4 designed for racing bikes. Doesn't pack much torque, but revs ludicrously high.",
		Model		 = "models/engines/inline4s.mdl",
		Sound		 = "acf_extra/vehiclefx/engines/l4/mini_onhigh.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 78,
		Torque		 = 68,
		FlywheelMass = 0.031,
		Pitch		 = 0.75,
		RPM = {
			Idle	= 1200,
			PeakMin	= 7500,
			PeakMax	= 11500,
			Limit	= 12000,
		}
	})

	ACF.RegisterEngine("1.9L-I4", "SP", {
		Name		 = "1.9L I4 Petrol",
		Description	 = "Supercharged racing 4 cylinder, most of the power in the high revs.",
		Model		 = "models/engines/inline4s.mdl",
		Sound		 = "acf_base/engines/i4_special.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 150,
		Torque		 = 176,
		FlywheelMass = 0.06,
		RPM = {
			Idle	= 950,
			PeakMin	= 5200,
			PeakMax	= 8500,
			Limit	= 9000,
		}
	})
end

do -- Special V4 Engines
	ACF.RegisterEngine("1.8L-V4", "SP", {
		Name		 = "1.8L V4 Petrol",
		Description	 = "Naturally aspirated rally-tuned V4 with enlarged bore and stroke.",
		Model		 = "models/engines/v4s.mdl",
		Sound		 = "acf_extra/vehiclefx/engines/l4/elan_onlow.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 92,
		Torque		 = 124.8,
		FlywheelMass = 0.04,
		RPM = {
			Idle	= 900,
			PeakMin	= 4600,
			PeakMax	= 7000,
			Limit	= 7500,
		}
	})
end

do -- Special I6 Engines
	ACF.RegisterEngine("3.8-I6", "SP", {
		Name		 = "3.8L I6 Petrol",
		Description	 = "Large racing straight six, powerful and high revving, but lacking in torque.",
		Model		 = "models/engines/inline6m.mdl",
		Sound		 = "acf_base/engines/l6_special.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 180,
		Torque		 = 224,
		FlywheelMass = 0.1,
		RPM = {
			Idle	= 1100,
			PeakMin	= 5200,
			PeakMax	= 8500,
			Limit	= 9000,
		}
	})
end

do -- Special V6 Engines
	ACF.RegisterEngine("2.4L-V6", "SP", {
		Name		 = "2.4L V6 Petrol",
		Description	 = "Although the cast iron engine block is fairly weighty, this tiny v6 makes up for it with impressive power.  The unique V angle allows uncharacteristically high RPM for a V6.",
		Model		 = "models/engines/v6small.mdl",
		Sound		 = "acf_extra/vehiclefx/engines/l6/capri_onmid.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 134,
		Torque		 = 172,
		FlywheelMass = 0.075,
		RPM = {
			Idle	= 950,
			PeakMin	= 4500,
			PeakMax	= 7100,
			Limit	= 8000,
		}
	})
end

do -- Special V8 Engines
	ACF.RegisterEngine("2.9-V8", "SP", {
		Name		 = "2.9L V8 Petrol",
		Description	 = "Racing V8, very high revving and loud",
		Model		 = "models/engines/v8s.mdl",
		Sound		 = "acf_base/engines/v8_special.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 180,
		Torque		 = 200,
		FlywheelMass = 0.075,
		RPM = {
			Idle	= 1000,
			PeakMin	= 5500,
			PeakMax	= 9000,
			Limit	= 10000,
		}
	})

	ACF.RegisterEngine("7.2-V8", "SP", {
		Name		 = "7.2L V8 Petrol",
		Description	 = "Very high revving, glorious v8 of ear rapetasticalness.",
		Model		 = "models/engines/v8m.mdl",
		Sound		 = "acf_base/engines/v8_special2.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 400,
		Torque		 = 340,
		FlywheelMass = 0.15,
		RPM = {
			Idle	= 1000,
			PeakMin	= 5000,
			PeakMax	= 8000,
			Limit	= 8500,
		}
	})
end

do -- Special V10 Engines
	ACF.RegisterEngine("5.3-V10", "SP", {
		Name		 = "5.3L V10 Special",
		Description	 = "Extreme performance v10",
		Model		 = "models/engines/v10sml.mdl",
		Sound		 = "acf_base/engines/v10_special.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 300,
		Torque		 = 320,
		FlywheelMass = 0.15,
		RPM = {
			Idle	= 1100,
			PeakMin	= 5750,
			PeakMax	= 8000,
			Limit	= 9000,
		}
	})
end

do -- Special V12 Engines
	ACF.RegisterEngine("3.0-V12", "SP", {
		Name		 = "3.0L V12 Petrol",
		Description	 = "A purpose-built racing v12, not known for longevity.",
		Model		 = "models/engines/v12s.mdl",
		Sound		 = "acf_extra/vehiclefx/engines/v12/gtb4_onmid.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 175,
		Torque		 = 248,
		FlywheelMass = 0.1,
		Pitch		 = 0.85,
		RPM = {
			Idle	= 1200,
			PeakMin	= 6875,
			PeakMax	= 11000,
			Limit	= 12500,
		}
	})
end
