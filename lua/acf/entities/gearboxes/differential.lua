local ACF       = ACF
local Gearboxes = ACF.Classes.Gearboxes

local Gear1SW = 10

Gearboxes.Register("Differential", {
	Name		= "Differential",
	CreateMenu	= ACF.ManualGearboxMenu,
	Gears = {
		Min	= 0,
		Max	= 1,
	}
})

do -- Scalable Gearboxes
	Gearboxes.RegisterItem("1Gear-L", "Differential", {
		Name			= "Differential, Inline",
		Description		= "An inline gearbox used to connect power from another gearbox to the wheels.",
		Model			= "models/engines/linear_s.mdl",
		Mass			= Gear1SW,
		Switch			= 0.3,
		MaxTorque		= 6000,
		CanDualClutch	= true,
		Preview = {
			FOV = 125,
		},
	})

	Gearboxes.RegisterItem("1Gear-T", "Differential", {
		Name			= "Differential, Transaxial",
		Description		= "A transaxial gearbox used to connect power from another gearbox to the wheels.",
		Model			= "models/engines/transaxial_s.mdl",
		Mass			= Gear1SW,
		Switch			= 0.3,
		MaxTorque		= 6000,
		CanDualClutch	= true,
		Preview = {
			FOV = 85,
		},
	})
end

ACF.SetCustomAttachments("models/engines/transaxial_s.mdl", {
	{ Name = "driveshaftR", Pos = Vector(0, 8, 3.2), Ang = Angle(0, 90, 90) },
	{ Name = "driveshaftL", Pos = Vector(0, -8, 3.2), Ang = Angle(0, -90, 90) },
	{ Name = "input", Pos = Vector(8, 0, 3.2), Ang = Angle(0, 0, 90) },
})
ACF.SetCustomAttachments("models/engines/linear_s.mdl", {
	{ Name = "driveshaftR", Pos = Vector(0, 8, 3.2), Ang = Angle(0, 90, 90) },
	{ Name = "driveshaftL", Pos = Vector(0, -9.6, 3.2), Ang = Angle(0, -90, 90) },
	{ Name = "input", Pos = Vector(0, 1.6, 11.6), Ang = Angle(0, -90, 90) },
})

local Transaxial = {
	{ Model = "models/engines/transaxial_s.mdl", Scale = 1 },
}

local Linears = {
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