
-- Electric motors

ACF_DefineEngine( "Electric-Small", {
	name = "Electric motor, Small",
	desc = "A small electric motor, loads of torque, but low power\n\nElectric motors provide huge amounts of torque, but are very heavy",
	model = "models/engines/emotorsmall.mdl",
	sound = "acf_engines/electric_small.wav",
	category = "Electric",
	fuel = "Electric",
	enginetype = "Electric",
	weight = 250,
	torque = 384,
	flywheelmass = 0.3,
	idlerpm = 10,
	peakminrpm = 1,
	peakmaxrpm = 1,
	limitrpm = 10000,
	iselec = true,
	flywheeloverride = 5000
} )

ACF_DefineEngine( "Electric-Medium", {
	name = "Electric motor, Medium",
	desc = "A medium electric motor, loads of torque, but low power\n\nElectric motors provide huge amounts of torque, but are very heavy",
	model = "models/engines/emotormed.mdl",
	sound = "acf_engines/electric_medium.wav",
	category = "Electric",
	fuel = "Electric",
	enginetype = "Electric",
	weight = 850,
	torque = 1152,
	flywheelmass = 1.5,
	idlerpm = 10,
	peakminrpm = 1,
	peakmaxrpm = 1,
	limitrpm = 7000,
	iselec = true,
	flywheeloverride = 8000
} )

ACF_DefineEngine( "Electric-Large", {
	name = "Electric motor, Large",
	desc = "A huge electric motor, loads of torque, but low power\n\nElectric motors provide huge amounts of torque, but are very heavy",
	model = "models/engines/emotorlarge.mdl",
	sound = "acf_engines/electric_large.wav",
	category = "Electric",
	fuel = "Electric",
	enginetype = "Electric",
	weight = 1900,
	torque = 3360,
	flywheelmass = 11.2,
	idlerpm = 10,
	peakminrpm = 1,
	peakmaxrpm = 1,
	limitrpm = 4500,
	iselec = true,
	flywheeloverride = 6000
} )

ACF_DefineEngine( "Electric-Tiny-NoBatt", {
	name = "Electric motor, Tiny, Standalone",
	desc = "A pint-size electric motor, for the lightest of light utility work.  Can power electric razors, desk fans, or your hopes and dreams\n\nElectric motors provide huge amounts of torque, but are very heavy.\n\nStandalone electric motors don't have integrated batteries, saving on weight and volume, but require you to supply your own batteries.",
	model = "models/engines/emotor-standalone-tiny.mdl",
	sound = "acf_engines/electric_small.wav",
	category = "Electric",
	fuel = "Electric",
	enginetype = "Electric",
	requiresfuel = true,
	weight = 50, --250
	torque = 40,
	flywheelmass = 0.025,
	idlerpm = 10,
	peakminrpm = 1,
	peakmaxrpm = 1,
	limitrpm = 10000,
	iselec = true,
	flywheeloverride = 500
} )

ACF_DefineEngine( "Electric-Small-NoBatt", {
	name = "Electric motor, Small, Standalone",
	desc = "A small electric motor, loads of torque, but low power\n\nElectric motors provide huge amounts of torque, but are very heavy.\n\nStandalone electric motors don't have integrated batteries, saving on weight and volume, but require you to supply your own batteries.",
	model = "models/engines/emotor-standalone-sml.mdl",
	sound = "acf_engines/electric_small.wav",
	category = "Electric",
	fuel = "Electric",
	enginetype = "Electric",
	requiresfuel = true,
	weight = 125, --250
	torque = 384,
	flywheelmass = 0.3,
	idlerpm = 10,
	peakminrpm = 1,
	peakmaxrpm = 1,
	limitrpm = 10000,
	iselec = true,
	flywheeloverride = 5000
} )

