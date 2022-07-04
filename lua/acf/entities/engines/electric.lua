local ACF     = ACF
local Engines = ACF.Classes.Engines


do -- Electric Motors
	Engines.Register("EL", {
		Name		= "Electric Motor",
		Description	= "Electric motors provide huge amounts of torque, but are very heavy.",
	})

	Engines.RegisterItem("Electric-Small", "EL", {
		Name		 = "Small Electric Motor",
		Description	 = "A small electric motor, loads of torque, but low power.",
		Model		 = "models/engines/emotorsmall.mdl",
		Sound		 = "acf_base/engines/electric_small.wav",
		Fuel		 = { Electric = true },
		Type		 = "Electric",
		Mass		 = 250,
		Torque		 = 480,
		FlywheelMass = 0.3,
		IsElectric	 = true,
		RPM = {
			Idle	 = 0,
			Limit	 = 10000,
			Override = 5000,
		},
		Preview = {
			FOV = 86,
		},
	})

	Engines.RegisterItem("Electric-Medium", "EL", {
		Name		 = "Medium Electric Motor",
		Description	 = "A medium electric motor, loads of torque, but low power.",
		Model		 = "models/engines/emotormed.mdl",
		Sound		 = "acf_base/engines/electric_medium.wav",
		Fuel		 = { Electric = true },
		Type		 = "Electric",
		Mass		 = 850,
		Torque		 = 1440,
		FlywheelMass = 1.5,
		IsElectric	 = true,
		RPM = {
			Idle	 = 0,
			Limit	 = 7000,
			Override = 8000,
		},
		Preview = {
			FOV = 88,
		},
	})

	Engines.RegisterItem("Electric-Large", "EL", {
		Name		 = "Large Electric Motor",
		Description	 = "A huge electric motor, loads of torque, but low power.",
		Model		 = "models/engines/emotorlarge.mdl",
		Sound		 = "acf_base/engines/electric_large.wav",
		Fuel		 = { Electric = true },
		Type		 = "Electric",
		Mass		 = 1900,
		Torque		 = 4200,
		FlywheelMass = 11.2,
		IsElectric	 = true,
		RPM = {
			Idle	 = 0,
			Limit	 = 4500,
			Override = 6000,
		},
	})
end

do -- Electric Standalone Motors
	Engines.Register("EL-S", {
		Name		= "Electric Standalone Motor",
		Description	= "Electric motors provide huge amounts of torque, but are very heavy. Standalones also require external batteries.",
	})

	Engines.RegisterItem("Electric-Tiny-NoBatt", "EL-S", {
		Name		 = "Tiny Electric Standalone Motor",
		Description	 = "A pint-size electric motor, for the lightest of light utility work. Can power electric razors, desk fans, or your hopes and dreams.",
		Model		 = "models/engines/emotor-standalone-tiny.mdl",
		Sound		 = "acf_base/engines/electric_small.wav",
		Fuel		 = { Electric = true },
		Type		 = "Electric",
		Mass		 = 50,
		Torque		 = 40,
		FlywheelMass = 0.025,
		IsElectric	 = true,
		RPM = {
			Idle	 = 0,
			Limit	 = 10000,
			Override = 500,
		},
		Preview = {
			FOV = 120,
		},
	})

	Engines.RegisterItem("Electric-Small-NoBatt", "EL-S", {
		Name		 = "Small Electric Standalone Motor",
		Description	 = "A small standalone electric motor, loads of torque, but low power.",
		Model		 = "models/engines/emotor-standalone-sml.mdl",
		Sound		 = "acf_base/engines/electric_small.wav",
		Fuel		 = { Electric = true },
		Type		 = "Electric",
		Mass		 = 125,
		Torque		 = 384,
		FlywheelMass = 0.3,
		IsElectric	 = true,
		RPM = {
			Idle	 = 0,
			Limit	 = 10000,
			Override = 5000,
		},
		Preview = {
			FOV = 114,
		},
	})

	Engines.RegisterItem("Electric-Medium-NoBatt", "EL-S", {
		Name		 = "Medium Electric Standalone Motor",
		Description	 = "A medium standalone electric motor, loads of torque, but low power.",
		Model		 = "models/engines/emotor-standalone-mid.mdl",
		Sound		 = "acf_base/engines/electric_medium.wav",
		Fuel		 = { Electric = true },
		Type		 = "Electric",
		Mass		 = 575,
		Torque		 = 1152,
		FlywheelMass = 1.5,
		IsElectric	 = true,
		RPM = {
			Idle	 = 0,
			Limit	 = 7000,
			Override = 8000,
		},
		Preview = {
			FOV = 112,
		},
	})

	Engines.RegisterItem("Electric-Large-NoBatt", "EL-S", {
		Name		 = "Large Electric Standalone Motor",
		Description	 = "A huge standalone electric motor, loads of torque, but low power.",
		Model		 = "models/engines/emotor-standalone-big.mdl",
		Sound		 = "acf_base/engines/electric_large.wav",
		Fuel		 = { Electric = true },
		Type		 = "Electric",
		Mass		 = 1500,
		Torque		 = 3360,
		FlywheelMass = 11.2,
		IsElectric	 = true,
		RPM = {
			Idle	 = 0,
			Limit	 = 4500,
			Override = 6000,
		},
		Preview = {
			FOV = 110,
		},
	})
