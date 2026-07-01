local ACF     = ACF
local Classes = ACF.Classes
Classes.DefineClass("ACF.Engines.V4", "ACF.Engines.BaseEngine", function()
	CLASS.Name = "V4 Engine"
end)

do -- Diesel Engines
	Classes.DefineClass("ACF.Engines.1.9L-V4", "ACF.Engines.V4", function()
		CLASS.Name		 = "1.9L V4 Diesel"
		CLASS.Description	 = "#acf.descs.engines.v4.1_9"
		CLASS.Model		 = "models/engines/v4s.mdl"
		CLASS.Sound		 = "acf_base/engines/i4_diesel2.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 110
		CLASS.Torque		 = 206
		CLASS.FlywheelMass = 0.3
		CLASS.RPM = {
			Idle	= 650,
			Limit	= 4000,
		}
		CLASS.Preview = {
			FOV = 110,
		}
	end)

	Classes.DefineClass("ACF.Engines.3.3L-V4", "ACF.Engines.V4", function()
		CLASS.Name		 = "3.3L V4 Diesel"
		CLASS.Description	 = "#acf.descs.engines.v4.3_3"
		CLASS.Model		 = "models/engines/v4m.mdl"
		CLASS.Sound		 = "acf_base/engines/i4_dieselmedium.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericDiesel"
		CLASS.Mass		 = 275
		CLASS.Torque		 = 600
		CLASS.FlywheelMass = 1.05
		CLASS.RPM = {
			Idle	= 600,
			Limit	= 3900,
		}
		CLASS.Preview = {
			FOV = 110,
		}
	end)
end

ACF.SetCustomAttachment("models/engines/v4m.mdl", "driveshaft", Vector(-5.99, 0, 4.85), Angle(0, 90, 90))
ACF.SetCustomAttachment("models/engines/v4s.mdl", "driveshaft", Vector(-4.79, 0, 3.88), Angle(0, 90, 90))

local Models = {
	--{ Model = "models/engines/v4l.mdl", Scale = 1.5 }, -- Unused
	{ Model = "models/engines/v4m.mdl", Scale = 1.25 },
	{ Model = "models/engines/v4s.mdl", Scale = 1 },
}

for _, Data in ipairs(Models) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Main = {
			Pos       = Vector(3.25, 0, 7.75) * Scale,
			Scale     = Vector(18, 11.5, 16) * Scale,
			Sensitive = true
		},
		LeftBank = {
			Pos   = Vector(4.25, -6.75, 11.25) * Scale,
			Scale = Vector(15.75, 6.5, 10) * Scale,
			Angle = Angle(0, 0, 45)
		},
		RightBank = {
			Pos   = Vector(4.25, 6.75, 11.25) * Scale,
			Scale = Vector(15.75, 6.5, 10) * Scale,
			Angle = Angle(0, 0, -45)
		}
	})
end
