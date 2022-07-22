local ACF     = ACF
local Engines = ACF.Classes.Engines


Engines.Register("B4", {
	Name = "Flat 4 Engine",
})

do
	Engines.RegisterItem("1.4-B4", "B4", {
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
			Limit	= 4500,
		},
		Preview = {
			FOV = 80,
		},
	})

	Engines.RegisterItem("2.1-B4", "B4", {
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
			Limit	= 5000,
		},
		Preview = {
			FOV = 80,
		},
	})

	Engines.RegisterItem("2.4-B4", "B4", {
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
			Limit	= 2800,
		},
		Preview = {
			FOV = 80,
		},
	})

	Engines.RegisterItem("3.2-B4", "B4", {
		Name		 = "3.2L Flat 4 Petrol",
		Description	 = "Bored out fuckswindleton batshit flat four. Fuck yourself.", -- Ok
		Model		 = "models/engines/b4med.mdl",
		Sound		 = "acf_base/engines/b4_petrollarge.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 210,
		Torque		 = 315,
		FlywheelMass = 0.15,
		RPM = {
			Idle	= 900,
			Limit	= 6500
		},
		Preview = {
			FOV = 85,
		},
	})
end

ACF.SetCustomAttachment("models/engines/b4med.mdl", "driveshaft", Vector(), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/engines/b4small.mdl", "driveshaft", Vector(), Angle(0, 0, 90))

local Models = {
	{ Model = "models/engines/b4med.mdl", Scale = 1.25 },
	{ Model = "models/engines/b4small.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Main = {
			Pos       = Vector(8.5, 0, 0.5) * Scale,
			Scale     = Vector(18, 16, 9) * Scale,
			Sensitive = true
		},
		UpperSection = {
			Pos   = Vector(7, 0, 7) * Scale,
			Scale = Vector(11, 23, 4) * Scale
		},
		LeftBank = {
			Pos   = Vector(9, -10, 2) * Scale,
			Scale = Vector(16, 4, 6) * Scale
		},
		RightBank = {
			Pos   = Vector(9, 10, 2) * Scale,
			Scale = Vector(16, 4, 6) * Scale
		}
	})
end
