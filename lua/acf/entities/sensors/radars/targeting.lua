local ACF     = ACF
local Sensors = ACF.Classes.Sensors

Sensors.Register("TGT-Radar", {
	Name		= "Targeting Radar",
	SpawnModel  = "acf/icons/target.png",
	Entity		= "acf_radar",
	CreateMenu	= ACF.CreateRadarMenu,
	LimitConVar	= {
		Name = "_acf_radar",
		Amount = 4,
		Text = "Maximum amount of ACF radars a player can create."
	},
})

do -- Directional radars
	local function DetectEntities(Radar)
		return ACF.GetEntitiesInCone(Radar:LocalToWorld(Radar.Origin), Radar:GetForward(), Radar.ConeDegs, Radar:CFW_GetContraption())
	end

	Sensors.RegisterItem("SmallDIR-TGT", "TGT-Radar", {
		Name		= "Small Directional Radar",
		Description	= "A lightweight directional radar with a smaller view cone.",
		Model		= "models/radar/radar_sml.mdl",
		Mass		= 35,
		ViewCone	= 10,
		Origin		= "radar",
		SwitchDelay	= 2,
		ThinkDelay	= 0.1,
		Detect		= DetectEntities,
		Preview = {
			FOV = 105,
		},
	})

	Sensors.RegisterItem("MediumDIR-TGT", "TGT-Radar", {
		Name		= "Medium Directional Radar",
		Description	= "A directional radar with a regular view cone.",
		Model		= "models/radar/radar_mid.mdl",
		Mass		= 120,
		ViewCone	= 25,
		Origin		= "radar",
		SwitchDelay	= 4,
		ThinkDelay	= 0.1,
		Detect		= DetectEntities,
		Preview = {
			FOV = 110,
		},
	})

	Sensors.RegisterItem("LargeDIR-TGT", "TGT-Radar", {
		Name		= "Large Directional Radar",
		Description	= "A heavy directional radar with a large view cone.",
		Model		= "models/radar/radar_big.mdl",
		Mass		= 220,
		ViewCone	= 60,
		Origin		= "radar",
		SwitchDelay	= 8,
		ThinkDelay	= 0.1,
		Detect		= DetectEntities,
		Preview = {
			FOV = 110,
		},
	})

	ACF.SetCustomAttachment("models/radar/radar_sml.mdl", "radar", Vector(5.5, 0, 6.1), Angle(0, 0, 0))
	ACF.SetCustomAttachment("models/radar/radar_mid.mdl", "radar", Vector(13.1, 0, 11.4), Angle(0, 0, 0))
	ACF.SetCustomAttachment("models/radar/radar_big.mdl", "radar", Vector(17.5, 0, 15.1), Angle(0, 0, 0))
end

do -- Spherical radars
	local function DetectEntities(Radar)
		return ACF.GetEntitiesInSphere(Radar:LocalToWorld(Radar.Origin), Radar.Range, Radar:CFW_GetContraption())
	end

	Sensors.RegisterItem("SmallOMNI-TGT", "TGT-Radar", {
		Name		= "Small Spherical Radar",
		Description	= "A lightweight omni-directional radar with a smaller range.",
		Model		= "models/radar/radar_sp_sml.mdl",
		Mass		= 80,
		Range		= 7874,
		Origin		= "radar",
		SwitchDelay	= 3,
		ThinkDelay	= 0.3,
		Detect		= DetectEntities,
		Preview = {
			FOV = 120,
		},
	})

	Sensors.RegisterItem("MediumOMNI-TGT", "TGT-Radar", {
		Name		= "Medium Spherical Radar",
		Description	= "A omni-directional radar with a regular range.",
		Model		= "models/radar/radar_sp_mid.mdl",
		Mass		= 210,
		Range		= 15748,
		Origin		= "radar",
		SwitchDelay	= 6,
		ThinkDelay	= 0.3,
		Detect		= DetectEntities,
		Preview = {
			FOV = 120,
		},
	})

	Sensors.RegisterItem("LargeOMNI-TGT", "TGT-Radar", {
		Name		= "Large Spherical Radar",
		Description	= "A heavy omni-directional radar with a large range.",
		Model		= "models/radar/radar_sp_big.mdl",
		Mass		= 540,
		Range		= 31496,
		Origin		= "radar",
		SwitchDelay	= 12,
		ThinkDelay	= 0.3,
		Detect		= DetectEntities,
		Preview = {
			FOV = 120,
		},
	})

	ACF.SetCustomAttachment("models/radar/radar_sp_sml.mdl", "radar", Vector(0, 0, 23.5), Angle(0, 0, 0))
	ACF.SetCustomAttachment("models/radar/radar_sp_mid.mdl", "radar", Vector(0, 0, 37.5), Angle(0, 0, 0))
	ACF.SetCustomAttachment("models/radar/radar_sp_big.mdl", "radar", Vector(0, 0, 60), Angle(0, 0, 0))
end
