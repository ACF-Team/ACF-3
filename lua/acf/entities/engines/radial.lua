local ACF     = ACF
local Engines = ACF.Classes.Engines


Engines.Register("R7", {
	Name = "Radial 7 Engine",
})

do
	Engines.RegisterItem("3.8-R7", "R7", {
		Name		 = "3.8L R7 Petrol",
		Description	 = "A tiny, old worn-out radial.",
		Model		 = "models/engines/radial7s.mdl",
		Sound		 = "acf_base/engines/r7_petrolsmall.wav",
		Fuel		 = { Petrol = true },
		Type		 = "Radial",
		Mass		 = 210,
		Torque		 = 387,
		FlywheelMass = 0.22,
		RPM = {
			Idle	= 700,
			Limit	= 4800,
		},
		Preview = {
			FOV = 105,
		},
	})

	Engines.RegisterItem("11.0-R7", "R7", {
		Name		 = "11.0L R7 Petrol",
		Description	 = "Mid range radial, thirsty and smooth.",
		Model		 = "models/engines/radial7m.mdl",
		Sound		 = "acf_base/engines/r7_petrolmedium.wav",
		Fuel		 = { Petrol = true },
		Type		 = "Radial",
		Mass		 = 385,
		Torque		 = 700,
		FlywheelMass = 0.45,
		RPM = {
			Idle	= 600,
			Limit	= 4000,
		},
		Preview = {
			FOV = 105,
		},
	})

	Engines.RegisterItem("8.0-R7", "R7", {
		Name		 = "8.0L R7 Diesel",
		Description	 = "Heavy and with a narrow powerband, but efficient, and well-optimized to cruising.",
		Model		 = "models/engines/radial7m.mdl",
		Sound		 = "acf_base/engines/r7_petrolmedium.wav",
		Fuel		 = { Petrol = true, Diesel = true },
		Type		 = "GenericDiesel",
		Mass		 = 450,
		Torque		 = 1000,
		FlywheelMass = 1,
		RPM = {
			Idle	= 400,
			Limit	= 2800,
		},
		Preview = {
			FOV = 105,
		},
	})

	Engines.RegisterItem("24.0-R7", "R7", {
		Name		 = "24.0L R7 Petrol",
		Description	 = "Massive American radial monster, destined for fighter aircraft and heavy tanks.",
		Model		 = "models/engines/radial7l.mdl",
		Sound		 = "acf_base/engines/r7_petrollarge.wav",
		Fuel		 = { Petrol = true },
		Type		 = "Radial",
		Mass		 = 952,
		Torque		 = 1990,
		FlywheelMass = 3.4,
		RPM = {
			Idle	= 750,
			Limit	= 2650,
		},
		Preview = {
			FOV = 105,
		},
	})
end

ACF.SetCustomAttachment("models/engines/radial7l.mdl", "driveshaft", Vector(-12), Angle(0, 180, 90))
ACF.SetCustomAttachment("models/engines/radial7m.mdl", "driveshaft", Vector(-8), Angle(0, 180, 90))
ACF.SetCustomAttachment("models/engines/radial7s.mdl", "driveshaft", Vector(-6), Angle(0, 180, 90))

-- Bunch of stuff to make it easier in the future to add radials
local Pistons    = 7
local PistonSize = Vector(6, 6, 10) -- Size of each piston
local PistonPos  = Vector(0, 0, -9) -- Position of the first piston
local AngleAxis  = Angle(0, 0, 1)
local Models = {
	{ Model = "models/engines/radial7l.mdl", Scale = 2 },
	{ Model = "models/engines/radial7m.mdl", Scale = 1.33 },
	{ Model = "models/engines/radial7s.mdl", Scale = 1 },
}

local function GeneratePistons(Hitboxes, Scale)
	local Rotation = 360 / Pistons
	local AddAngle = AngleAxis * Rotation

	for I = 1, Pistons do
		Hitboxes["Piston" .. I] = {
			Pos   = PistonPos * Scale,
			Scale = PistonSize * Scale,
			Angle = AddAngle * (I - 1),
		}

		PistonPos:Rotate(AddAngle)
	end
end

for _, Data in ipairs(Models) do
	local Scale = Data.Scale
	local Hitboxes = {
		Shaft = {
			Pos       = Vector(-0.5, 0, 0) * Scale,
			Scale     = Vector(10, 8.5, 8.5) * Scale,
			Sensitive = true
		}
	}

	GeneratePistons(Hitboxes, Scale)

	ACF.AddHitboxes(Data.Model, Hitboxes)
end
