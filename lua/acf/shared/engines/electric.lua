
-- Electric motors

do -- Electric Motors
	ACF.RegisterEngineClass("EL", {
		Name		= "Electric Motor",
		Description	= "Electric motors provide huge amounts of torque, but are very heavy.",
	})

	ACF.RegisterEngine("Electric-Small", "EL", {
		Name		 = "Small Electric Motor",
		Description	 = "A small electric motor, loads of torque, but low power.",
		Model		 = "models/engines/emotorsmall.mdl",
		Sound		 = "acf_base/engines/electric_small.wav",
		Fuel		 = { Electric = true },
		Type		 = "Electric",
		Mass		 = 250,
		Torque		 = 480,
		FlywheelMass = 0.3,
		IsElectric	 = true,
		RPM = {
			Idle	 = 10,
			PeakMin	 = 1,
			PeakMax	 = 1,
			Limit	 = 10000,
			Override = 5000,
		},
	})

	ACF.RegisterEngine("Electric-Medium", "EL", {
		Name		 = "Medium Electric Motor",
		Description	 = "A medium electric motor, loads of torque, but low power.",
		Model		 = "models/engines/emotormed.mdl",
		Sound		 = "acf_base/engines/electric_medium.wav",
		Fuel		 = { Electric = true },
		Type		 = "Electric",
		Mass		 = 850,
		Torque		 = 1440,
		FlywheelMass = 1.5,
		IsElectric	 = true,
		RPM = {
			Idle	 = 10,
			PeakMin	 = 1,
			PeakMax	 = 1,
			Limit	 = 7000,
			Override = 8000,
		}
	})

	ACF.RegisterEngine("Electric-Large", "EL", {
		Name		 = "Large Electric Motor",
		Description	 = "A huge electric motor, loads of torque, but low power.",
		Model		 = "models/engines/emotorlarge.mdl",
		Sound		 = "acf_base/engines/electric_large.wav",
		Fuel		 = { Electric = true },
		Type		 = "Electric",
		Mass		 = 1900,
		Torque		 = 4200,
		FlywheelMass = 11.2,
		IsElectric	 = true,
		RPM = {
			Idle	 = 10,
			PeakMin	 = 1,
			PeakMax	 = 1,
			Limit	 = 4500,
			Override = 6000,
		},
	})
end

do -- Electric Standalone Motors
	ACF.RegisterEngineClass("EL-S", {
		Name		= "Electric Standalone Motor",
		Description	= "Electric motors provide huge amounts of torque, but are very heavy. Standalones also require external batteries.",
	})

	ACF.RegisterEngine("Electric-Tiny-NoBatt", "EL-S", {
		Name		 = "Tiny Electric Standalone Motor",
		Description	 = "A pint-size electric motor, for the lightest of light utility work. Can power electric razors, desk fans, or your hopes and dreams.",
		Model		 = "models/engines/emotor-standalone-tiny.mdl",
		Sound		 = "acf_base/engines/electric_small.wav",
		Fuel		 = { Electric = true },
		Type		 = "Electric",
		Mass		 = 50,
		Torque		 = 40,
		FlywheelMass = 0.025,
		IsElectric	 = true,
		RPM = {
			Idle	 = 10,
			PeakMin	 = 1,
			PeakMax	 = 1,
			Limit	 = 10000,
			Override = 500,
		},
	})

	ACF.RegisterEngine("Electric-Small-NoBatt", "EL-S", {
		Name		 = "Small Electric Standalone Motor",
		Description	 = "A small standalone electric motor, loads of torque, but low power.",
		Model		 = "models/engines/emotor-standalone-sml.mdl",
		Sound		 = "acf_base/engines/electric_small.wav",
		Fuel		 = { Electric = true },
		Type		 = "Electric",
		Mass		 = 125,
		Torque		 = 384,
		FlywheelMass = 0.3,
		IsElectric	 = true,
		RPM = {
			Idle	 = 10,
			PeakMin	 = 1,
			PeakMax	 = 1,
			Limit	 = 10000,
			Override = 5000,
		}
	})

	ACF.RegisterEngine("Electric-Medium-NoBatt", "EL-S", {
		Name		 = "Medium Electric Standalone Motor",
		Description	 = "A medium standalone electric motor, loads of torque, but low power.",
		Model		 = "models/engines/emotor-standalone-mid.mdl",
		Sound		 = "acf_base/engines/electric_medium.wav",
		Fuel		 = { Electric = true },
		Type		 = "Electric",
		Mass		 = 575,
		Torque		 = 1152,
		FlywheelMass = 1.5,
		IsElectric	 = true,
		RPM = {
			Idle	 = 10,
			PeakMin	 = 1,
			PeakMax	 = 1,
			Limit	 = 7000,
			Override = 8000,
		},
	})

	ACF.RegisterEngine("Electric-Large-NoBatt", "EL-S", {
		Name		 = "Large Electric Standalone Motor",
		Description	 = "A huge standalone electric motor, loads of torque, but low power.",
		Model		 = "models/engines/emotor-standalone-big.mdl",
		Sound		 = "acf_base/engines/electric_large.wav",
		Fuel		 = { Electric = true },
		Type		 = "Electric",
		Mass		 = 1500,
		Torque		 = 3360,
		FlywheelMass = 11.2,
		IsElectric	 = true,
		RPM = {
			Idle	 = 10,
			PeakMin	 = 1,
			PeakMax	 = 1,
			Limit	 = 4500,
			Override = 6000,
		}
	})
end
