local ACF     = ACF
local Classes = ACF.Classes
Classes.DefineClass("ACF.Engines.R7", "ACF.Engines.BaseEngine", function()
	CLASS.Name = "Radial 7 Engine"
end)

do
	Classes.DefineClass("ACF.Engines.3.8-R7", "ACF.Engines.R7", function()
		CLASS.Name		 = "3.8L R7 Petrol"
		CLASS.Description	 = "#acf.descs.engines.r7.3_8"
		CLASS.Model		 = "models/engines/radial7s.mdl"
		CLASS.Sound		 = "acf_base/engines/r7_petrolsmall.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.Radial"
		CLASS.Mass		 = 210
		CLASS.Torque		 = 387
		CLASS.FlywheelMass = 0.22
		CLASS.RPM = {
			Idle	= 700,
			Limit	= 4800,
		}
		CLASS.Preview = {
			FOV = 105,
		}
	end)

	Classes.DefineClass("ACF.Engines.11.0-R7", "ACF.Engines.R7", function()
		CLASS.Name		 = "11.0L R7 Petrol"
		CLASS.Description	 = "#acf.descs.engines.r7.11_0"
		CLASS.Model		 = "models/engines/radial7m.mdl"
		CLASS.Sound		 = "acf_base/engines/r7_petrolmedium.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.Radial"
		CLASS.Mass		 = 385
		CLASS.Torque		 = 700
		CLASS.FlywheelMass = 0.45
		CLASS.RPM = {
			Idle	= 600,
			Limit	= 4000,
		}
		CLASS.Preview = {
			FOV = 105,
		}
	end)

	Classes.DefineClass("ACF.Engines.8.0-R7", "ACF.Engines.R7", function()
		CLASS.Name		 = "8.0L R7 Diesel"
		CLASS.Description	 = "#acf.descs.engines.r7.8_0"
		CLASS.Model		 = "models/engines/radial7m.mdl"
		CLASS.Sound		 = "acf_base/engines/r7_petrolmedium.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true, ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 450
		CLASS.Torque		 = 1000
		CLASS.FlywheelMass = 1
		CLASS.RPM = {
			Idle	= 400,
			Limit	= 2800,
		}
		CLASS.Preview = {
			FOV = 105,
		}
	end)

	Classes.DefineClass("ACF.Engines.24.0-R7", "ACF.Engines.R7", function()
		CLASS.Name		 = "24.0L R7 Petrol"
		CLASS.Description	 = "#acf.descs.engines.r7.24_0"
		CLASS.Model		 = "models/engines/radial7l.mdl"
		CLASS.Sound		 = "acf_base/engines/r7_petrollarge.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.Radial"
		CLASS.Mass		 = 952
		CLASS.Torque		 = 1990
		CLASS.FlywheelMass = 3.4
		CLASS.RPM = {
			Idle	= 750,
			Limit	= 2650,
		}
		CLASS.Preview = {
			FOV = 105,
		}
	end)
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
