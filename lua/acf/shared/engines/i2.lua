
-- Inline 2 engines

ACF_DefineEngine( "0.8L-I2", {
	name = "0.8L I2 Diesel",
	desc = "For when a 3 banger is still too bulky for your micro-needs",
	model = "models/engines/inline2s.mdl",
	sound = "acf_engines/i4_diesel2.wav",
	category = "I2",
	fuel = "Diesel",
	enginetype = "GenericDiesel",
	weight = 45,
	torque = 105,
	flywheelmass = 0.12,
	idlerpm = 500,
	peakminrpm = 750,
	peakmaxrpm = 2450,
	limitrpm = 2950
} )



ACF_DefineEngine( "10.0-I2", {
	name = "10.0L I2 Diesel",
	desc = "TORQUE.",
	model = "models/engines/inline2b.mdl",
	sound = "acf_engines/vtwin_large.wav",
	category = "I2",
	fuel = "Diesel",
	enginetype = "GenericDiesel",
	weight = 800,
	torque = 2000,
	flywheelmass = 7,
	idlerpm = 350,
	peakminrpm = 450,
	peakmaxrpm = 900,
	limitrpm = 1200
} )

ACF.RegisterEngineClass("I2", {
	Name = "Inline 2 Engine",
})

do
	ACF.RegisterEngine("0.8L-I2", "I2", {
		Name		 = "0.8L I2 Diesel",
		Description	 = "For when a 3 banger is still too bulky for your micro-needs.",
		Model		 = "models/engines/inline2s.mdl",
		Sound		 = "acf_engines/i4_diesel2.wav",
		Fuel		 = "Diesel",
		Type		 = "GenericDiesel",
		Mass		 = 45,
		Torque		 = 105,
		FlywheelMass = 0.12,
		RPM = {
			Idle	= 500,
			PeakMin	= 750,
			PeakMax	= 2450,
			Limit	= 2950,
		}
	})

	ACF.RegisterEngine("10.0-I2", "I2", {
		Name		 = "10.0L I2 Diesel",
		Description	 = "TORQUE.",
		Model		 = "models/engines/inline2b.mdl",
		Sound		 = "acf_engines/vtwin_large.wav",
		Fuel		 = "Diesel",
		Type		 = "GenericDiesel",
		Mass		 = 800,
		Torque		 = 2000,
		FlywheelMass = 7,
		RPM = {
			Idle	= 350,
			PeakMin	= 450,
			PeakMax	= 900,
			Limit	= 1200,
		}
	})
end
