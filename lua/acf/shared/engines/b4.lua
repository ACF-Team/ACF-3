
-- Flat 4 engines

ACF.RegisterEngineClass("B4", {
	Name = "Flat 4 Engine",
})

do
	ACF.RegisterEngine("1.4-B4", "B4", {
		Name		 = "1.4L Flat 4 Petrol",
		Description	 = "Small air cooled flat four, most commonly found in nazi insects",
		Model		 = "models/engines/b4small.mdl",
		Sound		 = "acf_base/engines/b4_petrolsmall.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 60,
		Torque		 = 131,
		FlywheelMass = 0.06,
		RPM = {
			Idle	= 600,
			PeakMin	= 2600,
			PeakMax	= 4200,
			Limit	= 4500,
		},
	})

	ACF.RegisterEngine("2.1-B4", "B4", {
		Name		 = "2.1L Flat 4 Petrol",
		Description	 = "Tuned up flat four, probably find this in things that go fast in a desert.",
		Model		 = "models/engines/b4small.mdl",
		Sound		 = "acf_base/engines/b4_petrolmedium.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 125,
		Torque		 = 225,
		FlywheelMass = 0.15,
		RPM = {
			Idle	= 700,
			PeakMin	= 3000,
			PeakMax	= 4800,
			Limit	= 5000,
		},
	})

	ACF.RegisterEngine("2.4-B4", "B4", {
		Name		 = "2.4L Flat 4 Multifuel",
		Description	 = "Tiny military-grade multifuel. Heavy, but grunts hard.",
		Model		 = "models/engines/b4small.mdl",
		Sound		 = "acf_extra/vehiclefx/engines/coh/ba11.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 135,
		Torque		 = 310,
		FlywheelMass = 0.4,
		RPM = {
			Idle	= 550,
			PeakMin	= 1250,
			PeakMax	= 2650,
			Limit	= 2800,
		},
	})

	ACF.RegisterEngine("3.2-B4", "B4", {
		Name		 = "3.2L Flat 4 Petrol",
		Description	 = "Bored out fuckswindleton batshit flat four. Fuck yourself.",
		Model		 = "models/engines/b4med.mdl",
		Sound		 = "acf_base/engines/b4_petrollarge.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 210,
		Torque		 = 315,
		FlywheelMass = 0.15,
		RPM = {
			Idle	= 900,
			PeakMin	= 3400,
			PeakMax	= 5500,
			Limit	= 6500
		},
	})
end

ACF.SetCustomAttachment("models/engines/b4med.mdl", "driveshaft", Vector(), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/engines/b4small.mdl", "driveshaft", Vector(), Angle(0, 0, 90))