ACF_DefineEngine( "Electric-Medium-NoBatt", {
	name = "Electric motor, Medium, Standalone",
	desc = "A medium electric motor, loads of torque, but low power\n\nElectric motors provide huge amounts of torque, but are very heavy.\n\nStandalone electric motors don't have integrated batteries, saving on weight and volume, but require you to supply your own batteries.",
	model = "models/engines/emotor-standalone-mid.mdl",
	sound = "acf_engines/electric_medium.wav",
	category = "Electric",
	fuel = "Electric",
	enginetype = "Electric",
	requiresfuel = true,
	weight = 575, --800
	torque = 1152,
	flywheelmass = 1.5,
	idlerpm = 10,
	peakminrpm = 1,
	peakmaxrpm = 1,
	limitrpm = 7000,
	iselec = true,
	flywheeloverride = 8000
} )

ACF_DefineEngine( "Electric-Large-NoBatt", {
	name = "Electric motor, Large, Standalone",
	desc = "A huge electric motor, loads of torque, but low power\n\nElectric motors provide huge amounts of torque, but are very heavy.\n\nStandalone electric motors don't have integrated batteries, saving on weight and volume, but require you to supply your own batteries.",
	model = "models/engines/emotor-standalone-big.mdl",
	sound = "acf_engines/electric_large.wav",
	category = "Electric",
	fuel = "Electric",
	enginetype = "Electric",
	requiresfuel = true,
	weight = 1500, --1900
	torque = 3360,
	flywheelmass = 11.2,
	idlerpm = 10,
	peakminrpm = 1,
	peakmaxrpm = 1,
	limitrpm = 4500,
	iselec = true,
	flywheeloverride = 6000
} )

do -- Electric Motors
	ACF.RegisterEngineClass("EL", {
		Name		= "Electric Motor",
		Description	= "Electric motors provide huge amounts of torque, but are very heavy.",
	})

	ACF.RegisterEngine("Electric-Small", "EL", {
		Name		 = "Small Electric Motor",
		Description	 = "A small electric motor, loads of torque, but low power.",
		Model		 = "models/engines/emotorsmall.mdl",
		Sound		 = "acf_engines/electric_small.wav",
		Fuel		 = { Electric = true },
		Type		 = "Electric",
		Mass		 = 250,
		Torque		 = 384,
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
		Sound		 = "acf_engines/electric_medium.wav",
		Fuel		 = { Electric = true },
		Type		 = "Electric",
		Mass		 = 850,
		Torque		 = 1152,
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
		Sound		 = "acf_engines/electric_large.wav",
		Fuel		 = { Electric = true },
		Type		 = "Electric",
		Mass		 = 1900,
		Torque		 = 3360,
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

	ACF.RegisterEngine("Electric-Small-NoBatt", "EL-S", {
		Name		 = "Small Electric Standalone Motor",
		Description	 = "A small standalone electric motor, loads of torque, but low power.",
		Model		 = "models/engines/emotor-standalone-sml.mdl",
		Sound		 = "acf_engines/electric_small.wav",
		Fuel		 = { Electric = true },
		Type		 = "Electric",
		Mass		 = 125,
		Torque		 = 384,
		FlywheelMass = 0.3,
		IsElectric	 = true,
		RequiresFuel = true,
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
		Sound		 = "acf_engines/electric_medium.wav",
		Fuel		 = { Electric = true },
		Type		 = "Electric",
		Mass		 = 575,
		Torque		 = 1152,
		FlywheelMass = 1.5,
		IsElectric	 = true,
		RequiresFuel = true,
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
		Sound		 = "acf_engines/electric_large.wav",
		Fuel		 = { Electric = true },
		Type		 = "Electric",
		Mass		 = 1500,
		Torque		 = 3360,
		FlywheelMass = 11.2,
		IsElectric	 = true,
		RequiresFuel = true,
		RPM = {
			Idle	 = 10,
			PeakMin	 = 1,
			PeakMax	 = 1,
			Limit	 = 4500,
			Override = 6000,
		}
	})
end
