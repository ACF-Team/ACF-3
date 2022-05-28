
-- V6 engines

ACF.RegisterEngineClass("V6", {
	Name		= "V6 Engine",
	Description	= "V6s are more torquey than the Boxer and Inline 6s but suffer in power."
})

do -- Petrol Engines
	ACF.RegisterEngine("3.6-V6", "V6", {
		Name		 = "3.6L V6 Petrol",
		Description	 = "Meaty Car sized V6, lots of torque.",
		Model		 = "models/engines/v6small.mdl",
		Sound		 = "acf_base/engines/v6_petrolsmall.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 190,
		Torque		 = 277,
		FlywheelMass = 0.25,
		RPM = {
			Idle	= 700,
			Limit	= 5000,
		},
		Preview = {
			FOV = 105,
		},
	})

	ACF.RegisterEngine("6.2-V6", "V6", {
		Name		 = "6.2L V6 Petrol",
		Description	 = "Heavy duty 6V71 v6, throatier than an LA whore, but loaded with torque.",
		Model		 = "models/engines/v6med.mdl",
		Sound		 = "acf_base/engines/v6_petrolmedium.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 360,
		Torque		 = 495,
		FlywheelMass = 0.45,
		RPM = {
			Idle	= 800,
			Limit	= 4800,
		},
		Preview = {
			FOV = 105,
		},
	})

	ACF.RegisterEngine("12.0-V6", "V6", {
		Name		 = "12.0L V6 Petrol",
		Description	 = "Fuck duty V6, guts ripped from god himself diluted in salt and shaped into an engine.",
		Model		 = "models/engines/v6large.mdl",
		Sound		 = "acf_base/engines/v6_petrollarge.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 675,
		Torque		 = 1650,
		FlywheelMass = 4,
		RPM = {
			Idle	= 600,
			Limit	= 3000,
		},
		Preview = {
			FOV = 105,
		},
	})
end

do -- Diesel Engines

	ACF.RegisterEngine("3.3-V6", "V6", {
		Name		 = "3.3L V6 Diesel",
		Description	 = "Some two stroke diesel let loose from a scrapyard.",
		Model		 = "models/engines/v6small.mdl",
		Sound		 = "acf_base/engines/v6_petrolsmall.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 220,
		Torque		 = 303,
		FlywheelMass = 0.8,
		RPM = {
			Idle	= 450,
			Limit	= 3700,
		},
		Preview = {
			FOV = 105,
		},
	})
	
	ACF.RegisterEngine("5.2-V6", "V6", {
		Name		 = "5.2L V6 Diesel",
		Description	 = "Light AFV-grade two-stroke diesel, high output but heavy.",
		Model		 = "models/engines/v6med.mdl",
		Sound		 = "acf_base/engines/i5_dieselmedium.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 520,
		Torque		 = 657,
		FlywheelMass = 0.8,
		RPM = {
			Idle	= 650,
			Limit	= 4000,
		},
		Preview = {
			FOV = 105,
		},
	})

	ACF.RegisterEngine("15.0-V6", "V6", {
		Name		 = "15.0L V6 Diesel",
		Description	 = "Powerful military-grade large V6, with impressive output. Well suited to medium-sized AFVs.",
		Model		 = "models/engines/v6large.mdl",
		Sound		 = "acf_base/engines/v6_diesellarge.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 1400,
		Torque		 = 2003,
		FlywheelMass = 6.4,
		RPM = {
			Idle	= 400,
			Limit	= 3050,
		},
		Preview = {
			FOV = 105,
		},
	})
end

ACF.SetCustomAttachment("models/engines/v6large.mdl", "driveshaft", Vector(2), Angle(0, 90, 90))
ACF.SetCustomAttachment("models/engines/v6med.mdl", "driveshaft", Vector(1.33), Angle(0, 90, 90))
ACF.SetCustomAttachment("models/engines/v6small.mdl", "driveshaft", Vector(1.06), Angle(0, 90, 90))

local Models = {
	{ Model = "models/engines/v6large.mdl", Scale = 1.85 },
	{ Model = "models/engines/v6med.mdl", Scale = 1.25 },
	{ Model = "models/engines/v6small.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Main = {
			Pos       = Vector(10.5, 0, 3.75) * Scale,
			Scale     = Vector(22, 11.5, 16.25) * Scale,
			Sensitive = true
		},
		LeftBank = {
			Pos   = Vector(11.5, -6.5, 7) * Scale,
			Scale = Vector(20, 8, 11) * Scale,
			Angle = Angle(0, 0, 45)
		},
		RightBank = {
			Pos   = Vector(11.5, 6.5, 7) * Scale,
			Scale = Vector(20, 8, 11) * Scale,
			Angle = Angle(0, 0, -45)
		}
	})
end
