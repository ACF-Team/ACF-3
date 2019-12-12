
-- Flat 4 engines

ACF_DefineEngine( "1.4-B4", {
	name = "1.4L Flat 4 Petrol",
	desc = "Small air cooled flat four, most commonly found in nazi insects",
	model = "models/engines/b4small.mdl",
	sound = "acf_engines/b4_petrolsmall.wav",
	category = "B4",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 60,
	torque = 105,
	flywheelmass = 0.06,
	idlerpm = 600,
	peakminrpm = 2600,
	peakmaxrpm = 4200,
	limitrpm = 4500
} )

ACF_DefineEngine( "2.1-B4", {
	name = "2.1L Flat 4 Petrol",
	desc = "Tuned up flat four, probably find this in things that go fast in a desert.",
	model = "models/engines/b4small.mdl",
	sound = "acf_engines/b4_petrolmedium.wav",
	category = "B4",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 125,
	torque = 180,
	flywheelmass = 0.15,
	idlerpm = 700,
	peakminrpm = 3000,
	peakmaxrpm = 4800,
	limitrpm = 5000
} )

ACF_DefineEngine( "3.2-B4", {
	name = "3.2L Flat 4 Petrol",
	desc = "Bored out fuckswindleton batshit flat four. Fuck yourself.",
	model = "models/engines/b4med.mdl",
	sound = "acf_engines/b4_petrollarge.wav",
	category = "B4",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 210,
	torque = 252,
	flywheelmass = 0.15,
	idlerpm = 900,
	peakminrpm = 3400,
	peakmaxrpm = 5500,
	limitrpm = 6500
} )

ACF_DefineEngine( "2.4-B4", {
	name = "2.4L Flat 4 Multifuel",
	desc = "Tiny military-grade multifuel. Heavy, but grunts hard.",
	model = "models/engines/b4small.mdl",
	sound = "acf_extra/vehiclefx/engines/coh/ba11.wav",
	category = "B4",
	fuel = "Multifuel",
	enginetype = "GenericDiesel",
	weight = 135,
	torque = 248,
	flywheelmass = 0.4,
	idlerpm = 550,
	peakminrpm = 1250,
	peakmaxrpm = 2650,
	limitrpm = 2800
} )
