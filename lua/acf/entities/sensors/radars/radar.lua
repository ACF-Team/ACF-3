local ACF             = ACF
local Classes         = ACF.Classes
local Countermeasures = ACF.Countermeasures

-- Missile and targeting radars are one group. What a radar detects is per entity, driven by the
-- DetectMissiles and DetectContraptions flags, rather than baked into a separate class tree.
Classes.DefineClass("ACF.Sensors.Radar.Standard", "ACF.Sensors.Radar", function(CLASS)
	CLASS.Name        = "Radar"
	CLASS.ID          = "Radar"
	CLASS.Entity      = "acf_radar"
	CLASS.SpawnModel  = "models/radar/radar_sml.mdl"
	CLASS.LimitConVar = {
		Name          = "_acf_radar",
		Amount        = 6,
		LegacyDefault = 4,
		Text          = "Maximum amount of ACF radars a player can create."
	}

	local Text            = "View Cone : %s degrees\nView Range : %s\nMin. Target Size (at max range) : %s\nMass : %s kg\nCost : %s\n"
	local SizeColor       = Color(255, 0, 0)
	local FormulaText     = "The minimum target size a radar can detect shrinks the closer a target gets. Smaller radars can only see small targets up close, while larger radars can see small targets much further out. A target smaller than the curve at its current distance won't be detected.\n\nMinimum detectable size = Min. Target Size x (Distance / View Range) ^ 2"
	local DetectTypesText = "Radars can be set to detect Contraptions, Missiles, or both. Radars that can only detect one target type receive a slight cost discount."

	-- Mirrors GetMinDetectableSize in helpers_sv.lua; a target smaller than this, at this distance, won't be seen.
	local MinSizeExponent = 2
	local function MinDetectableSize(MinSizeAtRange, Range, Dist)
		if not MinSizeAtRange or not Range or Range <= 0 then return 0 end

		return MinSizeAtRange * (Dist / Range) ^ MinSizeExponent
	end

	--- @param Menu userdata The collapsible the sensor page builds into
	--- @param Item table The selected radar class
	--- @param TopMenu userdata|nil The page menu, used for the graph so the collapsible isn't squashed
	function CLASS.CreateMenu(Menu, Item, TopMenu)
		local ViewCone  = (Item.ViewCone or 180) * 2
		local ViewRange = Item.Range and (math.Round(Item.Range * ACF.InchToMeter) .. " m") or "Unlimited"
		local MinSize   = Item.MinSizeAtRange and (Item.MinSizeAtRange .. " in") or "N/A"

		local Stats = Menu:AddLabel("")

		-- A radar detecting only one target type is discounted, so cost follows the checkboxes.
		local function UpdateStats()
			local Cost = Item.Cost or 0

			if ACF.GetClientBool("DetectContraptions", true) ~= ACF.GetClientBool("DetectMissiles", true) then
				Cost = Cost - ACF.RadarSingleTypeDiscount
			end

			Stats:SetText(Text:format(ViewCone, ViewRange, MinSize, Item.Mass, ACF.FormatCost(Cost)))
		end

		UpdateStats()

		-- Build on TopMenu, not the AddCollapsible content, to avoid squashing the graph.
		local ContentMenu = IsValid(TopMenu) and TopMenu or Menu

		if Item.Range and IsValid(TopMenu) then
			local RangeMeters   = Item.Range * ACF.InchToMeter
			local MaxSizeInches = Item.MinSizeAtRange or 0

			ContentMenu:AddHelp(FormulaText)

			local SizeGraph = ContentMenu:AddGraph()
			local Wide      = ContentMenu:GetWide()

			SizeGraph:SetSize(Wide, Wide / 2)
			SizeGraph:SetXLabel("Distance (m)")
			SizeGraph:SetYLabel("Min. target size (in)")
			SizeGraph:SetXRange(0, RangeMeters)
			SizeGraph:SetYRange(0, math.max(MaxSizeInches, 1))
			SizeGraph:SetXSpacing(math.max(math.Round(RangeMeters / 10, -1), 10))
			SizeGraph:SetYSpacing(math.max(math.Round(MaxSizeInches / 5, 1), 1))
			SizeGraph:SetFidelity(8)

			SizeGraph:PlotFunction("Min. size", SizeColor, function(X)
				local DistInches = (X / ACF.InchToMeter)

				return MinDetectableSize(Item.MinSizeAtRange, Item.Range, DistInches)
			end)
		end

		ContentMenu:AddHelp(DetectTypesText)

		-- A radar must detect at least one target type. Turning the last one off switches the other back on.
		local DetectContraptions = ContentMenu:AddCheckBox("Detect Contraptions")
		local DetectMissiles     = ContentMenu:AddCheckBox("Detect Missiles")

		function DetectContraptions:OnChange(Value)
			if not Value and not DetectMissiles:GetChecked() then
				DetectMissiles:SetValue(true)
			end

			ACF.SetClientData("DetectContraptions", Value)
			UpdateStats()
		end

		function DetectMissiles:OnChange(Value)
			if not Value and not DetectContraptions:GetChecked() then
				DetectContraptions:SetValue(true)
			end

			ACF.SetClientData("DetectMissiles", Value)
			UpdateStats()
		end

		-- Triggered once on menu creation and every time either checkbox is toggled.
		DetectContraptions:SetValue(ACF.GetClientBool("DetectContraptions", true))
		DetectMissiles:SetValue(ACF.GetClientBool("DetectMissiles", true))
	end
end)

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

	Classes.DefineClass("ACF.Sensors.Radar.Standard.SmallDirectional", "ACF.Sensors.Radar.Standard", function(CLASS)
		CLASS.Name           = "Small Directional Radar"
		CLASS.ID             = "SmallDIR"
		CLASS.Description    = "A lightweight directional radar with a shorter detection range and coarser target resolution."
		CLASS.Model          = "models/radar/radar_sml.mdl"
		CLASS.Mass           = 35
		CLASS.Cost           = 12.5
		CLASS.ViewCone       = 60
		CLASS.Range          = 23622 -- ~600m
		CLASS.MinSizeAtRange = 24
		CLASS.Origin         = "radar"
		CLASS.SwitchDelay    = 2
		CLASS.ThinkTicks     = 3
		CLASS.Preview        = { FOV = 105 }
		CLASS.Detect         = DetectEntities
	end)

	Classes.DefineClass("ACF.Sensors.Radar.Standard.MediumDirectional", "ACF.Sensors.Radar.Standard", function(CLASS)
		CLASS.Name           = "Medium Directional Radar"
		CLASS.ID             = "MediumDIR"
		CLASS.Description    = "A directional radar with a moderate detection range and target resolution."
		CLASS.Model          = "models/radar/radar_mid.mdl"
		CLASS.Mass           = 120
		CLASS.Cost           = 25
		CLASS.ViewCone       = 60
		CLASS.Range          = 31496 -- ~800m
		CLASS.MinSizeAtRange = 14
		CLASS.Origin         = "radar"
		CLASS.SwitchDelay    = 4
		CLASS.ThinkTicks     = 3
		CLASS.Preview        = { FOV = 110 }
		CLASS.Detect         = DetectEntities
	end)

	Classes.DefineClass("ACF.Sensors.Radar.Standard.LargeDirectional", "ACF.Sensors.Radar.Standard", function(CLASS)
		CLASS.Name           = "Large Directional Radar"
		CLASS.ID             = "LargeDIR"
		CLASS.Description    = "A heavy directional radar with a longer detection range and finer target resolution."
		CLASS.Model          = "models/radar/radar_big.mdl"
		CLASS.Mass           = 220
		CLASS.Cost           = 50
		CLASS.ViewCone       = 60
		CLASS.Range          = 39370 -- ~1000m
		CLASS.MinSizeAtRange = 7
		CLASS.Origin         = "radar"
		CLASS.SwitchDelay    = 8
		CLASS.ThinkTicks     = 3
		CLASS.Preview        = { FOV = 110 }
		CLASS.Detect         = DetectEntities
	end)

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

	Classes.DefineClass("ACF.Sensors.Radar.Standard.SmallSpherical", "ACF.Sensors.Radar.Standard", function(CLASS)
		CLASS.Name           = "Small Spherical Radar"
		CLASS.ID             = "SmallOMNI"
		CLASS.Description    = "A lightweight omni-directional radar with a shorter detection range and coarser target resolution."
		CLASS.Model          = "models/radar/radar_sp_sml.mdl"
		CLASS.Mass           = 80
		CLASS.Cost           = 20
		CLASS.Range          = 18898 -- ~480m
		CLASS.MinSizeAtRange = 24
		CLASS.Origin         = "radar"
		CLASS.SwitchDelay    = 3
		CLASS.ThinkTicks     = 10
		CLASS.Preview        = { FOV = 120 }
		CLASS.Detect         = DetectEntities
	end)

	Classes.DefineClass("ACF.Sensors.Radar.Standard.MediumSpherical", "ACF.Sensors.Radar.Standard", function(CLASS)
		CLASS.Name           = "Medium Spherical Radar"
		CLASS.ID             = "MediumOMNI"
		CLASS.Description    = "An omni-directional radar with a moderate detection range and target resolution."
		CLASS.Model          = "models/radar/radar_sp_mid.mdl"
		CLASS.Mass           = 210
		CLASS.Cost           = 40
		CLASS.Range          = 25197 -- ~640m
		CLASS.MinSizeAtRange = 14
		CLASS.Origin         = "radar"
		CLASS.SwitchDelay    = 6
		CLASS.ThinkTicks     = 10
		CLASS.Preview        = { FOV = 120 }
		CLASS.Detect         = DetectEntities
	end)

	Classes.DefineClass("ACF.Sensors.Radar.Standard.LargeSpherical", "ACF.Sensors.Radar.Standard", function(CLASS)
		CLASS.Name           = "Large Spherical Radar"
		CLASS.ID             = "LargeOMNI"
		CLASS.Description    = "A heavy omni-directional radar with a longer detection range and finer target resolution."
		CLASS.Model          = "models/radar/radar_sp_big.mdl"
		CLASS.Mass           = 540
		CLASS.Cost           = 80
		CLASS.Range          = 31496 -- ~800m
		CLASS.MinSizeAtRange = 7
		CLASS.Origin         = "radar"
		CLASS.SwitchDelay    = 12
		CLASS.ThinkTicks     = 10
		CLASS.Preview        = { FOV = 120 }
		CLASS.Detect         = DetectEntities
	end)

	ACF.SetCustomAttachment("models/radar/radar_sp_sml.mdl", "radar", Vector(0, 0, 23.5), Angle(0, 0, 0))
	ACF.SetCustomAttachment("models/radar/radar_sp_mid.mdl", "radar", Vector(0, 0, 37.5), Angle(0, 0, 0))
	ACF.SetCustomAttachment("models/radar/radar_sp_big.mdl", "radar", Vector(0, 0, 60), Angle(0, 0, 0))
end
