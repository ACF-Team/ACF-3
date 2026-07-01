local ACF             = ACF
local Classes         = ACF.Classes
local Countermeasures = ACF.Classes.Countermeasures

Classes.DefineClass("ACF.Sensors.Radar.Missile", "ACF.Sensors.Radar", function()
	CLASS.Name       = "Missile Radar"
	CLASS.ID         = "AM-Radar"
	CLASS.Entity     = "acf_radar"
	CLASS.SpawnModel = "models/missiles/agm_114.mdl"

	-- Detects missiles. Spherical items set Range, directional ones set ConeDegs.
	function CLASS.Detect(Radar)
		local Origin = Radar:LocalToWorld(Radar.Origin)

		if Radar.Range then
			return Countermeasures.GetMissilesInSphere(Origin, Radar.Range)
		end

		return Countermeasures.GetMissilesInCone(Origin, Radar:GetForward(), Radar.ConeDegs)
	end
end)

do -- Directional radars
	Classes.DefineClass("ACF.Sensors.Radar.Missile.SmallDirectional", "ACF.Sensors.Radar.Missile", function()
		CLASS.Name        = "Small Directional Missile Radar"
		CLASS.ID          = "SmallDIR-AM"
		CLASS.Description  = "A lightweight directional radar with a smaller view cone."
		CLASS.Model       = "models/radar/radar_sml.mdl"
		CLASS.Mass        = 35
		CLASS.ViewCone    = 10
		CLASS.Origin      = "radar"
		CLASS.SwitchDelay = 2
		CLASS.ThinkDelay  = 0.05
		CLASS.Preview     = { FOV = 105 }
	end)

	Classes.DefineClass("ACF.Sensors.Radar.Missile.MediumDirectional", "ACF.Sensors.Radar.Missile", function()
		CLASS.Name        = "Medium Directional Missile Radar"
		CLASS.ID          = "MediumDIR-AM"
		CLASS.Description  = "A directional radar with a regular view cone."
		CLASS.Model       = "models/radar/radar_mid.mdl"
		CLASS.Mass        = 120
		CLASS.ViewCone    = 25
		CLASS.Origin      = "radar"
		CLASS.SwitchDelay = 4
		CLASS.ThinkDelay  = 0.05
		CLASS.Preview     = { FOV = 110 }
	end)

	Classes.DefineClass("ACF.Sensors.Radar.Missile.LargeDirectional", "ACF.Sensors.Radar.Missile", function()
		CLASS.Name        = "Large Directional Missile Radar"
		CLASS.ID          = "LargeDIR-AM"
		CLASS.Description  = "A heavy directional radar with a large view cone."
		CLASS.Model       = "models/radar/radar_big.mdl"
		CLASS.Mass        = 220
		CLASS.ViewCone    = 60
		CLASS.Origin      = "radar"
		CLASS.SwitchDelay = 8
		CLASS.ThinkDelay  = 0.05
		CLASS.Preview     = { FOV = 110 }
	end)
end

do -- Spherical radars
	Classes.DefineClass("ACF.Sensors.Radar.Missile.SmallSpherical", "ACF.Sensors.Radar.Missile", function()
		CLASS.Name        = "Small Spherical Missile Radar"
		CLASS.ID          = "SmallOMNI-AM"
		CLASS.Description  = "A lightweight omni-directional radar with a smaller range."
		CLASS.Model       = "models/radar/radar_sp_sml.mdl"
		CLASS.Mass        = 80
		CLASS.Range       = 7874
		CLASS.Origin      = "radar"
		CLASS.SwitchDelay = 3
		CLASS.ThinkDelay  = 0.15
		CLASS.Preview     = { FOV = 120 }
	end)

	Classes.DefineClass("ACF.Sensors.Radar.Missile.MediumSpherical", "ACF.Sensors.Radar.Missile", function()
		CLASS.Name        = "Medium Spherical Missile Radar"
		CLASS.ID          = "MediumOMNI-AM"
		CLASS.Description  = "A omni-directional radar with a regular range."
		CLASS.Model       = "models/radar/radar_sp_mid.mdl"
		CLASS.Mass        = 210
		CLASS.Range       = 15748
		CLASS.Origin      = "radar"
		CLASS.SwitchDelay = 6
		CLASS.ThinkDelay  = 0.15
		CLASS.Preview     = { FOV = 120 }
	end)

	Classes.DefineClass("ACF.Sensors.Radar.Missile.LargeSpherical", "ACF.Sensors.Radar.Missile", function()
		CLASS.Name        = "Large Spherical Missile Radar"
		CLASS.ID          = "LargeOMNI-AM"
		CLASS.Description  = "A heavy omni-directional radar with a large range."
		CLASS.Model       = "models/radar/radar_sp_big.mdl"
		CLASS.Mass        = 540
		CLASS.Range       = 31496
		CLASS.Origin      = "radar"
		CLASS.SwitchDelay = 12
		CLASS.ThinkDelay  = 0.15
		CLASS.Preview     = { FOV = 120 }
	end)
end
