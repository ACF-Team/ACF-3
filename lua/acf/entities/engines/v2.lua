local ACF     = ACF
local Engines = ACF.Classes.Engines


Engines.Register("V2", {
	Name = "V-Twin Engine",
})

do -- Petrol Engines
	Engines.RegisterItem("0.6-V2", "V2", {
		Name		 = "600cc V-Twin",
		Description	 = "Twin cylinder bike engine, torquey for its size",
		Model		 = "models/engines/v-twins2.mdl",
		Sound		 = "acf_base/engines/vtwin_small.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 30,
		Torque		 = 62,
		FlywheelMass = 0.01,
		RPM = {
			Idle	= 900,
			Limit	= 7000,
		},
		Preview = {
			FOV = 115,
		},
	})

	Engines.RegisterItem("1.2-V2", "V2", {
		Name		 = "1200cc V-Twin",
		Description	 = "Large displacement vtwin engine",
		Model		 = "models/engines/v-twinm2.mdl",
		Sound		 = "acf_base/engines/vtwin_medium.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 50,
		Torque		 = 106,
		FlywheelMass = 0.02,
		RPM = {
			Idle	= 725,
			Limit	= 6250,
		},
		Preview = {
			FOV = 115,
		},
	})

	Engines.RegisterItem("2.4-V2", "V2", {
		Name		 = "2400cc V-Twin",
		Description	 = "Huge fucking Vtwin 'MURRICA FUCK YEAH",
		Model		 = "models/engines/v-twinl2.mdl",
		Sound		 = "acf_base/engines/vtwin_large.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 100,
		Torque		 = 200,
		FlywheelMass = 0.075,
		RPM = {
			Idle	= 900,
			Limit	= 6000,
		},
		Preview = {
			FOV = 115,
		},
	})
end

ACF.SetCustomAttachment("models/engines/v-twinl2.mdl", "driveshaft", Vector(), Angle(0, 90, 90))
ACF.SetCustomAttachment("models/engines/v-twinm2.mdl", "driveshaft", Vector(), Angle(0, 90, 90))
ACF.SetCustomAttachment("models/engines/v-twins2.mdl", "driveshaft", Vector(), Angle(0, 90, 90))

local Models = {
	{ Model = "models/engines/v-twinl2.mdl", Scale = 1.67 },
	{ Model = "models/engines/v-twinm2.mdl", Scale = 1.33 },
	{ Model = "models/engines/v-twins2.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Shaft = {
			Pos       = Vector(4.25) * Scale,
			Scale     = Vector(9, 8, 8) * Scale,
			Sensitive = true
		},
		Piston1 = {
			Pos   = Vector(5, -4, 8.5) * Scale,
			Scale = Vector(6, 6, 12) * Scale,
			Angle = Angle(0, 0, 25)
		},
		Piston2 = {
			Pos   = Vector(5, 4, 8.5) * Scale,
			Scale = Vector(6, 6, 12) * Scale,
			Angle = Angle(0, 0, -25)
		}
	})
end
