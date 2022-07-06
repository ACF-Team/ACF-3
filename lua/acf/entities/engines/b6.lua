local ACF     = ACF
local Engines = ACF.Classes.Engines


Engines.Register("B6", {
	Name = "Flat 6 Engine",
})

do
	Engines.RegisterItem("2.8-B6", "B6", {
		Name		 = "2.8L Flat 6 Petrol",
		Description	 = "Car sized flat six engine, sporty and light",
		Model		 = "models/engines/b6small.mdl",
		Sound		 = "acf_base/engines/b6_petrolsmall.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 100,
		Torque		 = 170,
		FlywheelMass = 0.08,
		RPM = {
			Idle	= 750,
			Limit	= 7250,
		},
		Preview = {
			FOV = 85,
		},
	})

	Engines.RegisterItem("5.0-B6", "B6", {
		Name		 = "5.0L Flat 6 Petrol",
		Description	 = "Sports car grade flat six, renown for their smooth operation and light weight",
		Model		 = "models/engines/b6med.mdl",
		Sound		 = "acf_base/engines/b6_petrolmedium.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 240,
		Torque		 = 412,
		FlywheelMass = 0.11,
		RPM = {
			Idle	= 900,
			Limit	= 6800,
		},
		Preview = {
			FOV = 83,
		},
	})

	Engines.RegisterItem("8.3-B6", "B6", {
		Name		 = "8.3L Flat 6 Multifuel",
		Description	 = "Military-grade multifuel boxer engine. Although heavy, it is compact, durable, and has excellent performance under adverse conditions.",
		Model		 = "models/engines/b6med.mdl",
		Sound		 = "acf_base/engines/v8_diesel.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 480,
		Torque		 = 606,
		FlywheelMass = 0.65,
		RPM = {
			Idle	= 500,
			Limit	= 4200,
		},
		Preview = {
			FOV = 83,
		},
	})

	Engines.RegisterItem("15.8-B6", "B6", {
		Name		 = "15.8L Flat 6 Petrol",
		Description	 = "Monstrous aircraft-grade boxer with a high rev range biased powerband",
		Model		 = "models/engines/b6large.mdl",
		Sound		 = "acf_base/engines/b6_petrollarge.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 725,
		Torque		 = 1375,
		FlywheelMass = 1,
		RPM = {
			Idle	= 620,
			Limit	= 4900,
		},
		Preview = {
			FOV = 83,
		},
	})

	Engines.RegisterItem("14.5-B6", "B6", {
		Name		 = "14.5L Flat 6 Diesel",
		Description	 = "Very large diesel boxer, compact, but lacking in torque compared to others",
		Model		 = "models/engines/b6large.mdl",
		Sound		 = "acf_base/engines/i6_diesellarge2.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 1600,
		Torque		 = 1995,
		FlywheelMass = 3,
		RPM = {
			Idle	= 620,
			Limit	= 2550,
		},
		Preview = {
			FOV = 83,
		},
	})
end

ACF.SetCustomAttachment("models/engines/b6large.mdl", "driveshaft", Vector(), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/engines/b6med.mdl", "driveshaft", Vector(), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/engines/b6small.mdl", "driveshaft", Vector(), Angle(0, 0, 90))

local Models = {
	{ Model = "models/engines/b6large.mdl", Scale = 2.25 },
	{ Model = "models/engines/b6med.mdl", Scale = 1.5 }, -- yes a medium B6 is overall larger than a medium B4 in more than length because ??????
	{ Model = "models/engines/b6small.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Main = {
			Pos       = Vector(11, 0, 0.5) * Scale,
			Scale     = Vector(22, 16, 9) * Scale,
			Sensitive = true
		},
		UpperSection = {
			Pos   = Vector(9, 0, 7) * Scale,
			Scale = Vector(15, 23, 4) * Scale
		},
		LeftBank = {
			Pos   = Vector(12, -10, 2) * Scale,
			Scale = Vector(20, 4, 6) * Scale
		},
		RightBank = {
			Pos   = Vector(12, 10, 2) * Scale,
			Scale = Vector(20, 4, 6) * Scale
		}
	})
end
