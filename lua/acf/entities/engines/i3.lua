local ACF     = ACF
local Classes = ACF.Classes
Classes.DefineClass("ACF.Engines.I3", "ACF.Engines.BaseEngine", function()
	CLASS.Name = "Inline 3 Engine"
end)

do -- Petrol Engines
	Classes.DefineClass("ACF.Engines.1.2-I3", "ACF.Engines.I3", function()
		CLASS.Name		 = "1.2L I3 Petrol"
		CLASS.Description	 = "#acf.descs.engines.i3.1_2"
		CLASS.Model		 = "models/engines/inline3s.mdl"
		CLASS.Sound		 = "acf_base/engines/i4_petrolsmall2.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 40
		CLASS.Torque		 = 118
		CLASS.FlywheelMass = 0.05
		CLASS.RPM = {
			Idle	= 1100,
			Limit	= 6000,
		}
		CLASS.Preview = {
			FOV = 125,
		}
	end)

	Classes.DefineClass("ACF.Engines.3.4-I3", "ACF.Engines.I3", function()
		CLASS.Name		 = "3.4L I3 Petrol"
		CLASS.Description	 = "#acf.descs.engines.i3.3_4"
		CLASS.Model		 = "models/engines/inline3m.mdl"
		CLASS.Sound		 = "acf_base/engines/i4_petrolmedium2.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 170
		CLASS.Torque		 = 243
		CLASS.FlywheelMass = 0.2
		CLASS.RPM = {
			Idle	= 900,
			Limit	= 6800,
		}
		CLASS.Preview = {
			FOV = 125,
		}
	end)

	Classes.DefineClass("ACF.Engines.13.5-I3", "ACF.Engines.I3", function()
		CLASS.Name		 = "13.5L I3 Petrol"
		CLASS.Description	 = "#acf.descs.engines.i3.13_5"
		CLASS.Model		 = "models/engines/inline3b.mdl"
		CLASS.Sound		 = "acf_base/engines/i4_petrollarge.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 500
		CLASS.Torque		 = 893
		CLASS.FlywheelMass = 3.7
		CLASS.RPM = {
			Idle	= 500,
			Limit	= 3900,
		}
		CLASS.Preview = {
			FOV = 125,
		}
	end)
end

do -- Diesel Engines
	Classes.DefineClass("ACF.Engines.1.1-I3", "ACF.Engines.I3", function()
		CLASS.Name		 = "1.1L I3 Diesel"
		CLASS.Description	 = "#acf.descs.engines.i3.1_1"
		CLASS.Model		 = "models/engines/inline3s.mdl"
		CLASS.Sound		 = "acf_base/engines/i4_diesel2.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 65
		CLASS.Torque		 = 187
		CLASS.FlywheelMass = 0.2
		CLASS.RPM = {
			Idle	= 550,
			Limit	= 3000,
		}
		CLASS.Preview = {
			FOV = 125,
		}
	end)

	Classes.DefineClass("ACF.Engines.2.8-I3", "ACF.Engines.I3", function()
		CLASS.Name		 = "2.8L I3 Diesel"
		CLASS.Description	 = "#acf.descs.engines.i3.2_8"
		CLASS.Model		 = "models/engines/inline3m.mdl"
		CLASS.Sound		 = "acf_base/engines/i4_dieselmedium.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 200
		CLASS.Torque		 = 362
		CLASS.FlywheelMass = 1
		CLASS.RPM = {
			Idle	= 600,
			Limit	= 3800
		}
		CLASS.Preview = {
			FOV = 125,
		}
	end)

	Classes.DefineClass("ACF.Engines.11.0-I3", "ACF.Engines.I3", function()
		CLASS.Name		 = "11.0L I3 Diesel"
		CLASS.Description	 = "#acf.descs.engines.i3.11_0"
		CLASS.Model		 = "models/engines/inline3b.mdl"
		CLASS.Sound		 = "acf_base/engines/i4_diesellarge.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 650
		CLASS.Torque		 = 1500
		CLASS.FlywheelMass = 5
		CLASS.RPM = {
			Idle	= 550,
			Limit	= 2000
		}
		CLASS.Preview = {
			FOV = 125,
		}
	end)
end

ACF.SetCustomAttachment("models/engines/inline3b.mdl", "driveshaft", Vector(-15, 0, 11), Angle(0, 180, 90))
ACF.SetCustomAttachment("models/engines/inline3m.mdl", "driveshaft", Vector(-9, 0, 6.6), Angle(0, 180, 90))
ACF.SetCustomAttachment("models/engines/inline3s.mdl", "driveshaft", Vector(-6, 0, 4.4), Angle(0, 180, 90))

local Models = {
	{ Model = "models/engines/inline3b.mdl", Scale = 2.5 },
	{ Model = "models/engines/inline3m.mdl", Scale = 1.5 },
	{ Model = "models/engines/inline3s.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Shaft = {
			Pos       = Vector(0.5, 0, 4.75) * Scale,
			Scale     = Vector(18.5, 8, 9) * Scale,
			Sensitive = true
		},
		Pistons = {
			Pos   = Vector(1, 0.25, 13.25) * Scale,
			Scale = Vector(14, 5.5, 8) * Scale
		}
	})
end
