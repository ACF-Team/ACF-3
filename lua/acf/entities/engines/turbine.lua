local ACF     = ACF
local Classes = ACF.Classes

Classes.DefineClass("ACF.Engines.GT", "ACF.Engines.BaseEngine", function()
	CLASS.Name = "Gas Turbine"
	CLASS.Description	= "#acf.descs.engines.gt"
end)

do -- Forward-facing Gas Turbines
	Classes.DefineClass("ACF.Engines.Turbine-Small", "ACF.Engines.GT", function()
		CLASS.Name		 = "Small Gas Turbine"
		CLASS.Description	 = "#acf.descs.engines.gt.small"
		CLASS.Model		 = "models/engines/gasturbine_s.mdl"
		CLASS.Sound		 = "acf_base/engines/turbine_small.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true, ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.Turbine"
		CLASS.Mass		 = 200
		CLASS.Torque		 = 589
		CLASS.FlywheelMass = 2.9
		CLASS.IsElectric	 = true
		CLASS.RPM = {
			Idle	 = 1400,
			Limit	 = 14000,
			Override = 4167,
		}
		CLASS.Preview = {
			FOV = 100,
		}
	end)

	Classes.DefineClass("ACF.Engines.Turbine-Medium", "ACF.Engines.GT", function()
		CLASS.Name		 = "Medium Gas Turbine"
		CLASS.Description	 = "#acf.descs.engines.gt.medium"
		CLASS.Model		 = "models/engines/gasturbine_m.mdl"
		CLASS.Sound		 = "acf_base/engines/turbine_medium.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true, ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.Turbine"
		CLASS.Mass		 = 400
		CLASS.Torque		 = 1312
		CLASS.FlywheelMass = 4.3
		CLASS.IsElectric	 = true
		CLASS.RPM = {
			Idle	 = 1800,
			Limit	 = 12000,
			Override = 5000,
		}
		CLASS.Preview = {
			FOV = 100,
		}
	end)

	Classes.DefineClass("ACF.Engines.Turbine-Large", "ACF.Engines.GT", function()
		CLASS.Name		 = "Large Gas Turbine"
		CLASS.Description	 = "#acf.descs.engines.gt.large"
		CLASS.Model		 = "models/engines/gasturbine_l.mdl"
		CLASS.Sound		 = "acf_base/engines/turbine_large.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true, ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.Turbine"
		CLASS.Mass		 = 1100
		CLASS.Torque		 = 2500
		CLASS.FlywheelMass = 10.5
		CLASS.IsElectric	 = true
		CLASS.RPM = {
			Idle	 = 2000,
			Limit	 = 13000,
			Override = 5625,
		}
		CLASS.Preview = {
			FOV = 100,
		}
	end)
end

do -- Transaxial Gas Turbines
	Classes.DefineClass("ACF.Engines.Turbine-Small-Trans", "ACF.Engines.GT", function()
		CLASS.Name		 = "Small Transaxial Gas Turbine"
		CLASS.Description	 = "#acf.descs.engines.gt.small_trans"
		CLASS.Model		 = "models/engines/turbine_s.mdl"
		CLASS.Sound		 = "acf_base/engines/turbine_small.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true, ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.Turbine"
		CLASS.Mass		 = 160
		CLASS.Torque		 = 387
		CLASS.FlywheelMass = 2.3
		CLASS.IsElectric	 = true
		CLASS.IsTrans		 = true
		CLASS.RPM = {
			Idle	 = 1400,
			Limit	 = 12000,
			Override = 4167,
		}
		CLASS.Preview = {
			FOV = 75,
		}
	end)

	Classes.DefineClass("ACF.Engines.Turbine-Medium-Trans", "ACF.Engines.GT", function()
		CLASS.Name		 = "Medium Transaxial Gas Turbine"
		CLASS.Description	 = "#acf.descs.engines.gt.medium_trans"
		CLASS.Model		 = "models/engines/turbine_m.mdl"
		CLASS.Sound		 = "acf_base/engines/turbine_medium.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true, ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.Turbine"
		CLASS.Mass		 = 320
		CLASS.Torque		 = 750
		CLASS.FlywheelMass = 3.4
		CLASS.IsElectric	 = true
		CLASS.IsTrans		 = true
		CLASS.RPM = {
			Idle	 = 1800,
			Limit	 = 12000,
			Override = 5000,
		}
		CLASS.Preview = {
			FOV = 75,
		}
	end)

	Classes.DefineClass("ACF.Engines.Turbine-Large-Trans", "ACF.Engines.GT", function()
		CLASS.Name		 = "Large Transaxial Gas Turbine"
		CLASS.Description	 = "#acf.descs.engines.gt.large_trans"
		CLASS.Model		 = "models/engines/turbine_l.mdl"
		CLASS.Sound		 = "acf_base/engines/turbine_large.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true, ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.Turbine"
		CLASS.Mass		 = 880
		CLASS.Torque		 = 1710
		CLASS.FlywheelMass = 8.4
		CLASS.IsElectric	 = true
		CLASS.IsTrans		 = true
		CLASS.RPM = {
			Idle	 = 2000,
			Limit	 = 10000,
			Override = 5625,
		}
		CLASS.Preview = {
			FOV = 75,
		}
	end)
