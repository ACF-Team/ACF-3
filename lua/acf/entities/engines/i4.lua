local ACF     = ACF
local Classes = ACF.Classes

Classes.DefineClass("ACF.Engines.I4", "ACF.Engines.BaseEngine", function()
	CLASS.Name = "Inline 4 Engine"
end)

do -- Petrol Engines
	Classes.DefineClass("ACF.Engines.1.5-I4", "ACF.Engines.I4", function()
		CLASS.Name		 = "1.5L I4 Petrol"
		CLASS.Description	 = "#acf.descs.engines.i4.1_5"
		CLASS.Model		 = "models/engines/inline4s.mdl"
		CLASS.Sound		 = "acf_base/engines/i4_petrolsmall2.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 50
		CLASS.Torque		 = 119
		CLASS.FlywheelMass = 0.06
		CLASS.RPM = {
			Idle	= 900,
			Limit	= 8000,
		}
		CLASS.Preview = {
			FOV = 120,
		}
	end)

	Classes.DefineClass("ACF.Engines.3.7-I4", "ACF.Engines.I4", function()
		CLASS.Name		 = "3.7L I4 Petrol"
		CLASS.Description	 = "#acf.descs.engines.i4.3_7"
		CLASS.Model		 = "models/engines/inline4m.mdl"
		CLASS.Sound		 = "acf_base/engines/i4_petrolmedium2.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 200
		CLASS.Torque		 = 305
		CLASS.FlywheelMass = 0.2
		CLASS.RPM = {
			Idle	= 900,
			Limit	= 6500
		}
		CLASS.Preview = {
			FOV = 120,
		}
	end)

	Classes.DefineClass("ACF.Engines.16.0-I4", "ACF.Engines.I4", function()
		CLASS.Name		 = "16.0L I4 Petrol"
		CLASS.Description	 = "#acf.descs.engines.i4.16_0"
		CLASS.Model		 = "models/engines/inline4l.mdl"
		CLASS.Sound		 = "acf_base/engines/i4_petrollarge.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 600
		CLASS.Torque		 = 1165
		CLASS.FlywheelMass = 4
		CLASS.RPM = {
			Idle	= 500,
			Limit	= 3400,
		}
		CLASS.Preview = {
			FOV = 120,
		}
	end)
end

do -- Diesel Engines
	Classes.DefineClass("ACF.Engines.1.6-I4", "ACF.Engines.I4", function()
		CLASS.Name		 = "1.6L I4 Diesel"
		CLASS.Description	 = "#acf.descs.engines.i4.1_6"
		CLASS.Model		 = "models/engines/inline4s.mdl"
		CLASS.Sound		 = "acf_base/engines/i4_diesel2.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 90
		CLASS.Torque		 = 184
		CLASS.FlywheelMass = 0.2
		CLASS.RPM = {
			Idle	= 650,
			Limit	= 5000,
		}
		CLASS.Preview = {
			FOV = 120,
		}
	end)

	Classes.DefineClass("ACF.Engines.3.1-I4", "ACF.Engines.I4", function()
		CLASS.Name		 = "3.1L I4 Diesel"
		CLASS.Description	 = "#acf.descs.engines.i4.3_1"
		CLASS.Model		 = "models/engines/inline4m.mdl"
		CLASS.Sound		 = "acf_base/engines/i4_dieselmedium.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 250
		CLASS.Torque		 = 510
		CLASS.FlywheelMass = 1
		CLASS.RPM = {
			Idle	= 500,
			Limit	= 4000,
		}
		CLASS.Preview = {
			FOV = 120,
		}
	end)

	Classes.DefineClass("ACF.Engines.15.0-I4", "ACF.Engines.I4", function()
		CLASS.Name		 = "15.0L I4 Diesel"
		CLASS.Description	 = "#acf.descs.engines.i4.15_0"
		CLASS.Model		 = "models/engines/inline4l.mdl"
		CLASS.Sound		 = "acf_base/engines/i4_diesellarge.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 800
		CLASS.Torque		 = 2060
		CLASS.FlywheelMass = 5
		CLASS.RPM = {
			Idle	= 450,
			Limit	= 2100,
		}
		CLASS.Preview = {
			FOV = 120,
		}
	end)
end

ACF.SetCustomAttachment("models/engines/inline4l.mdl", "driveshaft", Vector(-15, 0, 10), Angle(0, 180, 90))
ACF.SetCustomAttachment("models/engines/inline4m.mdl", "driveshaft", Vector(-9, 0, 6), Angle(0, 180, 90))
ACF.SetCustomAttachment("models/engines/inline4s.mdl", "driveshaft", Vector(-6, 0, 4), Angle(0, 180, 90))

local Models = {
	{ Model = "models/engines/inline4l.mdl", Scale = 2.5 },
	{ Model = "models/engines/inline4m.mdl", Scale = 1.5 },
	{ Model = "models/engines/inline4s.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Shaft = {
			Pos       = Vector(0.5, 0, 4.75) * Scale,
			Scale     = Vector(23, 7.5, 9) * Scale,
			Sensitive = true
		},
		Pistons = {
			Pos   = Vector(1.25, 0, 13.25) * Scale,
			Scale = Vector(18.25, 5.25, 8) * Scale
		}
	})
end
