
-- Radial engines

ACF.RegisterEngineClass("R7", {
	Name = "Radial 7 Engine",
})

do
	ACF.RegisterEngine("3.8-R7", "R7", {
		Name		 = "3.8L R7 Petrol",
		Description	 = "A tiny, old worn-out radial.",
		Model		 = "models/engines/radial7s.mdl",
		Sound		 = "acf_base/engines/r7_petrolsmall.wav",
		Fuel		 = { Petrol = true },
		Type		 = "Radial",
		Mass		 = 210,
		Torque		 = 387,
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
		Sound		 = "acf_base/engines/r7_petrolmedium.wav",
		Fuel		 = { Petrol = true },
		Type		 = "Radial",
		Mass		 = 385,
		Torque		 = 700,
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
		Sound		 = "acf_base/engines/r7_petrolmedium.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 450,
		Torque		 = 1000,
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
		Sound		 = "acf_base/engines/r7_petrollarge.wav",
		Fuel		 = { Petrol = true },
		Type		 = "Radial",
		Mass		 = 952,
		Torque		 = 2018,
		FlywheelMass = 3.4,
		RPM = {
			Idle	= 750,
			PeakMin	= 1900,
			PeakMax	= 3150,
			Limit	= 3500,
		}
	})
end

ACF.SetCustomAttachment("models/engines/radial7l.mdl", "driveshaft", Vector(-12), Angle(0, 180, 90))
ACF.SetCustomAttachment("models/engines/radial7m.mdl", "driveshaft", Vector(-8), Angle(0, 180, 90))
ACF.SetCustomAttachment("models/engines/radial7s.mdl", "driveshaft", Vector(-6), Angle(0, 180, 90))
