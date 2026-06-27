local ACF     = ACF
local Classes = ACF.Classes
Classes.DefineClass("ACF.Engines.V2", "ACF.Engines.BaseEngine", function()
	CLASS.Name = "V-Twin Engine"
end)

do -- Petrol Engines
	Classes.DefineClass("ACF.Engines.0.6-V2", "ACF.Engines.V2", function()
		CLASS.Name		 = "600cc V-Twin"
		CLASS.Description	 = "#acf.descs.engines.v2.0_6"
		CLASS.Model		 = "models/engines/v-twins2.mdl"
		CLASS.Sound		 = "acf_base/engines/vtwin_small.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 30
		CLASS.Torque		 = 62
		CLASS.FlywheelMass = 0.01
		CLASS.RPM = {
			Idle	= 900,
			Limit	= 7000,
		}
		CLASS.Preview = {
			FOV = 115,
		}
	end)

	Classes.DefineClass("ACF.Engines.1.2-V2", "ACF.Engines.V2", function()
		CLASS.Name		 = "1200cc V-Twin"
		CLASS.Description	 = "#acf.descs.engines.v2.1_2"
		CLASS.Model		 = "models/engines/v-twinm2.mdl"
		CLASS.Sound		 = "acf_base/engines/vtwin_medium.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 50
		CLASS.Torque		 = 106
		CLASS.FlywheelMass = 0.02
		CLASS.RPM = {
			Idle	= 725,
			Limit	= 6250,
		}
		CLASS.Preview = {
			FOV = 115,
		}
	end)

	Classes.DefineClass("ACF.Engines.2.4-V2", "ACF.Engines.V2", function()
		CLASS.Name		 = "2400cc V-Twin"
		CLASS.Description	 = "#acf.descs.engines.v2.2_4"
		CLASS.Model		 = "models/engines/v-twinl2.mdl"
		CLASS.Sound		 = "acf_base/engines/vtwin_large.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 100
		CLASS.Torque		 = 200
		CLASS.FlywheelMass = 0.075
		CLASS.RPM = {
			Idle	= 900,
			Limit	= 6000,
		}
		CLASS.Preview = {
			FOV = 115,
		}
	end)
end

ACF.SetCustomAttachment("models/engines/v-twinl2.mdl", "driveshaft", Vector(), Angle(0, 90, 90))
ACF.SetCustomAttachment("models/engines/v-twinm2.mdl", "driveshaft", Vector(), Angle(0, 90, 90))
ACF.SetCustomAttachment("models/engines/v-twins2.mdl", "driveshaft", Vector(), Angle(0, 90, 90))

local Models = {
	{ Model = "models/engines/v-twinl2.mdl", Scale = 1.67 },
	{ Model = "models/engines/v-twinm2.mdl", Scale = 1.33 },
	{ Model = "models/engines/v-twins2.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Shaft = {
			Pos       = Vector(4.25) * Scale,
			Scale     = Vector(9, 8, 8) * Scale,
			Sensitive = true
		},
		Piston1 = {
			Pos   = Vector(5, -4, 8.5) * Scale,
			Scale = Vector(6, 6, 12) * Scale,
			Angle = Angle(0, 0, 25)
		},
		Piston2 = {
			Pos   = Vector(5, 4, 8.5) * Scale,
			Scale = Vector(6, 6, 12) * Scale,
			Angle = Angle(0, 0, -25)
		}
	})
end
