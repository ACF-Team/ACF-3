local ACF     = ACF
local Classes = ACF.Classes
Classes.DefineClass("ACF.Engines.V6", "ACF.Engines.BaseEngine", function()
	CLASS.Name = "V6 Engine"
end)

do -- Petrol Engines
	Classes.DefineClass("ACF.Engines.3.6-V6", "ACF.Engines.V6", function()
		CLASS.Name		 = "3.6L V6 Petrol"
		CLASS.Description	 = "#acf.descs.engines.v6.3_6"
		CLASS.Model		 = "models/engines/v6small.mdl"
		CLASS.Sound		 = "acf_base/engines/v6_petrolsmall.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 190
		CLASS.Torque		 = 316
		CLASS.FlywheelMass = 0.25
		CLASS.RPM = {
			Idle	= 700,
			Limit	= 5000,
		}
		CLASS.Preview = {
			FOV = 105,
		}
	end)

	Classes.DefineClass("ACF.Engines.6.2-V6", "ACF.Engines.V6", function()
		CLASS.Name		 = "6.2L V6 Petrol"
		CLASS.Description	 = "#acf.descs.engines.v6.6_2"
		CLASS.Model		 = "models/engines/v6med.mdl"
		CLASS.Sound		 = "acf_base/engines/v6_petrolmedium.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 360
		CLASS.Torque		 = 590
		CLASS.FlywheelMass = 0.45
		CLASS.RPM = {
			Idle	= 800,
			Limit	= 5000,
		}
		CLASS.Preview = {
			FOV = 105,
		}
	end)

	Classes.DefineClass("ACF.Engines.12.0-V6", "ACF.Engines.V6", function()
		CLASS.Name		 = "12.0L V6 Petrol"
		CLASS.Description	 = "#acf.descs.engines.v6.12_0"
		CLASS.Model		 = "models/engines/v6large.mdl"
		CLASS.Sound		 = "acf_base/engines/v6_petrollarge.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 675
		CLASS.Torque		 = 1806
		CLASS.FlywheelMass = 4
		RPM = {
			Idle	= 600,
			Limit	= 3800,
		}
		CLASS.Preview = {
			FOV = 105,
		}
	end)
end

do -- Diesel Engines
	Classes.DefineClass("ACF.Engines.5.2-V6", "ACF.Engines.V6", function()
		CLASS.Name		 = "5.2L V6 Diesel"
		CLASS.Description	 = "#acf.descs.engines.v6.5_2"
		CLASS.Model		 = "models/engines/v6med.mdl"
		CLASS.Sound		 = "acf_base/engines/i5_dieselmedium.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 520
		CLASS.Torque		 = 606
		CLASS.FlywheelMass = 0.8
		CLASS.RPM = {
			Idle	= 650,
			Limit	= 4300,
		}
		CLASS.Preview = {
			FOV = 105,
		}
	end)

	Classes.DefineClass("ACF.Engines.15.0-V6", "ACF.Engines.V6", function()
		CLASS.Name		 = "15.0L V6 Diesel"
		CLASS.Description	 = "#acf.descs.engines.v6.15_0"
		CLASS.Model		 = "models/engines/v6large.mdl"
		CLASS.Sound		 = "acf_base/engines/v6_diesellarge.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 900
		CLASS.Torque		 = 2208
		CLASS.FlywheelMass = 6.4
		CLASS.RPM = {
			Idle	= 400,
			Limit	= 3100,
		}
		CLASS.Preview = {
			FOV = 105,
		}
	end)
end

ACF.SetCustomAttachment("models/engines/v6large.mdl", "driveshaft", Vector(2), Angle(0, 90, 90))
ACF.SetCustomAttachment("models/engines/v6med.mdl", "driveshaft", Vector(1.33), Angle(0, 90, 90))
ACF.SetCustomAttachment("models/engines/v6small.mdl", "driveshaft", Vector(1.06), Angle(0, 90, 90))

local Models = {
	{ Model = "models/engines/v6large.mdl", Scale = 1.85 },
	{ Model = "models/engines/v6med.mdl", Scale = 1.25 },
	{ Model = "models/engines/v6small.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Main = {
			Pos       = Vector(10.5, 0, 3.75) * Scale,
			Scale     = Vector(22, 11.5, 16.25) * Scale,
			Sensitive = true
		},
		LeftBank = {
			Pos   = Vector(11.5, -6.5, 7) * Scale,
			Scale = Vector(20, 8, 11) * Scale,
			Angle = Angle(0, 0, 45)
		},
		RightBank = {
			Pos   = Vector(11.5, 6.5, 7) * Scale,
			Scale = Vector(20, 8, 11) * Scale,
			Angle = Angle(0, 0, -45)
		}
	})
end
