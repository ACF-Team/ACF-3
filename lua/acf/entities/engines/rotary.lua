local ACF     = ACF
local Classes = ACF.Classes
Classes.DefineClass("ACF.Engines.R", "ACF.Engines.BaseEngine", function()
	CLASS.Name = "Rotary Engine"
end)

do
	Classes.DefineClass("ACF.Engines.900cc-R", "ACF.Engines.R", function()
		CLASS.Name		 = "0.9L Rotary"
		CLASS.Description	 = "#acf.descs.engines.r.0_9"
		CLASS.Model		 = "models/engines/wankel_2_small.mdl"
		CLASS.Sound		 = "acf_base/engines/wankel_small.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.Wankel"
		CLASS.Mass		 = 50
		CLASS.Torque		 = 97
		CLASS.FlywheelMass = 0.06
		CLASS.RPM = {
			Idle	= 950,
			Limit	= 9200,
		}
		CLASS.Preview = {
			FOV = 105,
		}
	end)

	Classes.DefineClass("ACF.Engines.1.3L-R", "ACF.Engines.R", function()
		CLASS.Name		 = "1.3L Rotary"
		CLASS.Description	 = "#acf.descs.engines.r.1_3"
		CLASS.Model		 = "models/engines/wankel_2_med.mdl"
		CLASS.Sound		 = "acf_base/engines/wankel_medium.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.Wankel"
		CLASS.Mass		 = 140
		CLASS.Torque		 = 155
		CLASS.FlywheelMass = 0.06
		CLASS.RPM = {
			Idle	= 950,
			Limit	= 9000,
		}
		CLASS.Preview = {
			FOV = 105,
		}
	end)

	Classes.DefineClass("ACF.Engines.2.0L-R", "ACF.Engines.R", function()
		CLASS.Name		 = "2.0L Rotary"
		CLASS.Description	 = "#acf.descs.engines.r.2_0"
		CLASS.Model		 = "models/engines/wankel_3_med.mdl"
		CLASS.Sound		 = "acf_base/engines/wankel_large.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.Wankel"
		CLASS.Mass		 = 200
		CLASS.Torque		 = 235
		CLASS.FlywheelMass = 0.1
		CLASS.RPM = {
			Idle	= 950,
			Limit	= 9500,
		}
		CLASS.Preview = {
			FOV = 105,
		}
	end)
end

ACF.SetCustomAttachment("models/engines/wankel_4_med.mdl", "driveshaft", Vector(), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/engines/wankel_3_med.mdl", "driveshaft", Vector(), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/engines/wankel_2_med.mdl", "driveshaft", Vector(), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/engines/wankel_2_small.mdl", "driveshaft", Vector(), Angle(0, 0, 90))

ACF.AddHitboxes("models/engines/wankel_4_med.mdl", {
	Main = {
		Pos       = Vector(13),
		Scale     = Vector(26.5, 13, 17),
		Sensitive = true
	}
})

ACF.AddHitboxes("models/engines/wankel_3_med.mdl", {
	Main = {
		Pos       = Vector(10.25),
		Scale     = Vector(22, 13, 17),
		Sensitive = true
	}
})

ACF.AddHitboxes("models/engines/wankel_2_med.mdl", {
	Main = {
		Pos       = Vector(7.5),
		Scale     = Vector(16, 13, 17),
		Sensitive = true
	}
})

ACF.AddHitboxes("models/engines/wankel_2_small.mdl", {
	Main = {
		Pos       = Vector(6),
		Scale     = Vector(13, 10, 14),
		Sensitive = true
	}
})
