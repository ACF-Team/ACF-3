local ACF     = ACF
local Engines = ACF.Classes.Engines


Engines.Register("V4", {
	Name = "V4 Engine",
})

do -- Diesel Engines
	Engines.RegisterItem("1.9L-V4", "V4", {
		Name		 = "1.9L V4 Diesel",
		Description	 = "Torquey little lunchbox; for those smaller vehicles that don't agree with petrol powerbands",
		Model		 = "models/engines/v4s.mdl",
		Sound		 = "acf_base/engines/i4_diesel2.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 110,
		Torque		 = 206,
		FlywheelMass = 0.3,
		RPM = {
			Idle	= 650,
			Limit	= 4000,
		},
		Preview = {
			FOV = 110,
		},
	})

	Engines.RegisterItem("3.3L-V4", "V4", {
		Name		 = "3.3L V4 Diesel",
		Description	 = "Compact cube of git; for moderate utility applications",
		Model		 = "models/engines/v4m.mdl",
		Sound		 = "acf_base/engines/i4_dieselmedium.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 275,
		Torque		 = 600,
		FlywheelMass = 1.05,
		RPM = {
			Idle	= 600,
			Limit	= 3900,
		},
		Preview = {
			FOV = 110,
		},
	})
end

ACF.SetCustomAttachment("models/engines/v4m.mdl", "driveshaft", Vector(-5.99, 0, 4.85), Angle(0, 90, 90))
ACF.SetCustomAttachment("models/engines/v4s.mdl", "driveshaft", Vector(-4.79, 0, 3.88), Angle(0, 90, 90))

local Models = {
	--{ Model = "models/engines/v4l.mdl", Scale = 1.5 }, -- Unused
	{ Model = "models/engines/v4m.mdl", Scale = 1.25 },
	{ Model = "models/engines/v4s.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Main = {
			Pos       = Vector(3.25, 0, 7.75) * Scale,
			Scale     = Vector(18, 11.5, 16) * Scale,
			Sensitive = true
		},
		LeftBank = {
			Pos   = Vector(4.25, -6.75, 11.25) * Scale,
			Scale = Vector(15.75, 6.5, 10) * Scale,
			Angle = Angle(0, 0, 45)
		},
		RightBank = {
			Pos   = Vector(4.25, 6.75, 11.25) * Scale,
			Scale = Vector(15.75, 6.5, 10) * Scale,
			Angle = Angle(0, 0, -45)
		}
	})
end
