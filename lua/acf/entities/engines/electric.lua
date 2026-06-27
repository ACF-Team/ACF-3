local ACF     = ACF
local Classes = ACF.Classes

do -- Electric Motors
	Classes.DefineClass("ACF.Engines.EL", "ACF.Engines.BaseEngine", function()
		CLASS.Name		= "Electric Motor"
		CLASS.Description	= "#acf.descs.engines.el"
	end)

	Classes.DefineClass("ACF.Engines.Electric-Small", "ACF.Engines.EL", function()
		CLASS.Name		 = "Small Electric Motor"
		CLASS.Description	 = "#acf.descs.engines.el.small"
		CLASS.Model		 = "models/engines/emotorsmall.mdl"
		CLASS.Sound		 = "acf_base/engines/electric_small.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Electric"] = true }
		CLASS.Type		 = "ACF.EngineTypes.Electric"
		CLASS.Mass		 = 250
		CLASS.Torque		 = 480
		CLASS.FlywheelMass = 0.3
		CLASS.IsElectric	 = true
		CLASS.RPM = {
			Idle	 = 0,
			Limit	 = 10000,
			Override = 5000,
		}
		CLASS.Preview = {
			FOV = 86,
		}
	end)

	Classes.DefineClass("ACF.Engines.Electric-Medium", "ACF.Engines.EL", function()
		CLASS.Name		 = "Medium Electric Motor"
		CLASS.Description	 = "#acf.descs.engines.el.medium"
		CLASS.Model		 = "models/engines/emotormed.mdl"
		CLASS.Sound		 = "acf_base/engines/electric_medium.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Electric"] = true }
		CLASS.Type		 = "ACF.EngineTypes.Electric"
		CLASS.Mass		 = 850
		CLASS.Torque		 = 1440
		CLASS.FlywheelMass = 1.5
		CLASS.IsElectric	 = true
		CLASS.RPM = {
			Idle	 = 0,
			Limit	 = 7000,
			Override = 8000,
		}
		CLASS.Preview = {
			FOV = 88,
		}
	end)

	Classes.DefineClass("ACF.Engines.Electric-Large", "ACF.Engines.EL", function()
		CLASS.Name		 = "Large Electric Motor"
		CLASS.Description	 = "#acf.descs.engines.el.large"
		CLASS.Model		 = "models/engines/emotorlarge.mdl"
		CLASS.Sound		 = "acf_base/engines/electric_large.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Electric"] = true }
		CLASS.Type		 = "ACF.EngineTypes.Electric"
		CLASS.Mass		 = 1900
		CLASS.Torque		 = 4200
		CLASS.FlywheelMass = 11.2
		CLASS.IsElectric	 = true
		CLASS.RPM = {
			Idle	 = 0,
			Limit	 = 4500,
			Override = 6000,
		}
	end)
end

