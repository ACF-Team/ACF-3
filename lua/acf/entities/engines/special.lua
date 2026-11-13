local ACF     = ACF
local Classes = ACF.Classes

-- IsSpecial is a class field (set below); the engine entity reads it off the engine instance.
Classes.DefineClass("ACF.Engines.SP", "ACF.Engines.BaseEngine", function(CLASS)
	CLASS.Name = "Special Engine"
	CLASS.IsSpecial = true
end)

do -- Special Rotary Engines
	Classes.DefineClass("ACF.Engines.2.6L-Wankel", "ACF.Engines.SP", function(CLASS)
		CLASS.Name		 = "2.6L Rotary"
		CLASS.Description	 = "#acf.descs.engines.sp.2_6"
		CLASS.Model		 = "models/engines/wankel_4_med.mdl"
		CLASS.Sound		 = "acf_base/engines/wankel_large.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.Wankel"
		CLASS.Mass		 = 330
		CLASS.Displacement = 2.6
		CLASS.Torque	   = 279
		CLASS.FlywheelMass = 0.11
		CLASS.RPM = {
			Idle	= 1200,
			Limit	= 9500,
		}
		CLASS.Preview = {
			FOV = 100,
		}
	end)
end

do -- Special I2 Engines
	Classes.DefineClass("ACF.Engines.0.9L-I2", "ACF.Engines.SP", function(CLASS)
		CLASS.Name		 = "0.9L I2 Petrol"
		CLASS.Description	 = "#acf.descs.engines.sp.0_9"
		CLASS.Model		 = "models/engines/inline2s.mdl"
		CLASS.Sound		 = "acf_extra/vehiclefx/engines/ponyengine.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 95
		CLASS.Displacement = 0.9
		CLASS.Torque	  = 113
		CLASS.FlywheelMass = 0.085
		CLASS.RPM = {
			Idle	= 750,
			Limit	= 6000,
		}
		CLASS.Preview = {
			FOV = 125,
		}
	end)
end

do -- Special I4 Engines
	Classes.DefineClass("ACF.Engines.1.0L-I4", "ACF.Engines.SP", function(CLASS)
		CLASS.Name		 = "1.0L I4 Petrol"
		CLASS.Description	 = "#acf.descs.engines.sp.1_0"
		CLASS.Model		 = "models/engines/inline4s.mdl"
		CLASS.Sound		 = "acf_extra/vehiclefx/engines/l4/mini_onhigh.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 120
		CLASS.Displacement = 1.0
		CLASS.Torque	   = 68
		CLASS.FlywheelMass = 0.031
		CLASS.Pitch		 = 0.75
		CLASS.RPM = {
			Idle	= 1200,
			Limit	= 12000,
		}
		CLASS.Preview = {
			FOV = 120,
		}
	end)

	Classes.DefineClass("ACF.Engines.1.9L-I4", "ACF.Engines.SP", function(CLASS)
		CLASS.Name		 = "1.9L I4 Petrol"
		CLASS.Description	 = "#acf.descs.engines.sp.1_9"
		CLASS.Model		 = "models/engines/inline4s.mdl"
		CLASS.Sound		 = "acf_base/engines/i4_special.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 210
		CLASS.Displacement = 1.9
		CLASS.Torque	   = 187
		CLASS.FlywheelMass = 0.06
		CLASS.RPM = {
			Idle	= 950,
			Limit	= 9000,
		}
		CLASS.Preview = {
			FOV = 120,
		}
	end)
end

do -- Special V4 Engines
	Classes.DefineClass("ACF.Engines.1.8L-V4", "ACF.Engines.SP", function(CLASS)
		CLASS.Name		 = "1.8L V4 Petrol"
		CLASS.Description	 = "#acf.descs.engines.sp.1_8"
		CLASS.Model		 = "models/engines/v4s.mdl"
		CLASS.Sound		 = "acf_extra/vehiclefx/engines/l4/elan_onlow.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 135
		CLASS.Displacement = 1.8
		CLASS.Torque	   = 127
		CLASS.FlywheelMass = 0.04
		CLASS.RPM = {
			Idle	= 900,
			Limit	= 7500,
		}
		CLASS.Preview = {
			FOV = 110,
		}
	end)
end

