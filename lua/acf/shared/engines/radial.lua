
-- Radial engines

ACF_DefineEngine( "3.8-R7", {
	name = "3.8L R7 Petrol",
	desc = "A tiny, old worn-out radial.",
	model = "models/engines/radial7s.mdl",
	sound = "acf_engines/r7_petrolsmall.wav",
	category = "Radial",
	fuel = "Petrol",
	enginetype = "Radial",
	weight = 210,
	torque = 310,
	flywheelmass = 0.22,
	idlerpm = 700,
	peakminrpm = 2600,
	peakmaxrpm = 4350,
	limitrpm = 4800
} )

ACF_DefineEngine( "11.0-R7", {
	name = "11.0 R7 Petrol",
	desc = "Mid range radial, thirsty and smooth",
	model = "models/engines/radial7m.mdl",
	sound = "acf_engines/r7_petrolmedium.wav",
	category = "Radial",
	fuel = "Petrol",
	enginetype = "Radial",
	weight = 385,
	torque = 560,
	flywheelmass = 0.45,
	idlerpm = 600,
	peakminrpm = 2300,
	peakmaxrpm = 3850,
	limitrpm = 4400
} )


ACF_DefineEngine( "8.0-R7", {
	name = "8.0 R7 Diesel",
	desc = "Military-grade radial engine, similar to a ZO 02A.  Heavy and with a narrow powerband, but efficient, and well-optimized to cruising.",
	model = "models/engines/radial7m.mdl",
	sound = "acf_engines/r7_petrolmedium.wav",
	category = "Radial",
	fuel = "Multifuel",
	enginetype = "GenericDiesel",
	weight = 450,
	torque = 800,
	flywheelmass = 1.0,
	idlerpm = 400,
	peakminrpm = 2200,
	peakmaxrpm = 2500,
	limitrpm = 2800
} )

ACF_DefineEngine( "24.0-R7", {
	name = "24.0L R7 Petrol",
	desc = "Massive American radial monster, destined for fighter aircraft and heavy tanks.",
	model = "models/engines/radial7l.mdl",
	sound = "acf_engines/r7_petrollarge.wav",
	category = "Radial",
	fuel = "Petrol",
	enginetype = "Radial",
	weight = 952,
	torque = 1615,
	flywheelmass = 3.4,
	idlerpm = 750,
	peakminrpm = 1900,
	peakmaxrpm = 3150,
	limitrpm = 3500
} )

ACF.RegisterEngineClass("R7", {
	Name = "Radial 7 Engine",
})

do
	ACF.RegisterEngine("3.8-R7", "R7", {
		Name		 = "3.8L R7 Petrol",
		Description	 = "A tiny, old worn-out radial.",
		Model		 = "models/engines/radial7s.mdl",
		Sound		 = "acf_engines/r7_petrolsmall.wav",
		Fuel		 = { Petrol = true },
		Type		 = "Radial",
		Mass		 = 210,
		Torque		 = 310,
		FlywheelMass = 0.22,
		RPM = {
			Idle	= 700,
			PeakMin	= 2600,
			PeakMax	= 4350,
			Limit	= 4800,
		}
	})

	ACF.RegisterEngine("11.0-R7", "R7", {
		Name		 = "11.0L R7 Petrol",
		Description	 = "Mid range radial, thirsty and smooth.",
		Model		 = "models/engines/radial7m.mdl",
		Sound		 = "acf_engines/r7_petrolmedium.wav",
		Fuel		 = { Petrol = true },
		Type		 = "Radial",
		Mass		 = 385,
		Torque		 = 560,
		FlywheelMass = 0.45,
		RPM = {
			Idle	= 600,
			PeakMin	= 2300,
			PeakMax	= 3850,
			Limit	= 4400,
		}
	})

	ACF.RegisterEngine("8.0-R7", "R7", {
		Name		 = "8.0L R7 Diesel",
		Description	 = "Heavy and with a narrow powerband, but efficient, and well-optimized to cruising.",
		Model		 = "models/engines/radial7m.mdl",
		Sound		 = "acf_engines/r7_petrolmedium.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 450,
		Torque		 = 800,
		FlywheelMass = 1,
		RPM = {
			Idle	= 400,
			PeakMin	= 2200,
			PeakMax	= 2500,
			Limit	= 2800,
		}
	})

	ACF.RegisterEngine("24.0-R7", "R7", {
		Name		 = "24.0L R7 Petrol",
		Description	 = "Massive American radial monster, destined for fighter aircraft and heavy tanks.",
		Model		 = "models/engines/radial7l.mdl",
		Sound		 = "acf_engines/r7_petrollarge.wav",
		Fuel		 = { Petrol = true },
		Type		 = "Radial",
		Mass		 = 952,
		Torque		 = 1615,
		FlywheelMass = 3.4,
		RPM = {
			Idle	= 750,
			PeakMin	= 1900,
			PeakMax	= 3150,
			Limit	= 3500,
		}
	})
end