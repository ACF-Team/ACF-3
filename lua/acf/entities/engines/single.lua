local ACF     = ACF
local Classes = ACF.Classes

Classes.DefineClass("ACF.Engines.I1", "ACF.Engines.BaseEngine", function()
	CLASS.Name = "Single Cylinder Engine"
end)

do
	Classes.DefineClass("ACF.Engines.0.25-I1", "ACF.Engines.I1", function()
		CLASS.Name		 = "250cc Single Cylinder"
		CLASS.Description	 = "#acf.descs.engines.i1.0_25"
		CLASS.Model		 = "models/engines/1cylsml.mdl"
		CLASS.Sound		 = "acf_base/engines/i1_small.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 15
		CLASS.Torque		 = 25
		CLASS.FlywheelMass = 0.005
		CLASS.RPM = {
			Idle	= 1200,
			Limit	= 7500,
		}
		CLASS.Preview = {
			FOV = 125,
		}
	end)

	Classes.DefineClass("ACF.Engines.0.5-I1", "ACF.Engines.I1", function()
		CLASS.Name		 = "500cc Single Cylinder"
		CLASS.Description	 = "#acf.descs.engines.i1.0_5"
		CLASS.Model		 = "models/engines/1cylmed.mdl"
		CLASS.Sound		 = "acf_base/engines/i1_medium.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 20
		CLASS.Torque		 = 50
		CLASS.FlywheelMass = 0.005
		CLASS.RPM = {
			Idle	= 900,
			Limit	= 8000,
		}
		CLASS.Preview = {
			FOV = 125,
		}
	end)

	Classes.DefineClass("ACF.Engines.1.3-I1", "ACF.Engines.I1", function()
		CLASS.Name		 = "1300cc Single Cylinder"
		CLASS.Description	 = "#acf.descs.engines.i1.1_3"
		CLASS.Model		 = "models/engines/1cylbig.mdl"
		CLASS.Sound		 = "acf_base/engines/i1_large.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 50
		CLASS.Torque		 = 112
		CLASS.FlywheelMass = 0.1
		CLASS.RPM = {
			Idle	= 600,
			Limit	= 6700,
		}
		CLASS.Preview = {
			FOV = 125,
		}
	end)
end

ACF.SetCustomAttachment("models/engines/1cylbig.mdl", "driveshaft", Vector(), Angle(0, -90, 90))
ACF.SetCustomAttachment("models/engines/1cylmed.mdl", "driveshaft", Vector(), Angle(0, -90, 90))
ACF.SetCustomAttachment("models/engines/1cylsml.mdl", "driveshaft", Vector(), Angle(0, -90, 90))

local Models = {
	{ Model = "models/engines/1cylbig.mdl", Scale = 1.69 },
	{ Model = "models/engines/1cylmed.mdl", Scale = 1.35 },
	{ Model = "models/engines/1cylsml.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Shaft = {
			Pos       = Vector(4, 0, 0) * Scale,
			Scale     = Vector(16, 8, 8) * Scale,
			Sensitive = true
		},
		Piston = {
			Pos   = Vector(7.5, 0, 9.5) * Scale,
			Scale = Vector(9, 8, 11) * Scale
		}
	})
end
