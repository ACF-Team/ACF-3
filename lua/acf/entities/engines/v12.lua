local ACF     = ACF
local Engines = ACF.Classes.Engines


Engines.Register("V12", {
	Name = "V12 Engine",
})

do -- Petrol Engines
	Engines.RegisterItem("4.6-V12", "V12", {
		Name		 = "4.6L V12 Petrol",
		Description	 = "An elderly racecar engine; low on torque, but plenty of power",
		Model		 = "models/engines/v12s.mdl",
		Sound		 = "acf_base/engines/v12_petrolsmall.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 188,
		Torque		 = 317,
		FlywheelMass = 0.2,
		RPM = {
			Idle	= 1000,
			Limit	= 8000,
		},
		Preview = {
			FOV = 95,
		},
	})

	Engines.RegisterItem("7.0-V12", "V12", {
		Name		 = "7.0L V12 Petrol",
		Description	 = "A high end V12; primarily found in very expensive cars",
		Model		 = "models/engines/v12m.mdl",
		Sound		 = "acf_base/engines/v12_petrolmedium.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 360,
		Torque		 = 726,
		FlywheelMass = 0.45,
		RPM = {
			Idle	= 800,
			Limit	= 6000,
		},
		Preview = {
			FOV = 95,
		},
	})

	Engines.RegisterItem("13.0-V12", "V12", {
		Name		 = "13.0L V12 Petrol",
		Description	 = "Thirsty gasoline v12, good torque and power for medium applications.",
		Model		 = "models/engines/v12m.mdl",
		Sound		 = "acf_base/engines/v12_special.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 520,
		Torque		 = 932,
		FlywheelMass = 2,
		RPM = {
			Idle	= 700,
			Limit	= 4250,
		},
		Preview = {
			FOV = 95,
		},
	})

	Engines.RegisterItem("23.0-V12", "V12", {
		Name		 = "23.0L V12 Petrol",
		Description	 = "A large, thirsty gasoline V12, found in early cold war tanks",
		Model		 = "models/engines/v12l.mdl",
		Sound		 = "acf_base/engines/v12_petrollarge.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 1350,
		Torque		 = 2436,
		FlywheelMass = 5,
		RPM = {
			Idle	= 600,
			Limit	= 3250,
		},
		Preview = {
			FOV = 95,
		},
	})
end

do -- Diesel Engines
	Engines.RegisterItem("4.0-V12", "V12", {
		Name		 = "4.0L V12 Diesel",
		Description	 = "Reliable truck-duty diesel; a lot of smooth torque",
		Model		 = "models/engines/v12s.mdl",
		Sound		 = "acf_base/engines/v12_dieselsmall.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 305,
		Torque		 = 510,
		FlywheelMass = 0.475,
		RPM = {
			Idle	= 650,
			Limit	= 4000,
		},
		Preview = {
			FOV = 95,
		},
	})

	Engines.RegisterItem("9.2-V12", "V12", {
		Name		 = "9.2L V12 Diesel",
		Description	 = "High torque light-tank V12, used mainly for vehicles that require balls",
		Model		 = "models/engines/v12m.mdl",
		Sound		 = "acf_base/engines/v12_dieselmedium.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 600,
		Torque		 = 1202,
		FlywheelMass = 2.5,
		RPM = {
			Idle	= 675,
			Limit	= 3600,
		},
		Preview = {
			FOV = 95,
		},
	})

	Engines.RegisterItem("21.0-V12", "V12", {
		Name		 = "21.0L V12 Diesel",
		Description	 = "AVDS-1790-2 tank engine; massively powerful, but enormous and heavy",
		Model		 = "models/engines/v12l.mdl",
		Sound		 = "acf_base/engines/v12_diesellarge.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 1800,
		Torque		 = 4325,
		FlywheelMass = 7,
		RPM = {
			Idle	= 400,
			Limit	= 2000,
		},
		Preview = {
			FOV = 95,
		},
	})
end

ACF.SetCustomAttachment("models/engines/v12l.mdl", "driveshaft", Vector(-34, 0, 7.3), Angle(0, 90, 90))
ACF.SetCustomAttachment("models/engines/v12m.mdl", "driveshaft", Vector(-22.61, 0, 4.85), Angle(0, 90, 90))
ACF.SetCustomAttachment("models/engines/v12s.mdl", "driveshaft", Vector(-18.09, 0, 3.88), Angle(0, 90, 90))

local Models = {
	{ Model = "models/engines/v12l.mdl", Scale = 1.85 },
	{ Model = "models/engines/v12m.mdl", Scale = 1.25 },
	{ Model = "models/engines/v12s.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Main = {
			Pos   = Vector(-1.25, 0, 7.5) * Scale,
			Scale = Vector(36, 11.5, 16.5) * Scale,
			Sensitive = true
		},
		LeftBank = {
			Pos   = Vector(-0.25, -6.5, 11) * Scale,
			Scale = Vector(34, 8, 11.25) * Scale,
			Angle = Angle(0, 0, 45)
		},
		RightBank = {
			Pos   = Vector(-0.25, 6.5, 11) * Scale,
			Scale = Vector(34, 8, 11.25) * Scale,
			Angle = Angle(0, 0, -45)
		}
	})
end
