local ACF     = ACF
local Engines = ACF.Classes.Engines


Engines.Register("SP", {
	Name = "Special Engine",
})

do -- Special Rotary Engines
	Engines.RegisterItem("2.6L-Wankel", "SP", {
		Name		 = "2.6L Rotary",
		Description	 = "4 rotor racing Wankel, high revving and high strung.",
		Model		 = "models/engines/wankel_4_med.mdl",
		Sound		 = "acf_base/engines/wankel_large.wav",
		Fuel		 = { Petrol = true },
		Type		 = "Wankel",
		Mass		 = 260,
		Torque		 = 312,
		FlywheelMass = 0.11,
		RPM = {
			Idle	= 1200,
			Limit	= 9500,
		},
		Preview = {
			FOV = 100,
		},
	})
end

do -- Special I2 Engines
	Engines.RegisterItem("0.9L-I2", "SP", {
		Name		 = "0.9L I2 Petrol",
		Description	 = "Turbocharged inline twin engine that delivers surprising pep for its size.",
		Model		 = "models/engines/inline2s.mdl",
		Sound		 = "acf_extra/vehiclefx/engines/ponyengine.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 60,
		Torque		 = 145,
		FlywheelMass = 0.085,
		RPM = {
			Idle	= 750,
			Limit	= 6000,
		},
		Preview = {
			FOV = 125,
		},
	})
end

do -- Special I4 Engines
	Engines.RegisterItem("1.0L-I4", "SP", {
		Name		 = "1.0L I4 Petrol",
		Description	 = "Tiny I4 designed for racing bikes. Doesn't pack much torque, but revs ludicrously high.",
		Model		 = "models/engines/inline4s.mdl",
		Sound		 = "acf_extra/vehiclefx/engines/l4/mini_onhigh.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 78,
		Torque		 = 85,
		FlywheelMass = 0.031,
		Pitch		 = 0.75,
		RPM = {
			Idle	= 1200,
			Limit	= 12000,
		},
		Preview = {
			FOV = 120,
		},
	})

	Engines.RegisterItem("1.9L-I4", "SP", {
		Name		 = "1.9L I4 Petrol",
		Description	 = "Supercharged racing 4 cylinder, most of the power in the high revs.",
		Model		 = "models/engines/inline4s.mdl",
		Sound		 = "acf_base/engines/i4_special.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 150,
		Torque		 = 220,
		FlywheelMass = 0.06,
		RPM = {
			Idle	= 950,
			Limit	= 9000,
		},
		Preview = {
			FOV = 120,
		},
	})
end

do -- Special V4 Engines
	Engines.RegisterItem("1.8L-V4", "SP", {
		Name		 = "1.8L V4 Petrol",
		Description	 = "Naturally aspirated rally-tuned V4 with enlarged bore and stroke.",
		Model		 = "models/engines/v4s.mdl",
		Sound		 = "acf_extra/vehiclefx/engines/l4/elan_onlow.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 92,
		Torque		 = 156,
		FlywheelMass = 0.04,
		RPM = {
			Idle	= 900,
			Limit	= 7500,
		},
		Preview = {
			FOV = 110,
		},
	})
end

do -- Special I6 Engines
	Engines.RegisterItem("3.8-I6", "SP", {
		Name		 = "3.8L I6 Petrol",
		Description	 = "Large racing straight six, powerful and high revving, but lacking in torque.",
		Model		 = "models/engines/inline6m.mdl",
		Sound		 = "acf_base/engines/l6_special.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 180,
		Torque		 = 280,
		FlywheelMass = 0.1,
		RPM = {
			Idle	= 1100,
			Limit	= 9000,
		},
		Preview = {
			FOV = 112,
		},
	})
end

do -- Special V6 Engines
	Engines.RegisterItem("2.4L-V6", "SP", {
		Name		 = "2.4L V6 Petrol",
		Description	 = "Although the cast iron engine block is fairly weighty, this tiny v6 makes up for it with impressive power. The unique V angle allows uncharacteristically high RPM for a V6.",
		Model		 = "models/engines/v6small.mdl",
		Sound		 = "acf_extra/vehiclefx/engines/l6/capri_onmid.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 134,
		Torque		 = 215,
		FlywheelMass = 0.075,
		RPM = {
			Idle	= 950,
			Limit	= 8000,
		},
		Preview = {
			FOV = 105,
		},
	})
end

do -- Special V8 Engines
	Engines.RegisterItem("2.9-V8", "SP", {
		Name		 = "2.9L V8 Petrol",
		Description	 = "Racing V8, very high revving and loud",
		Model		 = "models/engines/v8s.mdl",
		Sound		 = "acf_base/engines/v8_special.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 180,
		Torque		 = 250,
		FlywheelMass = 0.075,
		RPM = {
			Idle	= 1000,
			Limit	= 10000,
		},
		Preview = {
			FOV = 100,
		},
	})

	Engines.RegisterItem("7.2-V8", "SP", {
		Name		 = "7.2L V8 Petrol",
		Description	 = "Very high revving, glorious v8 of ear rapetasticalness.",
		Model		 = "models/engines/v8m.mdl",
		Sound		 = "acf_base/engines/v8_special2.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 400,
		Torque		 = 425,
		FlywheelMass = 0.15,
		RPM = {
			Idle	= 1000,
			Limit	= 8500,
		},
		Preview = {
			FOV = 100,
		},
	})
end

do -- Special V10 Engines
	Engines.RegisterItem("5.3-V10", "SP", {
		Name		 = "5.3L V10 Special",
		Description	 = "Extreme performance v10",
		Model		 = "models/engines/v10sml.mdl",
		Sound		 = "acf_base/engines/v10_special.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 300,
		Torque		 = 400,
		FlywheelMass = 0.15,
		RPM = {
			Idle	= 1100,
			Limit	= 9000,
		},
		Preview = {
			FOV = 100,
		},
	})
end

do -- Special V12 Engines
	Engines.RegisterItem("3.0-V12", "SP", {
		Name		 = "3.0L V12 Petrol",
		Description	 = "A purpose-built racing v12, not known for longevity.",
		Model		 = "models/engines/v12s.mdl",
		Sound		 = "acf_extra/vehiclefx/engines/v12/gtb4_onmid.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 175,
		Torque		 = 310,
		FlywheelMass = 0.1,
		Pitch		 = 0.85,
		RPM = {
			Idle	= 1200,
			Limit	= 12500,
		},
		Preview = {
			FOV = 95,
		},
	})
end
