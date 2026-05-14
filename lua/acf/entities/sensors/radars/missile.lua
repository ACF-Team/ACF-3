local ACF             = ACF
local Sensors         = ACF.Classes.Sensors
local Countermeasures = ACF.Classes.Countermeasures

Sensors.Register("AM-Radar", {
	Name		= "Missile Radar",
	SpawnModel  = "models/missiles/agm_114.mdl",
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
		return Countermeasures.GetMissilesInCone(Radar:LocalToWorld(Radar.Origin), Radar:GetForward(), Radar.ConeDegs)
	end

	Sensors.RegisterItem("SmallDIR-AM", "AM-Radar", {
		Name		= "Small Directional Missile Radar",
		Description	= "A lightweight directional radar with a smaller view cone.",
		Model		= "models/radar/radar_sml.mdl",
		Mass		= 35,
		ViewCone	= 10,
		Origin		= "radar",
		SwitchDelay	= 2,
		ThinkDelay	= 0.05,
		Detect		= DetectEntities,
		Preview = {
			FOV = 105,
		},
	})

	Sensors.RegisterItem("MediumDIR-AM", "AM-Radar", {
		Name		= "Medium Directional Missile Radar",
		Description	= "A directional radar with a regular view cone.",
		Model		= "models/radar/radar_mid.mdl",
		Mass		= 120,
		ViewCone	= 25,
		Origin		= "radar",
		SwitchDelay	= 4,
		ThinkDelay	= 0.05,
		Detect		= DetectEntities,
		Preview = {
			FOV = 110,
		},
	})

	Sensors.RegisterItem("LargeDIR-AM", "AM-Radar", {
		Name		= "Large Directional Missile Radar",
		Description	= "A heavy directional radar with a large view cone.",
		Model		= "models/radar/radar_big.mdl",
		Mass		= 220,
		ViewCone	= 60,
		Origin		= "radar",
		SwitchDelay	= 8,
		ThinkDelay	= 0.05,
		Detect		= DetectEntities,
		Preview = {
			FOV = 110,
		},
	})
end

do -- Spherical radars
	local function DetectEntities(Radar)
		return Countermeasures.GetMissilesInSphere(Radar:LocalToWorld(Radar.Origin), Radar.Range)
	end

	Sensors.RegisterItem("SmallOMNI-AM", "AM-Radar", {
		Name		= "Small Spherical Missile Radar",
		Description	= "A lightweight omni-directional radar with a smaller range.",
		Model		= "models/radar/radar_sp_sml.mdl",
		Mass		= 80,
		Range		= 7874,
		Origin		= "radar",
		SwitchDelay	= 3,
		ThinkDelay	= 0.15,
		Detect		= DetectEntities,
		Preview = {
			FOV = 120,
		},
	})

	Sensors.RegisterItem("MediumOMNI-AM", "AM-Radar", {
		Name		= "Medium Spherical Missile Radar",
		Description	= "A omni-directional radar with a regular range.",
		Model		= "models/radar/radar_sp_mid.mdl",
		Mass		= 210,
		Range		= 15748,
		Origin		= "radar",
		SwitchDelay	= 6,
		ThinkDelay	= 0.15,
		Detect		= DetectEntities,
		Preview = {
			FOV = 120,
		},
	})

	Sensors.RegisterItem("LargeOMNI-AM", "AM-Radar", {
		Name		= "Large Spherical Missile Radar",
		Description	= "A heavy omni-directional radar with a large range.",
		Model		= "models/radar/radar_sp_big.mdl",
		Mass		= 540,
		Range		= 31496,
		Origin		= "radar",
		SwitchDelay	= 12,
		ThinkDelay	= 0.15,
		Detect		= DetectEntities,
		Preview = {
			FOV = 120,
		},
	})
end
