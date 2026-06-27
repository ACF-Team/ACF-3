local ACF     = ACF
local Classes = ACF.Classes

Classes.DefineClass("ACF.Engines.I2", "ACF.Engines.BaseEngine", function()
	CLASS.Name = "Inline 2 Engine"
end)

do
	Classes.DefineClass("ACF.Engines.0.8L-I2", "ACF.Engines.I2", function()
		CLASS.Name		 = "0.8L I2 Diesel"
		CLASS.Description	 = "#acf.descs.engines.i2.0_8"
		CLASS.Model		 = "models/engines/inline2s.mdl"
		CLASS.Sound		 = "acf_base/engines/i4_diesel2.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 45
		CLASS.Torque		 = 131
		CLASS.FlywheelMass = 0.12
		CLASS.RPM = {
			Idle	= 500,
			Limit	= 2950,
		}
		CLASS.Preview = {
			FOV = 125,
		}
	end)

	Classes.DefineClass("ACF.Engines.10.0-I2", "ACF.Engines.I2", function()
		CLASS.Name		 = "10.0L I2 Diesel"
		CLASS.Description	 = "#acf.descs.engines.i2.10_0"
		CLASS.Model		 = "models/engines/inline2b.mdl"
		CLASS.Sound		 = "acf_base/engines/vtwin_large.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 800
		CLASS.Torque		 = 2500
		CLASS.FlywheelMass = 7
		CLASS.RPM = {
			Idle	= 350,
			Limit	= 1200,
		}
		CLASS.Preview = {
			FOV = 125,
		}
	end)
end

ACF.SetCustomAttachment("models/engines/inline2b.mdl", "driveshaft", Vector(), Angle(0, 180, 90))
ACF.SetCustomAttachment("models/engines/inline2s.mdl", "driveshaft", Vector(-6, 0, 4), Angle(0, 180, 90))

local Models = {
	{ Model = "models/engines/inline2b.mdl", Scale = 2.5 },
	{ Model = "models/engines/inline2s.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Shaft = {
			Pos       = Vector(-1.25, 0, 4.75) * Scale,
			Scale     = Vector(15.5, 8, 9) * Scale,
			Sensitive = true
		},
		Pistons = {
			Pos   = Vector(-0.5, 0, 13.25) * Scale,
			Scale = Vector(10, 5, 8) * Scale
		}
	})
end
