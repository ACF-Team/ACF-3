local ACF     = ACF
local Classes = ACF.Classes

Classes.DefineClass("ACF.Engines.I5", "ACF.Engines.BaseEngine", function()
	CLASS.Name = "Inline 5 Engine"
end)

do -- Petrol Engines
	Classes.DefineClass("ACF.Engines.2.3-I5", "ACF.Engines.I5", function()
		CLASS.Name		 = "2.3L I5 Petrol"
		CLASS.Description	 = "#acf.descs.engines.i5.2_3"
		CLASS.Model		 = "models/engines/inline5s.mdl"
		CLASS.Sound		 = "acf_base/engines/i5_petrolsmall.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 100
		CLASS.Torque		 = 156
		CLASS.FlywheelMass = 0.12
		CLASS.RPM = {
			Idle	= 900,
			Limit	= 7000,
		}
		CLASS.Preview = {
			FOV = 117,
		}
	end)

	Classes.DefineClass("ACF.Engines.3.9-I5", "ACF.Engines.I5", function()
		CLASS.Name		 = "3.9L I5 Petrol"
		CLASS.Description	 = "#acf.descs.engines.i5.3_9"
		CLASS.Model		 = "models/engines/inline5m.mdl"
		CLASS.Sound		 = "acf_base/engines/i5_petrolmedium.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 250
		CLASS.Torque		 = 343
		CLASS.FlywheelMass = 0.25
		CLASS.RPM = {
			Idle	= 700,
			Limit	= 6500,
		}
		CLASS.Preview = {
			FOV = 117,
		}
	end)
end

do -- Diesel Engines
	Classes.DefineClass("ACF.Engines.2.9-I5", "ACF.Engines.I5", function()
		CLASS.Name		 = "2.9L I5 Diesel"
		CLASS.Description	 = "#acf.descs.engines.i5.2_9"
		CLASS.Model		 = "models/engines/inline5s.mdl"
		CLASS.Sound		 = "acf_base/engines/i5_dieselsmall2.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 130
		CLASS.Torque		 = 225
		CLASS.FlywheelMass = 0.5
		CLASS.RPM = {
			Idle	= 500,
			Limit	= 4200,
		}
		CLASS.Preview = {
			FOV = 117,
		}
	end)

	Classes.DefineClass("ACF.Engines.4.1-I5", "ACF.Engines.I5", function()
		CLASS.Name		 = "4.1L I5 Diesel"
		CLASS.Description	 = "#acf.descs.engines.i5.4_1"
		CLASS.Model		 = "models/engines/inline5m.mdl"
		CLASS.Sound		 = "acf_base/engines/i5_dieselmedium.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 400
		CLASS.Torque		 = 550
		CLASS.FlywheelMass = 1.5
		CLASS.RPM = {
			Idle	= 650,
			Limit	= 3800,
		}
		CLASS.Preview = {
			FOV = 117,
		}
	end)
end

ACF.SetCustomAttachment("models/engines/inline5m.mdl", "driveshaft", Vector(-15, 0, 6.6), Angle(0, 180, 90))
ACF.SetCustomAttachment("models/engines/inline5s.mdl", "driveshaft", Vector(-10, 0, 4.4), Angle(0, 180, 90))

local Models = {
	{ Model = "models/engines/inline5b.mdl", Scale = 2.5 },
	{ Model = "models/engines/inline5m.mdl", Scale = 1.5 },
	{ Model = "models/engines/inline5s.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Shaft = {
			Pos       = Vector(-0.75, 0, 4.75) * Scale,
			Scale     = Vector(28, 7.5, 9) * Scale,
			Sensitive = true
		},
		Pistons = {
			Pos   = Vector(0.25, 0, 13.5) * Scale,
			Scale = Vector(23, 5.25, 8.5) * Scale
		}
	})
end
