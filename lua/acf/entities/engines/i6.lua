local ACF     = ACF
local Classes = ACF.Classes

Classes.DefineClass("ACF.Engines.I6", "ACF.Engines.BaseEngine", function()
	CLASS.Name = "Inline 6 Engine"
end)

do -- Petrol Engines
	Classes.DefineClass("ACF.Engines.2.2-I6", "ACF.Engines.I6", function()
		CLASS.Name		 = "2.2L I6 Petrol"
		CLASS.Description	 = "#acf.descs.engines.i6.2_2"
		CLASS.Model		 = "models/engines/inline6s.mdl"
		CLASS.Sound		 = "acf_base/engines/l6_petrolsmall2.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 120
		CLASS.Torque		 = 169
		CLASS.FlywheelMass = 0.1
		CLASS.RPM = {
			Idle	= 800,
			Limit	= 7500,
		}
		CLASS.Preview = {
			FOV = 112,
		}
	end)

	Classes.DefineClass("ACF.Engines.4.8-I6", "ACF.Engines.I6", function()
		CLASS.Name		 = "4.8L I6 Petrol"
		CLASS.Description	 = "#acf.descs.engines.i6.4_8"
		CLASS.Model		 = "models/engines/inline6m.mdl"
		CLASS.Sound		 = "acf_base/engines/l6_petrolmedium.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 300
		CLASS.Torque		 = 460
		CLASS.FlywheelMass = 0.2
		CLASS.RPM = {
			Idle	= 900,
			Limit	= 5500,
		}
		CLASS.Preview = {
			FOV = 112,
		}
	end)

	Classes.DefineClass("ACF.Engines.17.2-I6", "ACF.Engines.I6", function()
		CLASS.Name		 = "17.2L I6 Petrol"
		CLASS.Description	 = "#acf.descs.engines.i6.17_2"
		CLASS.Model		 = "models/engines/inline6l.mdl"
		CLASS.Sound		 = "acf_base/engines/l6_petrollarge2.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 850
		CLASS.Torque		 = 1760
		CLASS.FlywheelMass = 2.5
		CLASS.RPM = {
			Idle	= 800,
			Limit	= 2700,
		}
		CLASS.Preview = {
			FOV = 112,
		}
	end)
end

do -- Diesel Engines
	Classes.DefineClass("ACF.Engines.3.0-I6", "ACF.Engines.I6", function()
		CLASS.Name		 = "3.0L I6 Diesel"
		CLASS.Description	 = "#acf.descs.engines.i6.3_0"
		CLASS.Model		 = "models/engines/inline6s.mdl"
		CLASS.Sound		 = "acf_base/engines/l6_dieselsmall.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 150
		CLASS.Torque		 = 250
		CLASS.FlywheelMass = 0.5
		CLASS.RPM = {
			Idle	= 650,
			Limit	= 4900,
		}
		CLASS.Preview = {
			FOV = 112,
		}
	end)

	Classes.DefineClass("ACF.Engines.6.5-I6", "ACF.Engines.I6", function()
		CLASS.Name		 = "6.5L I6 Diesel"
		CLASS.Description	 = "#acf.descs.engines.i6.6_5"
		CLASS.Model		 = "models/engines/inline6m.mdl"
		CLASS.Sound		 = "acf_base/engines/l6_dieselmedium4.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 450
		CLASS.Torque		 = 700
		CLASS.FlywheelMass = 1.5
		CLASS.RPM = {
			Idle	= 600,
			Limit	= 4000,
		}
		CLASS.Preview = {
			FOV = 112,
		}
	end)

	Classes.DefineClass("ACF.Engines.20.0-I6", "ACF.Engines.I6", function()
		CLASS.Name		 = "20.0L I6 Diesel"
		CLASS.Description	 = "#acf.descs.engines.i6.20_0"
		CLASS.Model		 = "models/engines/inline6l.mdl"
		CLASS.Sound		 = "acf_base/engines/l6_diesellarge2.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 1200
		CLASS.Torque		 = 2490
		CLASS.FlywheelMass = 8
		CLASS.RPM = {
			Idle	= 400,
			Limit	= 2350,
		}
		CLASS.Preview = {
			FOV = 112,
		}
	end)
end

ACF.SetCustomAttachment("models/engines/inline6l.mdl", "driveshaft", Vector(-30, 0, 11), Angle(0, 180, 90))
ACF.SetCustomAttachment("models/engines/inline6m.mdl", "driveshaft", Vector(-18, 0, 6.6), Angle(0, 180, 90))
ACF.SetCustomAttachment("models/engines/inline6s.mdl", "driveshaft", Vector(-12, 0, 4.4), Angle(0, 180, 90))

local Models = {
	{ Model = "models/engines/inline6l.mdl", Scale = 2.5 },
	{ Model = "models/engines/inline6m.mdl", Scale = 1.5 },
	{ Model = "models/engines/inline6s.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Shaft = {
			Pos       = Vector(0.5, 0, 4.75) * Scale,
			Scale     = Vector(32, 7.5, 9) * Scale,
			Sensitive = true
		},
		Pistons = {
			Pos   = Vector(1.25, 0, 13.5) * Scale,
			Scale = Vector(27, 5.25, 8.5) * Scale
		}
	})
end
