local ACF             = ACF
local Sensors         = ACF.Classes.Sensors
local Countermeasures = ACF.Classes.Countermeasures

Sensors.Register("Radar", {
	Name		= "Radar",
	SpawnModel  = "models/radar/radar_sml.mdl",
	Entity		= "acf_radar",
	CreateMenu	= ACF.CreateRadarMenu,
	LimitConVar	= {
		Name = "_acf_radar",
		Amount = 6,
		LegacyDefault = 4,
		Text = "Maximum amount of ACF radars a player can create."
	},
})

do -- Directional radars
	local function DetectEntities(Radar)
		local Origin = Radar:LocalToWorld(Radar.Origin)
		local Forward = Radar:GetForward()
		local Cone = Radar.ConeDegs
		local Result = {}

		if Radar.DetectContraptions then
			for Ent in pairs(ACF.GetEntitiesInCone(Origin, Forward, Cone, Radar:CFW_GetContraption())) do
				Result[Ent] = true
			end
		end

		if Radar.DetectMissiles then
			for Missile in pairs(Countermeasures.GetMissilesInCone(Origin, Forward, Cone)) do
				Result[Missile] = true
			end
		end

		return Result
	end

	Sensors.RegisterItem("SmallDIR", "Radar", {
		Name		= "Small Directional Radar",
		Description	= "A lightweight directional radar with a shorter detection range and coarser target resolution.",
		Model		= "models/radar/radar_sml.mdl",
		Mass		= 35,
		ViewCone	= 60,
		Range		= 23622, -- ~600m
		MinSizeAtRange = 10,
		Origin		= "radar",
		SwitchDelay	= 2,
		ThinkTicks	= 3,
		Detect		= DetectEntities,
		Preview = {
			FOV = 105,
		},
	})

	Sensors.RegisterItem("MediumDIR", "Radar", {
		Name		= "Medium Directional Radar",
		Description	= "A directional radar with a moderate detection range and target resolution.",
		Model		= "models/radar/radar_mid.mdl",
		Mass		= 120,
		ViewCone	= 60,
		Range		= 31496, -- ~800m
		MinSizeAtRange = 5,
		Origin		= "radar",
		SwitchDelay	= 4,
		ThinkTicks	= 3,
		Detect		= DetectEntities,
		Preview = {
			FOV = 110,
		},
	})

	Sensors.RegisterItem("LargeDIR", "Radar", {
		Name		= "Large Directional Radar",
		Description	= "A heavy directional radar with a longer detection range and finer target resolution.",
		Model		= "models/radar/radar_big.mdl",
		Mass		= 220,
		ViewCone	= 60,
		Range		= 39370, -- ~1000m
		MinSizeAtRange = 2,
		Origin		= "radar",
		SwitchDelay	= 8,
		ThinkTicks	= 3,
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
		local Origin = Radar:LocalToWorld(Radar.Origin)
		local Range = Radar.Range
		local Result = {}

		if Radar.DetectContraptions then
			for Ent in pairs(ACF.GetEntitiesInSphere(Origin, Range, Radar:CFW_GetContraption())) do
				Result[Ent] = true
			end
		end

		if Radar.DetectMissiles then
			for Missile in pairs(Countermeasures.GetMissilesInSphere(Origin, Range)) do
				Result[Missile] = true
			end
		end

		return Result
	end

	Sensors.RegisterItem("SmallOMNI", "Radar", {
		Name		= "Small Spherical Radar",
		Description	= "A lightweight omni-directional radar with a shorter detection range and coarser target resolution.",
		Model		= "models/radar/radar_sp_sml.mdl",
		Mass		= 80,
		Range		= 18898, -- ~480m
		MinSizeAtRange = 10,
		Origin		= "radar",
		SwitchDelay	= 3,
		ThinkTicks	= 10,
		Detect		= DetectEntities,
		Preview = {
			FOV = 120,
		},
	})

	Sensors.RegisterItem("MediumOMNI", "Radar", {
		Name		= "Medium Spherical Radar",
		Description	= "An omni-directional radar with a moderate detection range and target resolution.",
		Model		= "models/radar/radar_sp_mid.mdl",
		Mass		= 210,
		Range		= 25197, -- ~640m
		MinSizeAtRange = 5,
		Origin		= "radar",
		SwitchDelay	= 6,
		ThinkTicks	= 10,
		Detect		= DetectEntities,
		Preview = {
			FOV = 120,
		},
	})

	Sensors.RegisterItem("LargeOMNI", "Radar", {
		Name		= "Large Spherical Radar",
		Description	= "A heavy omni-directional radar with a longer detection range and finer target resolution.",
		Model		= "models/radar/radar_sp_big.mdl",
		Mass		= 540,
		Range		= 31496, -- ~800m
		MinSizeAtRange = 2,
		Origin		= "radar",
		SwitchDelay	= 12,
		ThinkTicks	= 10,
		Detect		= DetectEntities,
		Preview = {
			FOV = 120,
		},
	})

	ACF.SetCustomAttachment("models/radar/radar_sp_sml.mdl", "radar", Vector(0, 0, 23.5), Angle(0, 0, 0))
	ACF.SetCustomAttachment("models/radar/radar_sp_mid.mdl", "radar", Vector(0, 0, 37.5), Angle(0, 0, 0))
	ACF.SetCustomAttachment("models/radar/radar_sp_big.mdl", "radar", Vector(0, 0, 60), Angle(0, 0, 0))
end
