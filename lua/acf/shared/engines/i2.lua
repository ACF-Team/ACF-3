
-- Inline 2 engines

ACF.RegisterEngineClass("I2", {
	Name = "Inline 2 Engine",
})

do
	ACF.RegisterEngine("0.8L-I2", "I2", {
		Name		 = "0.8L I2 Diesel",
		Description	 = "For when a 3 banger is still too bulky for your micro-needs.",
		Model		 = "models/engines/inline2s.mdl",
		Sound		 = "acf_base/engines/i4_diesel2.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 45,
		Torque		 = 131,
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
		Sound		 = "acf_base/engines/vtwin_large.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 800,
		Torque		 = 2500,
		FlywheelMass = 7,
		RPM = {
			Idle	= 350,
			PeakMin	= 450,
			PeakMax	= 900,
			Limit	= 1200,
		}
	})
end