do -- Special I6 Engines
	Classes.DefineClass("ACF.Engines.3.8-I6", "ACF.Engines.SP", function(CLASS)
		CLASS.Name		 = "3.8L I6 Petrol"
		CLASS.Description	 = "#acf.descs.engines.sp.3_8"
		CLASS.Model		 = "models/engines/inline6m.mdl"
		CLASS.Sound		 = "acf_base/engines/l6_special.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 240
		CLASS.Displacement = 3.8
		CLASS.Torque	   = 242
		CLASS.FlywheelMass = 0.1
		CLASS.RPM = {
			Idle	= 1100,
			Limit	= 9000,
		}
		CLASS.Preview = {
			FOV = 112,
		}
	end)
end

do -- Special V6 Engines
	Classes.DefineClass("ACF.Engines.2.4L-V6", "ACF.Engines.SP", function(CLASS)
		CLASS.Name		 = "2.4L V6 Petrol"
		CLASS.Description	 = "#acf.descs.engines.sp.2_4"
		CLASS.Model		 = "models/engines/v6small.mdl"
		CLASS.Sound		 = "acf_extra/vehiclefx/engines/l6/capri_onmid.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 190
		CLASS.Displacement = 2.4
		CLASS.Torque	   = 181
		CLASS.FlywheelMass = 0.075
		CLASS.RPM = {
			Idle	= 950,
			Limit	= 8000,
		}
		CLASS.Preview = {
			FOV = 105,
		}
	end)
end

do -- Special V8 Engines
	Classes.DefineClass("ACF.Engines.2.9-V8", "ACF.Engines.SP", function(CLASS)
		CLASS.Name		 = "2.9L V8 Petrol"
		CLASS.Description	 = "#acf.descs.engines.sp.2_9"
		CLASS.Model		 = "models/engines/v8s.mdl"
		CLASS.Sound		 = "acf_base/engines/v8_special.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 240
		CLASS.Displacement = 2.9
		CLASS.Torque	   = 216
		CLASS.FlywheelMass = 0.075
		CLASS.RPM = {
			Idle	= 1000,
			Limit	= 10000,
		}
		CLASS.Preview = {
			FOV = 100,
		}
	end)

	Classes.DefineClass("ACF.Engines.7.2-V8", "ACF.Engines.SP", function(CLASS)
		CLASS.Name		 = "7.2L V8 Petrol"
		CLASS.Description	 = "#acf.descs.engines.sp.7_2"
		CLASS.Model		 = "models/engines/v8m.mdl"
		CLASS.Sound		 = "acf_base/engines/v8_special2.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 475
		CLASS.Displacement = 7.2
		CLASS.Torque	   = 394
		CLASS.FlywheelMass = 0.15
		CLASS.RPM = {
			Idle	= 1000,
			Limit	= 8500,
		}
		CLASS.Preview = {
			FOV = 100,
		}
	end)
end

do -- Special V10 Engines
	Classes.DefineClass("ACF.Engines.5.3-V10", "ACF.Engines.SP", function(CLASS)
		CLASS.Name		 = "5.3L V10 Special"
		CLASS.Description	 = "#acf.descs.engines.sp.5_3"
		CLASS.Model		 = "models/engines/v10sml.mdl"
		CLASS.Sound		 = "acf_base/engines/v10_special.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 375
		CLASS.Displacement = 5.3
		CLASS.Torque	   = 362
		CLASS.FlywheelMass = 0.15
		CLASS.RPM = {
			Idle	= 1100,
			Limit	= 9000,
		}
		CLASS.Preview = {
			FOV = 100,
		}
	end)
end

do -- Special V12 Engines
	Classes.DefineClass("ACF.Engines.3.0-V12", "ACF.Engines.SP", function(CLASS)
		CLASS.Name		 = "3.0L V12 Petrol"
		CLASS.Description	 = "#acf.descs.engines.sp.3_0"
		CLASS.Model		 = "models/engines/v12s.mdl"
		CLASS.Sound		 = "acf_extra/vehiclefx/engines/v12/gtb4_onmid.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Petrol"] = true }
		CLASS.Type		 = "ACF.EngineTypes.GenericPetrol"
		CLASS.Mass		 = 235
		CLASS.Displacement = 3.0
		CLASS.Torque	   = 268
		CLASS.FlywheelMass = 0.1
		CLASS.Pitch		 = 0.85
		CLASS.RPM = {
			Idle	= 1100,
			Limit	= 8750,
		}
		CLASS.Preview = {
			FOV = 95,
		}
	end)
end
