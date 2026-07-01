local ACF     = ACF
local Classes = ACF.Classes

Classes.DefineClass("ACF.Engines.B6", "ACF.Engines.BaseEngine", function()
	CLASS.Name = "Flat 6 Engine"
end)

do
	Classes.DefineClass("ACF.Engines.2.8-B6", "ACF.Engines.B6", function()
		CLASS.Name		 = "2.8L Flat 6 Petrol"
		CLASS.Description	 = "#acf.descs.engines.b6.2_8"
		CLASS.Model		 = "models/engines/b6small.mdl"
		CLASS.Sound		 = "acf_base/engines/b6_petrolsmall.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 100
		CLASS.Torque		 = 170
		CLASS.FlywheelMass = 0.08
		CLASS.RPM = {
			Idle	= 750,
			Limit	= 7250,
		}
		CLASS.Preview = {
			FOV = 85,
		}
	end)

	Classes.DefineClass("ACF.Engines.5.0-B6", "ACF.Engines.B6", function()
		CLASS.Name		 = "5.0L Flat 6 Petrol"
		CLASS.Description	 = "#acf.descs.engines.b6.5_0"
		CLASS.Model		 = "models/engines/b6med.mdl"
		CLASS.Sound		 = "acf_base/engines/b6_petrolmedium.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 240
		CLASS.Torque		 = 412
		CLASS.FlywheelMass = 0.11
		CLASS.RPM = {
			Idle	= 900,
			Limit	= 6800,
		}
		CLASS.Preview = {
			FOV = 83,
		}
	end)

	Classes.DefineClass("ACF.Engines.8.3-B6", "ACF.Engines.B6", function()
		CLASS.Name		 = "8.3L Flat 6 Multifuel"
		CLASS.Description	 = "#acf.descs.engines.b6.8_3"
		CLASS.Model		 = "models/engines/b6med.mdl"
		CLASS.Sound		 = "acf_base/engines/v8_diesel.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true, ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 480
		CLASS.Torque		 = 606
		CLASS.FlywheelMass = 0.65
		CLASS.RPM = {
			Idle	= 500,
			Limit	= 4200,
		}
		CLASS.Preview = {
			FOV = 83,
		}
	end)

	Classes.DefineClass("ACF.Engines.15.8-B6", "ACF.Engines.B6", function()
		CLASS.Name		 = "15.8L Flat 6 Petrol"
		CLASS.Description	 = "#acf.descs.engines.b6.15_8"
		CLASS.Model		 = "models/engines/b6large.mdl"
		CLASS.Sound		 = "acf_base/engines/b6_petrollarge.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 725
		CLASS.Torque		 = 1375
		CLASS.FlywheelMass = 1
		CLASS.RPM = {
			Idle	= 620,
			Limit	= 4900,
		}
		CLASS.Preview = {
			FOV = 83,
		}
	end)

	Classes.DefineClass("ACF.Engines.14.5-B6", "ACF.Engines.B6", function()
		CLASS.Name		 = "14.5L Flat 6 Diesel"
		CLASS.Description	 = "#acf.descs.engines.b6.14_5"
		CLASS.Model		 = "models/engines/b6large.mdl"
		CLASS.Sound		 = "acf_base/engines/i6_diesellarge2.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 1600
		CLASS.Torque		 = 1995
		CLASS.FlywheelMass = 3
		CLASS.RPM = {
			Idle	= 620,
			Limit	= 2550,
		}
		CLASS.Preview = {
			FOV = 83,
		}
	end)
end

ACF.SetCustomAttachment("models/engines/b6large.mdl", "driveshaft", Vector(), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/engines/b6med.mdl", "driveshaft", Vector(), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/engines/b6small.mdl", "driveshaft", Vector(), Angle(0, 0, 90))

local Models = {
	{ Model = "models/engines/b6large.mdl", Scale = 2.25 },
	{ Model = "models/engines/b6med.mdl", Scale = 1.5 }, -- yes a medium B6 is overall larger than a medium B4 in more than length because ??????
	{ Model = "models/engines/b6small.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Main = {
			Pos       = Vector(11, 0, 0.5) * Scale,
			Scale     = Vector(22, 16, 9) * Scale,
			Sensitive = true
		},
		UpperSection = {
			Pos   = Vector(9, 0, 7) * Scale,
			Scale = Vector(15, 23, 4) * Scale
		},
		LeftBank = {
			Pos   = Vector(12, -10, 2) * Scale,
			Scale = Vector(20, 4, 6) * Scale
		},
		RightBank = {
			Pos   = Vector(12, 10, 2) * Scale,
			Scale = Vector(20, 4, 6) * Scale
		}
	})
end
