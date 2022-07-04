local ACF     = ACF
local Engines = ACF.Classes.Engines


Engines.Register("V6", {
	Name		= "V6 Engine",
	Description	= "V6s are more torquey than the Boxer and Inline 6s but suffer in power."
})

do -- Petrol Engines
	Engines.RegisterItem("3.6-V6", "V6", {
		Name		 = "3.6L V6 Petrol",
		Description	 = "Meaty Car sized V6, lots of torque.",
		Model		 = "models/engines/v6small.mdl",
		Sound		 = "acf_base/engines/v6_petrolsmall.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 190,
		Torque		 = 316,
		FlywheelMass = 0.25,
		RPM = {
			Idle	= 700,
			Limit	= 5000,
		},
		Preview = {
			FOV = 105,
		},
	})

	Engines.RegisterItem("6.2-V6", "V6", {
		Name		 = "6.2L V6 Petrol",
		Description	 = "Heavy duty 6V71 v6, throatier than an LA whore, but loaded with torque.",
		Model		 = "models/engines/v6med.mdl",
		Sound		 = "acf_base/engines/v6_petrolmedium.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 360,
		Torque		 = 590,
		FlywheelMass = 0.45,
		RPM = {
			Idle	= 800,
			Limit	= 5000,
		},
		Preview = {
			FOV = 105,
		},
	})

	Engines.RegisterItem("12.0-V6", "V6", {
		Name		 = "12.0L V6 Petrol",
		Description	 = "Fuck duty V6, guts ripped from god himself diluted in salt and shaped into an engine.",
		Model		 = "models/engines/v6large.mdl",
		Sound		 = "acf_base/engines/v6_petrollarge.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 675,
		Torque		 = 1806,
		FlywheelMass = 4,
		RPM = {
			Idle	= 600,
			Limit	= 3800,
		},
		Preview = {
			FOV = 105,
		},
	})
end

do -- Diesel Engines
	Engines.RegisterItem("5.2-V6", "V6", {
		Name		 = "5.2L V6 Diesel",
		Description	 = "Light AFV-grade two-stroke diesel, high output but heavy.",
		Model		 = "models/engines/v6med.mdl",
		Sound		 = "acf_base/engines/i5_dieselmedium.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 520,
		Torque		 = 606,
		FlywheelMass = 0.8,
		RPM = {
			Idle	= 650,
			Limit	= 4300,
		},
		Preview = {
			FOV = 105,
		},
	})

	Engines.RegisterItem("15.0-V6", "V6", {
		Name		 = "15.0L V6 Diesel",
		Description	 = "Powerful military-grade large V6, with impressive output. Well suited to medium-sized AFVs.",
		Model		 = "models/engines/v6large.mdl",
		Sound		 = "acf_base/engines/v6_diesellarge.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 900,
		Torque		 = 2208,
		FlywheelMass = 6.4,
		RPM = {
			Idle	= 400,
			Limit	= 3100,
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