do -- Electric Standalone Motors
	Classes.DefineClass("ACF.Engines.EL-S", "ACF.Engines.BaseEngine", function()
		CLASS.Name		= "Electric Standalone Motor"
		CLASS.Description	= "#acf.descs.engines.el.standalone"
	end)

	Classes.DefineClass("ACF.Engines.Electric-Tiny-NoBatt", "ACF.Engines.EL-S", function()
		CLASS.Name		 = "Tiny Electric Standalone Motor"
		CLASS.Description	 = "#acf.descs.engines.el.standalone.tiny"
		CLASS.Model		 = "models/engines/emotor-standalone-tiny.mdl"
		CLASS.Sound		 = "acf_base/engines/electric_small.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Electric"] = true }
		CLASS.Type		 = "ACF.EngineTypes.Electric"
		CLASS.Mass		 = 50
		CLASS.Torque		 = 40
		CLASS.FlywheelMass = 0.025
		CLASS.IsElectric	 = true
		CLASS.RPM = {
			Idle	 = 0,
			Limit	 = 10000,
			Override = 500,
		}
		CLASS.Preview = {
			FOV = 120,
		}
	end)

	Classes.DefineClass("ACF.Engines.Electric-Small-NoBatt", "ACF.Engines.EL-S", function()
		CLASS.Name		 = "Small Electric Standalone Motor"
		CLASS.Description	 = "#acf.descs.engines.el.standalone.small"
		CLASS.Model		 = "models/engines/emotor-standalone-sml.mdl"
		CLASS.Sound		 = "acf_base/engines/electric_small.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Electric"] = true }
		CLASS.Type		 = "ACF.EngineTypes.Electric"
		CLASS.Mass		 = 125
		CLASS.Torque		 = 384
		CLASS.FlywheelMass = 0.3
		CLASS.IsElectric	 = true
		CLASS.RPM = {
			Idle	 = 0,
			Limit	 = 10000,
			Override = 5000,
		}
		CLASS.Preview = {
			FOV = 114,
		}
	end)

	Classes.DefineClass("ACF.Engines.Electric-Medium-NoBatt", "ACF.Engines.EL-S", function()
		CLASS.Name		 = "Medium Electric Standalone Motor"
		CLASS.Description	 = "#acf.descs.engines.el.standalone.medium"
		CLASS.Model		 = "models/engines/emotor-standalone-mid.mdl"
		CLASS.Sound		 = "acf_base/engines/electric_medium.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Electric"] = true }
		CLASS.Type		 = "ACF.EngineTypes.Electric"
		CLASS.Mass		 = 575
		CLASS.Torque		 = 1152
		CLASS.FlywheelMass = 1.5
		CLASS.IsElectric	 = true
		CLASS.RPM = {
			Idle	 = 0,
			Limit	 = 7000,
			Override = 8000,
		}
		CLASS.Preview = {
			FOV = 112,
		}
	end)

	Classes.DefineClass("ACF.Engines.Electric-Large-NoBatt", "ACF.Engines.EL-S", function()
		CLASS.Name		 = "Large Electric Standalone Motor"
		CLASS.Description	 = "#acf.descs.engines.el.standalone.large"
		CLASS.Model		 = "models/engines/emotor-standalone-big.mdl"
		CLASS.Sound		 = "acf_base/engines/electric_large.wav"
		CLASS.Fuel		 = { ["ACF.FuelTypes.Electric"] = true }
		CLASS.Type		 = "ACF.EngineTypes.Electric"
		CLASS.Mass		 = 1500
		CLASS.Torque		 = 3360
		CLASS.FlywheelMass = 11.2
		CLASS.IsElectric	 = true
		CLASS.RPM = {
			Idle	 = 0,
			Limit	 = 4500,
			Override = 6000,
		}
		CLASS.Preview = {
			FOV = 110,
		}
	end)
end

ACF.SetCustomAttachment("models/engines/emotorlarge.mdl", "driveshaft", Vector(), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/engines/emotormed.mdl", "driveshaft", Vector(), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/engines/emotorsmall.mdl", "driveshaft", Vector(), Angle(0, 0, 90))
ACF.SetCustomAttachment("models/engines/emotor-standalone-big.mdl", "driveshaft", Vector(), Angle(0, -90, 90))
ACF.SetCustomAttachment("models/engines/emotor-standalone-mid.mdl", "driveshaft", Vector(), Angle(0, -90, 90))
ACF.SetCustomAttachment("models/engines/emotor-standalone-sml.mdl", "driveshaft", Vector(), Angle(0, -90, 90))
ACF.SetCustomAttachment("models/engines/emotor-standalone-tiny.mdl", "driveshaft", Vector(), Angle(0, -90, 90))

local Fullsizes = {
	{ Model = "models/engines/emotorlarge.mdl", Scale = 1.92 },
	{ Model = "models/engines/emotormed.mdl", Scale = 1.37 },
	{ Model = "models/engines/emotorsmall.mdl", Scale = 1 },
}

local Standalones = {
	{ Model = "models/engines/emotor-standalone-big.mdl", Scale = 1.67 },
	{ Model = "models/engines/emotor-standalone-mid.mdl", Scale = 1.33 },
	{ Model = "models/engines/emotor-standalone-sml.mdl", Scale = 1 },
}

for _, Data in ipairs(Fullsizes) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Main = {
			Pos       = Vector(13, 0, 0.5) * Scale,
			Scale     = Vector(26, 14, 14) * Scale,
			Sensitive = true
		},
		CableBullshit = {
			Pos   = Vector(31, 0, 0.5) * Scale,
			Scale = Vector(10, 14, 14) * Scale
		},
		LeftPack = {
			Pos   = Vector(18.75, -13.5, 0.5) * Scale,
			Scale = Vector(37, 10, 14.5) * Scale
		},
		RightPack = {
			Pos   = Vector(18.75, 13.5, 0.5) * Scale,
			Scale = Vector(37, 10, 14.5) * Scale
		}
	})
end

for _, Data in ipairs(Standalones) do
	local Scale = Data.Scale

	ACF.AddHitboxes(Data.Model, {
		Main = {
			Pos       = Vector(9) * Scale,
			Scale     = Vector(20, 16, 16) * Scale,
			Sensitive = true
		}
	})
end

-- Special snowflake
ACF.AddHitboxes("models/engines/emotor-standalone-tiny.mdl", {
	Main = {
		Pos       = Vector(-0.5),
		Scale     = Vector(14, 10, 10),
		Sensitive = true
	}
})
