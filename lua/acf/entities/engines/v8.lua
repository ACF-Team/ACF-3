local ACF     = ACF
local Classes = ACF.Classes
Classes.DefineClass("ACF.Engines.V8", "ACF.Engines.BaseEngine", function()
	CLASS.Name = "V8 Engine"
end)

do -- Petrol Engines
	Classes.DefineClass("ACF.Engines.5.7-V8", "ACF.Engines.V8", function()
		CLASS.Name		 = "5.7L V8 Petrol"
		CLASS.Description	 = "#acf.descs.engines.v8.5_7"
		CLASS.Model		 = "models/engines/v8s.mdl"
		CLASS.Sound		 = "acf_base/engines/v8_petrolsmall.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 260
		CLASS.Torque		 = 389
		CLASS.FlywheelMass = 0.15
		CLASS.RPM = {
			Idle	= 800,
			Limit	= 5700,
		}
		CLASS.Preview = {
			FOV = 100,
		}
	end)

	Classes.DefineClass("ACF.Engines.9.0-V8", "ACF.Engines.V8", function()
		CLASS.Name		 = "9.0L V8 Petrol"
		CLASS.Description	 = "#acf.descs.engines.v8.9_0"
		CLASS.Model		 = "models/engines/v8m.mdl"
		CLASS.Sound		 = "acf_base/engines/v8_petrolmedium.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 400
		CLASS.Torque		 = 576
		CLASS.FlywheelMass = 0.25
		CLASS.RPM = {
			Idle	= 700,
			Limit	= 5500,
		}
		CLASS.Preview = {
			FOV = 100,
		}
	end)

	Classes.DefineClass("ACF.Engines.18.0-V8", "ACF.Engines.V8", function()
		CLASS.Name		 = "18.0L V8 Petrol"
		CLASS.Description	 = "#acf.descs.engines.v8.18_0"
		CLASS.Model		 = "models/engines/v8l.mdl"
		CLASS.Sound		 = "acf_base/engines/v8_petrollarge.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 850
		CLASS.Torque		 = 1848
		CLASS.FlywheelMass = 2.8
		CLASS.RPM = {
			Idle	= 600,
			Limit	= 3000,
		}
		CLASS.Preview = {
			FOV = 100,
		}
	end)
end

do -- Diesel Engines
	Classes.DefineClass("ACF.Engines.4.5-V8", "ACF.Engines.V8", function()
		CLASS.Name		 = "4.5L V8 Diesel"
		CLASS.Description	 = "#acf.descs.engines.v8.4_5"
		CLASS.Model		 = "models/engines/v8s.mdl"
		CLASS.Sound		 = "acf_base/engines/v8_dieselsmall.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 320
		CLASS.Torque		 = 446
		CLASS.FlywheelMass = 0.75
		CLASS.RPM = {
			Idle	= 800,
			Limit	= 4000,
		}
		CLASS.Preview = {
			FOV = 100,
		}
	end)

	Classes.DefineClass("ACF.Engines.7.8-V8", "ACF.Engines.V8", function()
		CLASS.Name		 = "7.8L V8 Diesel"
		CLASS.Description	 = "#acf.descs.engines.v8.7_8"
		CLASS.Model		 = "models/engines/v8m.mdl"
		CLASS.Sound		 = "acf_base/engines/v8_dieselmedium2.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 520
		CLASS.Torque		 = 870
		CLASS.FlywheelMass = 1.6
		CLASS.RPM = {
			Idle	= 650,
			Limit	= 3800,
		}
		CLASS.Preview = {
			FOV = 100,
		}
	end)

	Classes.DefineClass("ACF.Engines.19.0-V8", "ACF.Engines.V8", function()
		CLASS.Name		 = "19.0L V8 Diesel"
		CLASS.Description	 = "#acf.descs.engines.v8.19_0"
		CLASS.Model		 = "models/engines/v8l.mdl"
		CLASS.Sound		 = "acf_base/engines/v8_diesellarge.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 1200
		CLASS.Torque		 = 3308
		CLASS.FlywheelMass = 4.5
		CLASS.RPM = {
			Idle	= 500,
			Limit	= 2000,
		}
		CLASS.Preview = {
			FOV = 100,
		}
	end)
end

ACF.SetCustomAttachment("models/engines/v8l.mdl", "driveshaft", Vector(-25.6, 0, 7.4), Angle(0, 90, 90))
ACF.SetCustomAttachment("models/engines/v8m.mdl", "driveshaft", Vector(-17.02, 0, 4.92), Angle(0, 90, 90))
ACF.SetCustomAttachment("models/engines/v8s.mdl", "driveshaft", Vector(-13.62, 0, 3.94), Angle(0, 90, 90))

local Models = {
	{ Model = "models/engines/v8l.mdl", Scale = 1.85 },
	{ Model = "models/engines/v8m.mdl", Scale = 1.25 },
	{ Model = "models/engines/v8s.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Main = {
			Pos       = Vector(-1.25, 0, 7.5) * Scale,
			Scale     = Vector(27.5, 11.5, 16.5) * Scale,
			Sensitive = true
		},
		LeftBank = {
			Pos   = Vector(0, -6.5, 11) * Scale,
			Scale = Vector(25, 8, 11.25) * Scale,
			Angle = Angle(0, 0, 45)
		},
		RightBank = {
			Pos   = Vector(0, 6.5, 11) * Scale,
			Scale = Vector(25, 8, 11.25) * Scale,
			Angle = Angle(0, 0, -45)
		}
	})
end
