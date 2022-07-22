local ACF     = ACF
local Engines = ACF.Classes.Engines


Engines.Register("V8", {
	Name = "V8 Engine",
})

do -- Petrol Engines
	Engines.RegisterItem("5.7-V8", "V8", {
		Name		 = "5.7L V8 Petrol",
		Description	 = "Car sized petrol engine, good power and mid range torque",
		Model		 = "models/engines/v8s.mdl",
		Sound		 = "acf_base/engines/v8_petrolsmall.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 260,
		Torque		 = 389,
		FlywheelMass = 0.15,
		RPM = {
			Idle	= 800,
			Limit	= 5700,
		},
		Preview = {
			FOV = 100,
		},
	})

	Engines.RegisterItem("9.0-V8", "V8", {
		Name		 = "9.0L V8 Petrol",
		Description	 = "Thirsty, giant V8, for medium applications",
		Model		 = "models/engines/v8m.mdl",
		Sound		 = "acf_base/engines/v8_petrolmedium.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 400,
		Torque		 = 576,
		FlywheelMass = 0.25,
		RPM = {
			Idle	= 700,
			Limit	= 5500,
		},
		Preview = {
			FOV = 100,
		},
	})

	Engines.RegisterItem("18.0-V8", "V8", {
		Name		 = "18.0L V8 Petrol",
		Description	 = "American gasoline tank V8, good overall power and torque and fairly lightweight",
		Model		 = "models/engines/v8l.mdl",
		Sound		 = "acf_base/engines/v8_petrollarge.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 850,
		Torque		 = 1848,
		FlywheelMass = 2.8,
		RPM = {
			Idle	= 600,
			Limit	= 3000,
		},
		Preview = {
			FOV = 100,
		},
	})
end

do -- Diesel Engines
	Engines.RegisterItem("4.5-V8", "V8", {
		Name		 = "4.5L V8 Diesel",
		Description	 = "Light duty diesel v8, good for light vehicles that require a lot of torque",
		Model		 = "models/engines/v8s.mdl",
		Sound		 = "acf_base/engines/v8_dieselsmall.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 320,
		Torque		 = 446,
		FlywheelMass = 0.75,
		RPM = {
			Idle	= 800,
			Limit	= 4000,
		},
		Preview = {
			FOV = 100,
		},
	})

	Engines.RegisterItem("7.8-V8", "V8", {
		Name		 = "7.8L V8 Diesel",
		Description	 = "Redneck chariot material. Truck duty V8 diesel, has a good, wide powerband",
		Model		 = "models/engines/v8m.mdl",
		Sound		 = "acf_base/engines/v8_dieselmedium2.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 520,
		Torque		 = 870,
		FlywheelMass = 1.6,
		RPM = {
			Idle	= 650,
			Limit	= 3800,
		},
		Preview = {
			FOV = 100,
		},
	})

	Engines.RegisterItem("19.0-V8", "V8", {
		Name		 = "19.0L V8 Diesel",
		Description	 = "Heavy duty diesel V8, used in heavy construction equipment and tanks",
		Model		 = "models/engines/v8l.mdl",
		Sound		 = "acf_base/engines/v8_diesellarge.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 1200,
		Torque		 = 3308,
		FlywheelMass = 4.5,
		RPM = {
			Idle	= 500,
			Limit	= 2000,
		},
		Preview = {
			FOV = 100,
		},
	})
end

ACF.SetCustomAttachment("models/engines/v8l.mdl", "driveshaft", Vector(-25.6, 0, 7.4), Angle(0, 90, 90))
ACF.SetCustomAttachment("models/engines/v8m.mdl", "driveshaft", Vector(-17.02, 0, 4.92), Angle(0, 90, 90))
ACF.SetCustomAttachment("models/engines/v8s.mdl", "driveshaft", Vector(-13.62, 0, 3.94), Angle(0, 90, 90))

local Models = {
	{ Model = "models/engines/v8l.mdl", Scale = 1.85 },
	{ Model = "models/engines/v8m.mdl", Scale = 1.25 },
	{ Model = "models/engines/v8s.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Main = {
			Pos       = Vector(-1.25, 0, 7.5) * Scale,
			Scale     = Vector(27.5, 11.5, 16.5) * Scale,
			Sensitive = true
		},
		LeftBank = {
			Pos   = Vector(0, -6.5, 11) * Scale,
			Scale = Vector(25, 8, 11.25) * Scale,
			Angle = Angle(0, 0, 45)
		},
		RightBank = {
			Pos   = Vector(0, 6.5, 11) * Scale,
			Scale = Vector(25, 8, 11.25) * Scale,
			Angle = Angle(0, 0, -45)
		}
	})
end