end

Classes.DefineClass("ACF.Engines.GGT", "ACF.Engines.BaseEngine", function()
	CLASS.Name = "Ground Gas Turbine"
	CLASS.Description	= "#acf.descs.engines.ggt"
end)

do -- Forward-facing Ground Gas Turbines
	Classes.DefineClass("ACF.Engines.Turbine-Ground-Small", "ACF.Engines.GGT", function()
		CLASS.Name		 = "Small Ground Gas Turbine"
		CLASS.Description	 = "#acf.descs.engines.ggt.small"
		CLASS.Model		 = "models/engines/gasturbine_s.mdl"
		CLASS.Sound		 = "acf_base/engines/turbine_small.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true, ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.Turbine"
		CLASS.Mass		 = 220
		CLASS.Torque		 = 1860
		CLASS.FlywheelMass = 35.5
		CLASS.IsElectric	 = true
		CLASS.RPM = {
			Idle	 = 450,
			Limit	 = 4000,
			Override = 1200,
		}
		CLASS.Preview = {
			FOV = 100,
		}
	end)

	Classes.DefineClass("ACF.Engines.Turbine-Ground-Medium", "ACF.Engines.GGT", function()
		CLASS.Name		 = "Medium Ground Gas Turbine"
		CLASS.Description	 = "#acf.descs.engines.ggt.medium"
		CLASS.Model		 = "models/engines/gasturbine_m.mdl"
		CLASS.Sound		 = "acf_base/engines/turbine_medium.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true, ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.Turbine"
		CLASS.Mass		 = 440
		CLASS.Torque		 = 3540
		CLASS.FlywheelMass = 38.7
		CLASS.IsElectric	 = true
		CLASS.Pitch		 = 1.15
		CLASS.RPM = {
			Idle	 = 600,
			Limit	 = 4000,
			Override = 1200,
		}
		CLASS.Preview = {
			FOV = 100,
		}
	end)

	Classes.DefineClass("ACF.Engines.Turbine-Ground-Large", "ACF.Engines.GGT", function()
		CLASS.Name		 = "Large Ground Gas Turbine"
		CLASS.Description	 = "#acf.descs.engines.ggt.large"
		CLASS.Model		 = "models/engines/gasturbine_l.mdl"
		CLASS.Sound		 = "acf_base/engines/turbine_large.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true, ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.Turbine"
		CLASS.Mass		 = 1300
		CLASS.Torque		 = 9000
		CLASS.FlywheelMass = 168
		CLASS.IsElectric	 = true
		CLASS.Pitch		 = 1.35
		CLASS.RPM = {
			Idle	 = 650,
			Limit	 = 3250,
			Override = 1000,
		}
		CLASS.Preview = {
			FOV = 100,
		}
	end)
end

