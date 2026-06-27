local ACF     = ACF
local Classes = ACF.Classes
Classes.DefineClass("ACF.Engines.V12", "ACF.Engines.BaseEngine", function()
	CLASS.Name = "V12 Engine"
end)

do -- Petrol Engines
	Classes.DefineClass("ACF.Engines.4.6-V12", "ACF.Engines.V12", function()
		CLASS.Name		 = "4.6L V12 Petrol"
		CLASS.Description	 = "#acf.descs.engines.v12.4_6"
		CLASS.Model		 = "models/engines/v12s.mdl"
		CLASS.Sound		 = "acf_base/engines/v12_petrolsmall.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 188
		CLASS.Torque		 = 317
		CLASS.FlywheelMass = 0.2
		CLASS.RPM = {
			Idle	= 1000,
			Limit	= 8000,
		}
		CLASS.Preview = {
			FOV = 95,
		}
	end)

	Classes.DefineClass("ACF.Engines.7.0-V12", "ACF.Engines.V12", function()
		CLASS.Name		 = "7.0L V12 Petrol"
		CLASS.Description	 = "#acf.descs.engines.v12.7_0"
		CLASS.Model		 = "models/engines/v12m.mdl"
		CLASS.Sound		 = "acf_base/engines/v12_petrolmedium.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 360
		CLASS.Torque		 = 726
		CLASS.FlywheelMass = 0.45
		CLASS.RPM = {
			Idle	= 800,
			Limit	= 6000,
		}
		CLASS.Preview = {
			FOV = 95,
		}
	end)

	Classes.DefineClass("ACF.Engines.13.0-V12", "ACF.Engines.V12", function()
		CLASS.Name		 = "13.0L V12 Petrol"
		CLASS.Description	 = "#acf.descs.engines.v12.13_0"
		CLASS.Model		 = "models/engines/v12m.mdl"
		CLASS.Sound		 = "acf_base/engines/v12_special.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 520
		CLASS.Torque		 = 932
		CLASS.FlywheelMass = 2
		CLASS.RPM = {
			Idle	= 700,
			Limit	= 4250,
		}
		CLASS.Preview = {
			FOV = 95,
		}
	end)

	Classes.DefineClass("ACF.Engines.23.0-V12", "ACF.Engines.V12", function()
		CLASS.Name		 = "23.0L V12 Petrol"
		CLASS.Description	 = "#acf.descs.engines.v12.23_0"
		CLASS.Model		 = "models/engines/v12l.mdl"
		CLASS.Sound		 = "acf_base/engines/v12_petrollarge.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 1350
		CLASS.Torque		 = 2436
		CLASS.FlywheelMass = 5
		CLASS.RPM = {
			Idle	= 600,
			Limit	= 3250,
		}
		CLASS.Preview = {
			FOV = 95,
		}
	end)
end

do -- Diesel Engines
	Classes.DefineClass("ACF.Engines.4.0-V12", "ACF.Engines.V12", function()
		CLASS.Name		 = "4.0L V12 Diesel"
		CLASS.Description	 = "#acf.descs.engines.v12.4_0"
		CLASS.Model		 = "models/engines/v12s.mdl"
		CLASS.Sound		 = "acf_base/engines/v12_dieselsmall.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 305
		CLASS.Torque		 = 510
		CLASS.FlywheelMass = 0.475
		CLASS.RPM = {
			Idle	= 650,
			Limit	= 4000,
		}
		CLASS.Preview = {
			FOV = 95,
		}
	end)

	Classes.DefineClass("ACF.Engines.9.2-V12", "ACF.Engines.V12", function()
		CLASS.Name		 = "9.2L V12 Diesel"
		CLASS.Description	 = "#acf.descs.engines.v12.9_2"
		CLASS.Model		 = "models/engines/v12m.mdl"
		CLASS.Sound		 = "acf_base/engines/v12_dieselmedium.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 600
		CLASS.Torque		 = 1202
		CLASS.FlywheelMass = 2.5
		CLASS.RPM = {
			Idle	= 675,
			Limit	= 3600,
		}
		CLASS.Preview = {
			FOV = 95,
		}
	end)

	Classes.DefineClass("ACF.Engines.21.0-V12", "ACF.Engines.V12", function()
		CLASS.Name		 = "21.0L V12 Diesel"
		CLASS.Description	 = "#acf.descs.engines.v12.21_0"
		CLASS.Model		 = "models/engines/v12l.mdl"
		CLASS.Sound		 = "acf_base/engines/v12_diesellarge.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 1800
		CLASS.Torque		 = 4325
		CLASS.FlywheelMass = 7
		CLASS.RPM = {
			Idle	= 400,
			Limit	= 2000,
		}
		CLASS.Preview = {
			FOV = 95,
		}
	end)
end

ACF.SetCustomAttachment("models/engines/v12l.mdl", "driveshaft", Vector(-34, 0, 7.3), Angle(0, 90, 90))
ACF.SetCustomAttachment("models/engines/v12m.mdl", "driveshaft", Vector(-22.61, 0, 4.85), Angle(0, 90, 90))
ACF.SetCustomAttachment("models/engines/v12s.mdl", "driveshaft", Vector(-18.09, 0, 3.88), Angle(0, 90, 90))

local Models = {
	{ Model = "models/engines/v12l.mdl", Scale = 1.85 },
	{ Model = "models/engines/v12m.mdl", Scale = 1.25 },
	{ Model = "models/engines/v12s.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Main = {
			Pos   = Vector(-1.25, 0, 7.5) * Scale,
			Scale = Vector(36, 11.5, 16.5) * Scale,
			Sensitive = true
		},
		LeftBank = {
			Pos   = Vector(-0.25, -6.5, 11) * Scale,
			Scale = Vector(34, 8, 11.25) * Scale,
			Angle = Angle(0, 0, 45)
		},
		RightBank = {
			Pos   = Vector(-0.25, 6.5, 11) * Scale,
			Scale = Vector(34, 8, 11.25) * Scale,
			Angle = Angle(0, 0, -45)
		}
	})
end
