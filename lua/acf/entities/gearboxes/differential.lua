local ACF       = ACF
local Gearboxes = ACF.Classes.Gearboxes

local Gear1SW = 10
local Gear1MW = 20
local Gear1LW = 40

Gearboxes.Register("Differential", {
	Name		= "Differential",
	CreateMenu	= ACF.ManualGearboxMenu,
	Gears = {
		Min	= 0,
		Max	= 1,
	}
})

do -- Inline Gearboxes
	Gearboxes.RegisterItem("1Gear-L-S", "Differential", {
		Name		= "Differential, Inline, Small",
		Description	= "Small differential, used to connect power from gearbox to wheels",
		Model		= "models/engines/linear_s.mdl",
		Mass		= Gear1SW,
		Switch		= 0.3,
		MaxTorque	= 25000,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("1Gear-L-M", "Differential", {
		Name		= "Differential, Inline, Medium",
		Description	= "Medium duty differential",
		Model		= "models/engines/linear_m.mdl",
		Mass		= Gear1MW,
		Switch		= 0.4,
		MaxTorque	= 50000,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("1Gear-L-L", "Differential", {
		Name		= "Differential, Inline, Large",
		Description	= "Heavy duty differential, for the heaviest of engines",
		Model		= "models/engines/linear_l.mdl",
		Mass		= Gear1LW,
		Switch		= 0.6,
		MaxTorque	= 100000,
		Preview = {
			FOV = 125,
		},
	})
end

do -- Inline Dual Clutch Gearboxes
	Gearboxes.RegisterItem("1Gear-LD-S", "Differential", {
		Name		= "Differential, Inline, Small, Dual Clutch",
		Description	= "Small differential, used to connect power from gearbox to wheels",
		Model		= "models/engines/linear_s.mdl",
		Mass		= Gear1SW,
		Switch		= 0.3,
		MaxTorque	= 25000,
		DualClutch	= true,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("1Gear-LD-M", "Differential", {
		Name		= "Differential, Inline, Medium, Dual Clutch",
		Description	= "Medium duty differential",
		Model		= "models/engines/linear_m.mdl",
		Mass		= Gear1MW,
		Switch		= 0.4,
		MaxTorque	= 50000,
		DualClutch	= true,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("1Gear-LD-L", "Differential", {
		Name		= "Differential, Inline, Large, Dual Clutch",
		Description	= "Heavy duty differential, for the heaviest of engines",
		Model		= "models/engines/linear_l.mdl",
		Mass		= Gear1LW,
		Switch		= 0.6,
		MaxTorque	= 100000,
		DualClutch	= true,
		Preview = {
			FOV = 125,
		},
	})
end

do -- Transaxial Gearboxes
	Gearboxes.RegisterItem("1Gear-T-S", "Differential", {
		Name		= "Differential, Small",
		Description	= "Small differential, used to connect power from gearbox to wheels",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= Gear1SW,
		Switch		= 0.3,
		MaxTorque	= 25000,
		Preview = {
			FOV = 85,
		},
	})

	Gearboxes.RegisterItem("1Gear-T-M", "Differential", {
		Name		= "Differential, Medium",
		Description	= "Medium duty differential",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= Gear1MW,
		Switch		= 0.4,
		MaxTorque	= 50000,
		Preview = {
			FOV = 85,
		},
	})

	Gearboxes.RegisterItem("1Gear-T-L", "Differential", {
		Name		= "Differential, Large",
		Description	= "Heavy duty differential, for the heaviest of engines",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= Gear1LW,
		Switch		= 0.6,
		MaxTorque	= 100000,
		Preview = {
			FOV = 85,
		},
	})
end

do -- Transaxial Dual Clutch Gearboxes
	Gearboxes.RegisterItem("1Gear-TD-S", "Differential", {
		Name		= "Differential, Small, Dual Clutch",
		Description	= "Small differential, used to connect power from gearbox to wheels",
		Model		= "models/engines/transaxial_s.mdl",
		Mass		= Gear1SW,
		Switch		= 0.3,
		MaxTorque	= 25000,
		DualClutch	= true,
		Preview = {
			FOV = 85,
		},
	})

	Gearboxes.RegisterItem("1Gear-TD-M", "Differential", {
		Name		= "Differential, Medium, Dual Clutch",
		Description	= "Medium duty differential",
		Model		= "models/engines/transaxial_m.mdl",
		Mass		= Gear1MW,
		Switch		= 0.4,
		MaxTorque	= 50000,
		DualClutch	= true,
		Preview = {
			FOV = 85,
		},
	})

	Gearboxes.RegisterItem("1Gear-TD-L", "Differential", {
		Name		= "Differential, Large, Dual Clutch",
		Description	= "Heavy duty differential, for the heaviest of engines",
		Model		= "models/engines/transaxial_l.mdl",
		Mass		= Gear1LW,
		Switch		= 0.6,
		MaxTorque	= 100000,
		DualClutch	= true,
		Preview = {
			FOV = 85,
		},
	})
end

ACF.SetCustomAttachments("models/engines/transaxial_l.mdl", {
	{ Name = "driveshaftR", Pos = Vector(0, 20, 8), Ang = Angle(0, 90, 90) },
	{ Name = "driveshaftL", Pos = Vector(0, -20, 8), Ang = Angle(0, -90, 90) },
	{ Name = "input", Pos = Vector(20, 0, 8), Ang = Angle(0, 0, 90) },
})
ACF.SetCustomAttachments("models/engines/transaxial_m.mdl", {
	{ Name = "driveshaftR", Pos = Vector(0, 12, 4.8), Ang = Angle(0, 90, 90) },
	{ Name = "driveshaftL", Pos = Vector(0, -12, 4.8), Ang = Angle(0, -90, 90) },
	{ Name = "input", Pos = Vector(12, 0, 4.8), Ang = Angle(0, 0, 90) },
})
ACF.SetCustomAttachments("models/engines/transaxial_s.mdl", {
	{ Name = "driveshaftR", Pos = Vector(0, 8, 3.2), Ang = Angle(0, 90, 90) },
	{ Name = "driveshaftL", Pos = Vector(0, -8, 3.2), Ang = Angle(0, -90, 90) },
	{ Name = "input", Pos = Vector(8, 0, 3.2), Ang = Angle(0, 0, 90) },
})
ACF.SetCustomAttachments("models/engines/linear_l.mdl", {
	{ Name = "driveshaftR", Pos = Vector(0, 20, 8), Ang = Angle(0, 90, 90) },
	{ Name = "driveshaftL", Pos = Vector(0, -24, 8), Ang = Angle(0, -90, 90) },
	{ Name = "input", Pos = Vector(0, 4, 29), Ang = Angle(0, -90, 90) },
})
ACF.SetCustomAttachments("models/engines/linear_m.mdl", {
	{ Name = "driveshaftR", Pos = Vector(0, 12, 4.8), Ang = Angle(0, 90, 90) },
	{ Name = "driveshaftL", Pos = Vector(0, -14.4, 4.8), Ang = Angle(0, -90, 90) },
	{ Name = "input", Pos = Vector(0, 2.4, 17.4), Ang = Angle(0, -90, 90) },
})
ACF.SetCustomAttachments("models/engines/linear_s.mdl", {
	{ Name = "driveshaftR", Pos = Vector(0, 8, 3.2), Ang = Angle(0, 90, 90) },
	{ Name = "driveshaftL", Pos = Vector(0, -9.6, 3.2), Ang = Angle(0, -90, 90) },
	{ Name = "input", Pos = Vector(0, 1.6, 11.6), Ang = Angle(0, -90, 90) },
})

local Transaxial = {
	{ Model = "models/engines/transaxial_l.mdl", Scale = 2.5 },
	{ Model = "models/engines/transaxial_m.mdl", Scale = 1.5 },
	{ Model = "models/engines/transaxial_s.mdl", Scale = 1 },
}

local Linears = {
	{ Model = "models/engines/linear_l.mdl", Scale = 2.5 },
	{ Model = "models/engines/linear_m.mdl", Scale = 1.5 },
	{ Model = "models/engines/linear_s.mdl", Scale = 1 },
}

for _, Data in ipairs(Transaxial) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Axle = {
			Pos       = Vector(0, 0, 3.25) * Scale,
			Scale     = Vector(6.5, 16, 6.5) * Scale,
			Sensitive = true
		},
		In = {
			Pos   = Vector(5.5, 0, 3.25) * Scale,
			Scale = Vector(4.5, 6.5, 6.5) * Scale
		}
	})
end

for _, Data in ipairs(Linears) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Straight = {
			Pos       = Vector(0, -0.5, 3.25) * Scale,
			Scale     = Vector(6.5, 18, 6.5) * Scale,
			Sensitive = true
		},
		In = {
			Pos   = Vector(0, 4.75, 11) * Scale,
			Scale = Vector(6.5, 7.5, 9) * Scale
		}
	})
end
