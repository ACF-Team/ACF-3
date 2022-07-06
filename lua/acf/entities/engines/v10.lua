local ACF     = ACF
local Engines = ACF.Classes.Engines


Engines.Register("V10", {
	Name = "V10 Engine",
})

do
	Engines.RegisterItem("4.3-V10", "V10", {
		Name		 = "4.3L V10 Petrol",
		Description	 = "Small-block V-10 gasoline engine, great for powering a hot rod lincoln",
		Model		 = "models/engines/v10sml.mdl",
		Sound		 = "acf_base/engines/v10_petrolsmall.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 160,
		Torque		 = 360,
		FlywheelMass = 0.2,
		RPM = {
			Idle	= 900,
			Limit	= 6250,
		},
		Preview = {
			FOV = 100,
		},
	})

	Engines.RegisterItem("8.0-V10", "V10", {
		Name		 = "8.0L V10 Petrol",
		Description	 = "Beefy 10-cylinder gas engine, gets 9 kids to soccer practice",
		Model		 = "models/engines/v10med.mdl",
		Sound		 = "acf_base/engines/v10_petrolmedium.wav",
		Fuel		 = { Petrol = true },
		Type		 = "GenericPetrol",
		Mass		 = 300,
		Torque		 = 612,
		FlywheelMass = 0.5,
		RPM = {
			Idle	= 750,
			Limit	= 6500,
		},
		Preview = {
			FOV = 100,
		},
	})

	Engines.RegisterItem("22.0-V10", "V10", {
		Name		 = "22.0L V10 Multifuel",
		Description	 = "Heavy multifuel V-10, gearbox-shredding torque but very heavy.",
		Model		 = "models/engines/v10big.mdl",
		Sound		 = "acf_base/engines/v10_diesellarge.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 1600,
		Torque		 = 3240,
		FlywheelMass = 5,
		RPM = {
			Idle	= 525,
			Limit	= 2200,
		},
		Preview = {
			FOV = 100,
		},
	})
end

ACF.SetCustomAttachment("models/engines/v10big.mdl", "driveshaft", Vector(-33, 0, 7.2), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/engines/v10med.mdl", "driveshaft", Vector(-21.95, 0, 4.79), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/engines/v10sml.mdl", "driveshaft", Vector(-17.56, 0, 3.83), Angle(0, 0, 90))

local Models = {
	{ Model = "models/engines/v10big.mdl", Scale = 1.85 },
	{ Model = "models/engines/v10med.mdl", Scale = 1.25 },
	{ Model = "models/engines/v10sml.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Main = {
			Pos       = Vector(-3.5, 0, 7.5) * Scale,
			Scale     = Vector(31, 11.5, 16.5) * Scale,
			Sensitive = true
		},
		LeftBank = {
			Pos   = Vector(-2.5, -6.5, 11) * Scale,
			Scale = Vector(28, 8, 11.25) * Scale,
			Angle = Angle(0, 0, 45)
		},
		RightBank = {
			Pos   = Vector(-2.5, 6.5, 11) * Scale,
			Scale = Vector(28, 8, 11.25) * Scale,
			Angle = Angle(0, 0, -45)
		}
	})
end
