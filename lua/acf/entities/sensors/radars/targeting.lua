local ACF     = ACF
local Classes = ACF.Classes

Classes.DefineClass("ACF.Sensors.Radar.Targeting", "ACF.Sensors.Radar", function()
	CLASS.Name       = "Targeting Radar"
	CLASS.ID         = "TGT-Radar"
	CLASS.Entity     = "acf_radar"
	CLASS.SpawnModel = "acf/icons/target.png"

	-- Detects regular entities. Spherical items set Range, directional ones set ConeDegs.
	function CLASS.Detect(Radar)
		local Origin = Radar:LocalToWorld(Radar.Origin)

		if Radar.Range then
			return ACF.GetEntitiesInSphere(Origin, Radar.Range, Radar:CFW_GetContraption())
		end

		return ACF.GetEntitiesInCone(Origin, Radar:GetForward(), Radar.ConeDegs, Radar:CFW_GetContraption())
	end
end)

do -- Directional radars
	Classes.DefineClass("ACF.Sensors.Radar.Targeting.SmallDirectional", "ACF.Sensors.Radar.Targeting", function()
		CLASS.Name        = "Small Directional Radar"
		CLASS.ID          = "SmallDIR-TGT"
		CLASS.Description  = "A lightweight directional radar with a smaller view cone."
		CLASS.Model       = "models/radar/radar_sml.mdl"
		CLASS.Mass        = 35
		CLASS.ViewCone    = 10
		CLASS.Origin      = "radar"
		CLASS.SwitchDelay = 2
		CLASS.ThinkDelay  = 0.1
		CLASS.Preview     = { FOV = 105 }
	end)

	Classes.DefineClass("ACF.Sensors.Radar.Targeting.MediumDirectional", "ACF.Sensors.Radar.Targeting", function()
		CLASS.Name        = "Medium Directional Radar"
		CLASS.ID          = "MediumDIR-TGT"
		CLASS.Description  = "A directional radar with a regular view cone."
		CLASS.Model       = "models/radar/radar_mid.mdl"
		CLASS.Mass        = 120
		CLASS.ViewCone    = 25
		CLASS.Origin      = "radar"
		CLASS.SwitchDelay = 4
		CLASS.ThinkDelay  = 0.1
		CLASS.Preview     = { FOV = 110 }
	end)

	Classes.DefineClass("ACF.Sensors.Radar.Targeting.LargeDirectional", "ACF.Sensors.Radar.Targeting", function()
		CLASS.Name        = "Large Directional Radar"
		CLASS.ID          = "LargeDIR-TGT"
		CLASS.Description  = "A heavy directional radar with a large view cone."
		CLASS.Model       = "models/radar/radar_big.mdl"
		CLASS.Mass        = 220
		CLASS.ViewCone    = 60
		CLASS.Origin      = "radar"
		CLASS.SwitchDelay = 8
		CLASS.ThinkDelay  = 0.1
		CLASS.Preview     = { FOV = 110 }
	end)

	ACF.SetCustomAttachment("models/radar/radar_sml.mdl", "radar", Vector(5.5, 0, 6.1), Angle(0, 0, 0))
	ACF.SetCustomAttachment("models/radar/radar_mid.mdl", "radar", Vector(13.1, 0, 11.4), Angle(0, 0, 0))
	ACF.SetCustomAttachment("models/radar/radar_big.mdl", "radar", Vector(17.5, 0, 15.1), Angle(0, 0, 0))
end

do -- Spherical radars
	Classes.DefineClass("ACF.Sensors.Radar.Targeting.SmallSpherical", "ACF.Sensors.Radar.Targeting", function()
		CLASS.Name        = "Small Spherical Radar"
		CLASS.ID          = "SmallOMNI-TGT"
		CLASS.Description  = "A lightweight omni-directional radar with a smaller range."
		CLASS.Model       = "models/radar/radar_sp_sml.mdl"
		CLASS.Mass        = 80
		CLASS.Range       = 7874
		CLASS.Origin      = "radar"
		CLASS.SwitchDelay = 3
		CLASS.ThinkDelay  = 0.3
		CLASS.Preview     = { FOV = 120 }
	end)

	Classes.DefineClass("ACF.Sensors.Radar.Targeting.MediumSpherical", "ACF.Sensors.Radar.Targeting", function()
		CLASS.Name        = "Medium Spherical Radar"
		CLASS.ID          = "MediumOMNI-TGT"
		CLASS.Description  = "A omni-directional radar with a regular range."
		CLASS.Model       = "models/radar/radar_sp_mid.mdl"
		CLASS.Mass        = 210
		CLASS.Range       = 15748
		CLASS.Origin      = "radar"
		CLASS.SwitchDelay = 6
		CLASS.ThinkDelay  = 0.3
		CLASS.Preview     = { FOV = 120 }
	end)

	Classes.DefineClass("ACF.Sensors.Radar.Targeting.LargeSpherical", "ACF.Sensors.Radar.Targeting", function()
		CLASS.Name        = "Large Spherical Radar"
		CLASS.ID          = "LargeOMNI-TGT"
		CLASS.Description  = "A heavy omni-directional radar with a large range."
		CLASS.Model       = "models/radar/radar_sp_big.mdl"
		CLASS.Mass        = 540
		CLASS.Range       = 31496
		CLASS.Origin      = "radar"
		CLASS.SwitchDelay = 12
		CLASS.ThinkDelay  = 0.3
		CLASS.Preview     = { FOV = 120 }
	end)

	ACF.SetCustomAttachment("models/radar/radar_sp_sml.mdl", "radar", Vector(0, 0, 23.5), Angle(0, 0, 0))
	ACF.SetCustomAttachment("models/radar/radar_sp_mid.mdl", "radar", Vector(0, 0, 37.5), Angle(0, 0, 0))
	ACF.SetCustomAttachment("models/radar/radar_sp_big.mdl", "radar", Vector(0, 0, 60), Angle(0, 0, 0))
end