end

ACF.SetCustomAttachment("models/engines/emotorlarge.mdl", "driveshaft", Vector(), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/engines/emotormed.mdl", "driveshaft", Vector(), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/engines/emotorsmall.mdl", "driveshaft", Vector(), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/engines/emotor-standalone-big.mdl", "driveshaft", Vector(), Angle(0, -90, 90))
ACF.SetCustomAttachment("models/engines/emotor-standalone-mid.mdl", "driveshaft", Vector(), Angle(0, -90, 90))
ACF.SetCustomAttachment("models/engines/emotor-standalone-sml.mdl", "driveshaft", Vector(), Angle(0, -90, 90))
ACF.SetCustomAttachment("models/engines/emotor-standalone-tiny.mdl", "driveshaft", Vector(), Angle(0, -90, 90))

local Fullsizes = {
	{ Model = "models/engines/emotorlarge.mdl", Scale = 1.92 },
	{ Model = "models/engines/emotormed.mdl", Scale = 1.37 },
	{ Model = "models/engines/emotorsmall.mdl", Scale = 1 },
}

local Standalones = {
	{ Model = "models/engines/emotor-standalone-big.mdl", Scale = 1.67 },
	{ Model = "models/engines/emotor-standalone-mid.mdl", Scale = 1.33 },
	{ Model = "models/engines/emotor-standalone-sml.mdl", Scale = 1 },

}

for _, Data in ipairs(Fullsizes) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Main = {
			Pos       = Vector(13, 0, 0.5) * Scale,
			Scale     = Vector(26, 14, 14) * Scale,
			Sensitive = true
		},
		CableBullshit = {
			Pos   = Vector(31, 0, 0.5) * Scale,
			Scale = Vector(10, 14, 14) * Scale
		},
		LeftPack = {
			Pos   = Vector(18.75, -13.5, 0.5) * Scale,
			Scale = Vector(37, 10, 14.5) * Scale
		},
		RightPack = {
			Pos   = Vector(18.75, 13.5, 0.5) * Scale,
			Scale = Vector(37, 10, 14.5) * Scale
		}
	})
end

for _, Data in ipairs(Standalones) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Main = {
			Pos       = Vector(9) * Scale,
			Scale     = Vector(20, 16, 16) * Scale,
			Sensitive = true
		}
	})
end

-- Special snowflake
ACF.AddHitboxes("models/engines/emotor-standalone-tiny.mdl", {
	Main = {
		Pos       = Vector(-0.5),
		Scale     = Vector(14, 10, 10),
		Sensitive = true
	}
})
