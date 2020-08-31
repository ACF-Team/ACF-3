
-- Flat 6 engines

ACF_DefineEngine( "2.8-B6", {
	name = "2.8L Flat 6 Petrol",
	desc = "Car sized flat six engine, sporty and light",
	model = "models/engines/b6small.mdl",
	sound = "acf_base/engines/b6_petrolsmall.wav",
	category = "B6",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 100,
	torque = 170,
	flywheelmass = 0.08,
	idlerpm = 750,
	peakminrpm = 4300,
	peakmaxrpm = 6950,
	limitrpm = 7250
} )

ACF_DefineEngine( "5.0-B6", {
	name = "5.0L Flat 6 Petrol",
	desc = "Sports car grade flat six, renown for their smooth operation and light weight",
	model = "models/engines/b6med.mdl",
	sound = "acf_base/engines/b6_petrolmedium.wav",
	category = "B6",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 240,
	torque = 412,
	flywheelmass = 0.11,
	idlerpm = 900,
	peakminrpm = 3500,
	peakmaxrpm = 6000,
	limitrpm = 6800
} )

ACF_DefineEngine( "8.3-B6", {
	name = "8.3L Flat 6 Multifuel",
	desc = "Military-grade multifuel boxer engine.  Although heavy, it is compact, durable, and has excellent performance under adverse conditions.",
	model = "models/engines/b6med.mdl",
	sound = "acf_base/engines/v8_diesel.wav",
	category = "B6",
	fuel = "Multifuel",
	enginetype = "GenericDiesel",
	weight = 480,
	torque = 706,
	flywheelmass = 0.65,
	idlerpm = 500,
	peakminrpm = 1900,
	peakmaxrpm = 3600,
	limitrpm = 4200
} )


ACF_DefineEngine( "15.8-B6", {
	name = "15.8L Flat 6 Petrol",
	desc = "Monstrous aircraft-grade boxer with a high rev range biased powerband",
	model = "models/engines/b6large.mdl",
	sound = "acf_base/engines/b6_petrollarge.wav",
	category = "B6",
	fuel = "Petrol",
	enginetype = "GenericPetrol",
	weight = 725,
	torque = 1375,
	flywheelmass = 1,
	idlerpm = 620,
	peakminrpm = 2500,
	peakmaxrpm = 4275,
	limitrpm = 4900
} )