do -- Transaxial Ground Gas Turbines
	Classes.DefineClass("ACF.Engines.Turbine-Small-Ground-Trans", "ACF.Engines.GGT", function()
		CLASS.Name		 = "Small Transaxial Ground Gas Turbine"
		CLASS.Description	 = "#acf.descs.engines.ggt.small_trans"
		CLASS.Model		 = "models/engines/turbine_s.mdl"
		CLASS.Sound		 = "acf_base/engines/turbine_small.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true, ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.Turbine"
		CLASS.Mass		 = 200
		CLASS.Torque		 = 1040
		CLASS.FlywheelMass = 20.7
		CLASS.IsElectric	 = true
		CLASS.IsTrans		 = true
		CLASS.RPM = {
			Idle	 = 450,
			Limit	 = 4000,
			Override = 1200,
		}
		CLASS.Preview = {
			FOV = 75,
		}
	end)

	Classes.DefineClass("ACF.Engines.Turbine-Medium-Ground-Trans", "ACF.Engines.GGT", function()
		CLASS.Name		 = "Medium Transaxial Ground Gas Turbine"
		CLASS.Description	 = "#acf.descs.engines.ggt.medium_trans"
		CLASS.Model		 = "models/engines/turbine_m.mdl"
		CLASS.Sound		 = "acf_base/engines/turbine_medium.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true, ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.Turbine"
		CLASS.Mass		 = 480
		CLASS.Torque		 = 1123
		CLASS.FlywheelMass = 23.7
		CLASS.IsElectric	 = true
		CLASS.IsTrans		 = true
		CLASS.Pitch		 = 1.15
		CLASS.RPM = {
			Idle	 = 600,
			Limit	 = 4000,
			Override = 1200,
		}
		CLASS.Preview = {
			FOV = 75,
		}
	end)

	Classes.DefineClass("ACF.Engines.Turbine-Large-Ground-Trans", "ACF.Engines.GGT", function()
		CLASS.Name		 = "Large Transaxial Ground Gas Turbine"
		CLASS.Description	 = "#acf.descs.engines.ggt.large_trans"
		CLASS.Model		 = "models/engines/turbine_l.mdl"
		CLASS.Sound		 = "acf_base/engines/turbine_large.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true, ["ACF.FuelTypes.Diesel"] = true }
		CLASS.Type		 = "ACF.EngineTypes.Turbine"
		CLASS.Mass		 = 1100
		CLASS.Torque		 = 4600
		CLASS.FlywheelMass = 75.6
		CLASS.IsElectric	 = true
		CLASS.IsTrans		 = true
		CLASS.Pitch		 = 1.35
		CLASS.RPM = {
			Idle	 = 650,
			Limit	 = 3250,
			Override = 1000,
		}
		CLASS.Preview = {
			FOV = 75,
		}
	end)
end

ACF.SetCustomAttachment("models/engines/turbine_l.mdl", "driveshaft", Vector(0, -15), Angle(0, -90))
ACF.SetCustomAttachment("models/engines/turbine_m.mdl", "driveshaft", Vector(0, -11.25), Angle(0, -90))
ACF.SetCustomAttachment("models/engines/turbine_s.mdl", "driveshaft", Vector(0, -7.5), Angle(0, -90))
ACF.SetCustomAttachment("models/engines/gasturbine_l.mdl", "driveshaft", Vector(-42), Angle(0, -180))
ACF.SetCustomAttachment("models/engines/gasturbine_m.mdl", "driveshaft", Vector(-31.5), Angle(0, -180))
ACF.SetCustomAttachment("models/engines/gasturbine_s.mdl", "driveshaft", Vector(-21), Angle(0, -180))

local Straight = {
	{ Model = "models/engines/turbine_l.mdl", Scale = 2 },
	{ Model = "models/engines/turbine_m.mdl", Scale = 1.5 },
	{ Model = "models/engines/turbine_s.mdl", Scale = 1 },
}

local Transaxial = {
	{ Model = "models/engines/gasturbine_l.mdl", Scale = 2 },
	{ Model = "models/engines/gasturbine_m.mdl", Scale = 1.5 },
	{ Model = "models/engines/gasturbine_s.mdl", Scale = 1 },
}

for _, Data in ipairs(Transaxial) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Main = {
			Pos       = Vector(2) * Scale,
			Scale     = Vector(26, 11, 11) * Scale,
			Sensitive = true
		},
		Intake = {
			Pos   = Vector(20) * Scale,
			Scale = Vector(10, 15, 15) * Scale
		},
		Output = {
			Pos   = Vector(-16, 0, 4) * Scale,
			Scale = Vector(10, 15, 24) * Scale
		}
	})
end

for _, Data in ipairs(Straight) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Main = {
			Pos   = Vector(6) * Scale,
			Scale = Vector(22, 10, 10) * Scale,
			Sensitive = true
		},
		Intake = {
			Pos   = Vector(19.5) * Scale,
			Scale = Vector(5, 12, 12) * Scale
		},
		Chamber = {
			Pos   = Vector(-9.5) * Scale,
			Scale = Vector(9, 13, 13) * Scale
		},
		Exhaust = {
			Pos   = Vector(-19) * Scale,
			Scale = Vector(10, 10, 10) * Scale
		}
	})
end