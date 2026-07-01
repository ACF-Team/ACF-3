local ACF     = ACF
local Classes = ACF.Classes
Classes.DefineClass("ACF.Engines.V10", "ACF.Engines.BaseEngine", function()
	CLASS.Name = "V10 Engine"
end)

do
	Classes.DefineClass("ACF.Engines.4.3-V10", "ACF.Engines.V10", function()
		CLASS.Name		 = "4.3L V10 Petrol"
		CLASS.Description	 = "#acf.descs.engines.v10.4_3"
		CLASS.Model		 = "models/engines/v10sml.mdl"
		CLASS.Sound		 = "acf_base/engines/v10_petrolsmall.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 160
		CLASS.Torque		 = 360
		CLASS.FlywheelMass = 0.2
		CLASS.RPM = {
			Idle	= 900,
			Limit	= 6250,
		}
		CLASS.Preview = {
			FOV = 100,
		}
	end)

	Classes.DefineClass("ACF.Engines.8.0-V10", "ACF.Engines.V10", function()
		CLASS.Name		 = "8.0L V10 Petrol"
		CLASS.Description	 = "#acf.descs.engines.v10.8_0"
		CLASS.Model		 = "models/engines/v10med.mdl"
		CLASS.Sound		 = "acf_base/engines/v10_petrolmedium.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 300
		CLASS.Torque		 = 612
		CLASS.FlywheelMass = 0.5
		CLASS.RPM = {
			Idle	= 750,
			Limit	= 6500,
		}
		CLASS.Preview = {
			FOV = 100,
		}
	end)

	Classes.DefineClass("ACF.Engines.22.0-V10", "ACF.Engines.V10", function()
		CLASS.Name		 = "22.0L V10 Multifuel"
		CLASS.Description	 = "#acf.descs.engines.v10.22_0"
		CLASS.Model		 = "models/engines/v10big.mdl"
		CLASS.Sound		 = "acf_base/engines/v10_diesellarge.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true, ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 1600
		CLASS.Torque		 = 3240
		CLASS.FlywheelMass = 5
		CLASS.RPM = {
			Idle	= 525,
			Limit	= 2200,
		}
		CLASS.Preview = {
			FOV = 100,
		}
	end)
end

ACF.SetCustomAttachment("models/engines/v10big.mdl", "driveshaft", Vector(-33, 0, 7.2), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/engines/v10med.mdl", "driveshaft", Vector(-21.95, 0, 4.79), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/engines/v10sml.mdl", "driveshaft", Vector(-17.56, 0, 3.83), Angle(0, 0, 90))

local Models = {
	{ Model = "models/engines/v10big.mdl", Scale = 1.85 },
	{ Model = "models/engines/v10med.mdl", Scale = 1.25 },
	{ Model = "models/engines/v10sml.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Main = {
			Pos       = Vector(-3.5, 0, 7.5) * Scale,
			Scale     = Vector(31, 11.5, 16.5) * Scale,
			Sensitive = true
		},
		LeftBank = {
			Pos   = Vector(-2.5, -6.5, 11) * Scale,
			Scale = Vector(28, 8, 11.25) * Scale,
			Angle = Angle(0, 0, 45)
		},
		RightBank = {
			Pos   = Vector(-2.5, 6.5, 11) * Scale,
			Scale = Vector(28, 8, 11.25) * Scale,
			Angle = Angle(0, 0, -45)
		}
	})
end
