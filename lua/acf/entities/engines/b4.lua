local ACF     = ACF
local Classes = ACF.Classes

Classes.DefineClass("ACF.Engines.B4", "ACF.Engines.BaseEngine", function()
	CLASS.Name = "Flat 4 Engine"
end)

do
	Classes.DefineClass("ACF.Engines.1.4-B4", "ACF.Engines.B4", function()
		CLASS.Name		 = "1.4L Flat 4 Petrol"
		CLASS.Description	 = "#acf.descs.engines.b4.1_4"
		CLASS.Model		 = "models/engines/b4small.mdl"
		CLASS.Sound		 = "acf_base/engines/b4_petrolsmall.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 60
		CLASS.Torque		 = 131
		CLASS.FlywheelMass = 0.06
		CLASS.RPM = {
			Idle	= 600,
			Limit	= 4500,
		}
		CLASS.Preview = {
			FOV = 80,
		}
	end)

	Classes.DefineClass("ACF.Engines.2.1-B4", "ACF.Engines.B4", function()
		CLASS.Name		 = "2.1L Flat 4 Petrol"
		CLASS.Description	 = "#acf.descs.engines.b4.2_1"
		CLASS.Model		 = "models/engines/b4small.mdl"
		CLASS.Sound		 = "acf_base/engines/b4_petrolmedium.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 125
		CLASS.Torque		 = 225
		CLASS.FlywheelMass = 0.15
		CLASS.RPM = {
			Idle	= 700,
			Limit	= 5000
		}
		CLASS.Preview = {
			FOV = 80
		}
	end)

	Classes.DefineClass("ACF.Engines.2.4-B4", "ACF.Engines.B4", function()
		CLASS.Name		 = "2.4L Flat 4 Multifuel"
		CLASS.Description	 = "#acf.descs.engines.b4.2_4"
		CLASS.Model		 = "models/engines/b4small.mdl"
		CLASS.Sound		 = "acf_extra/vehiclefx/engines/coh/ba11.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true, ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 135
		CLASS.Torque		 = 310
		CLASS.FlywheelMass = 0.4
		CLASS.RPM = {
			Idle	= 550,
			Limit	= 2800
		}
		CLASS.Preview = {
			FOV = 80
		}
	end)

	Classes.DefineClass("ACF.Engines.3.2-B4", "ACF.Engines.B4", function()
		CLASS.Name		 = "3.2L Flat 4 Petrol"
		CLASS.Description	 = "#acf.descs.engines.b4.3_2" -- Ok
		CLASS.Model		 = "models/engines/b4med.mdl"
		CLASS.Sound		 = "acf_base/engines/b4_petrollarge.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 210
		CLASS.Torque		 = 315
		CLASS.FlywheelMass = 0.15
		CLASS.RPM = {
			Idle	= 900,
			Limit	= 6500
		}
		CLASS.Preview = {
			FOV = 85,
		}
	end)
end

ACF.SetCustomAttachment("models/engines/b4med.mdl", "driveshaft", Vector(), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/engines/b4small.mdl", "driveshaft", Vector(), Angle(0, 0, 90))

local Models = {
	{ Model = "models/engines/b4med.mdl", Scale = 1.25 },
	{ Model = "models/engines/b4small.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Main = {
			Pos       = Vector(8.5, 0, 0.5) * Scale,
			Scale     = Vector(18, 16, 9) * Scale,
			Sensitive = true
		},
		UpperSection = {
			Pos   = Vector(7, 0, 7) * Scale,
			Scale = Vector(11, 23, 4) * Scale
		},
		LeftBank = {
			Pos   = Vector(9, -10, 2) * Scale,
			Scale = Vector(16, 4, 6) * Scale
		},
		RightBank = {
			Pos   = Vector(9, 10, 2) * Scale,
			Scale = Vector(16, 4, 6) * Scale
		}
	})
end
