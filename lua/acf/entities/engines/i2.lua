local ACF     = ACF
local Engines = ACF.Classes.Engines


Engines.Register("I2", {
	Name = "Inline 2 Engine",
})

do
	Engines.RegisterItem("0.8L-I2", "I2", {
		Name		 = "0.8L I2 Diesel",
		Description	 = "For when a 3 banger is still too bulky for your micro-needs.",
		Model		 = "models/engines/inline2s.mdl",
		Sound		 = "acf_base/engines/i4_diesel2.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 45,
		Torque		 = 131,
		FlywheelMass = 0.12,
		RPM = {
			Idle	= 500,
			Limit	= 2950,
		},
		Preview = {
			FOV = 125,
		},
	})

	Engines.RegisterItem("10.0-I2", "I2", {
		Name		 = "10.0L I2 Diesel",
		Description	 = "TORQUE.",
		Model		 = "models/engines/inline2b.mdl",
		Sound		 = "acf_base/engines/vtwin_large.wav",
		Fuel		 = { Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 800,
		Torque		 = 2500,
		FlywheelMass = 7,
		RPM = {
			Idle	= 350,
			Limit	= 1200,
		},
		Preview = {
			FOV = 125,
		},
	})
end

ACF.SetCustomAttachment("models/engines/inline2b.mdl", "driveshaft", Vector(), Angle(0, 180, 90))
ACF.SetCustomAttachment("models/engines/inline2s.mdl", "driveshaft", Vector(-6, 0, 4), Angle(0, 180, 90))

local Models = {
	{ Model = "models/engines/inline2b.mdl", Scale = 2.5 },
	{ Model = "models/engines/inline2s.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Shaft = {
			Pos       = Vector(-1.25, 0, 4.75) * Scale,
			Scale     = Vector(15.5, 8, 9) * Scale,
			Sensitive = true
		},
		Pistons = {
			Pos   = Vector(-0.5, 0, 13.25) * Scale,
			Scale = Vector(10, 5, 8) * Scale
		}
	})
end
