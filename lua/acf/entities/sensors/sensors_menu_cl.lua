local ACF  = ACF

do	-- Radars
	local Text = "View Cone : %s degrees\nView Range : %s\nMin. Target Size (at max range) : %s\nMass : %s kg\n"
	local SizeColor = Color(255, 0, 0)
	local FormulaText = "The minimum target size a radar can detect shrinks the closer a target gets. Smaller radars can only see small targets up close, while larger radars can see small targets much further out. A target smaller than the curve at its current distance won't be detected.\n\nMinimum detectable size = Min. Target Size x (Distance / View Range) ^ 2"
	local DetectTypesText = "Radars can be set to detect Contraptions, Missiles, or both. Radars that can only detect one target type receive a slight cost discount."

	-- Mirrors GetMinDetectableSize in lua/acf/entities/sensors/radars/helpers_sv.lua; a target smaller than this, at this distance, won't be seen by the radar.
	local MinSizeExponent = 2
	local function MinDetectableSize(MinSizeAtRange, Range, Dist)
		if not MinSizeAtRange or not Range or Range <= 0 then return 0 end

		return MinSizeAtRange * (Dist / Range) ^ MinSizeExponent
	end

	function ACF.CreateRadarMenu(Data, Menu, TopMenu)
		local ViewCone = (Data.ViewCone or 180) * 2
		local ViewRange = Data.Range and (math.Round(Data.Range * ACF.InchToMeter) .. " m") or "Unlimited"
		local MinSize = Data.MinSizeAtRange and (Data.MinSizeAtRange .. " in") or "N/A"

		Menu:AddLabel(Text:format(ViewCone, ViewRange, MinSize, Data.Mass))

		ACF.SetClientData("PrimaryClass", "acf_radar")

		-- Build on TopMenu, not Menu (AddCollapsible content), to avoid squashing the graph.
		local ContentMenu = IsValid(TopMenu) and TopMenu or Menu

		if Data.Range and IsValid(TopMenu) then
			local RangeMeters = Data.Range * ACF.InchToMeter
			local MaxSizeInches = Data.MinSizeAtRange or 0

			ContentMenu:AddHelp(FormulaText)

			local SizeGraph = ContentMenu:AddGraph()
			local Wide = ContentMenu:GetWide()

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

				return MinDetectableSize(Data.MinSizeAtRange, Data.Range, DistInches)
			end)
		end

		ContentMenu:AddHelp(DetectTypesText)

		-- A radar must be able to detect at least one target type. If the user tries to turn the last remaining type off, the other checkbox is switched back on instead of allowing nothing.
		local DetectContraptions = ContentMenu:AddCheckBox("Detect Contraptions")
		local DetectMissiles = ContentMenu:AddCheckBox("Detect Missiles")

		function DetectContraptions:OnChange(Value)
			if not Value and not DetectMissiles:GetChecked() then
				DetectMissiles:SetValue(true)
			end

			ACF.SetClientData("DetectContraptions", Value)
		end

		function DetectMissiles:OnChange(Value)
			if not Value and not DetectContraptions:GetChecked() then
				DetectContraptions:SetValue(true)
			end

			ACF.SetClientData("DetectMissiles", Value)
		end

		-- Triggered once on menu creation and every time either checkbox is toggled.
		DetectContraptions:SetValue(ACF.GetClientBool("DetectContraptions", true))
		DetectMissiles:SetValue(ACF.GetClientBool("DetectMissiles", true))
	end
end

do	-- Receivers
	local Text = "Mass : %s kg\n"

	function ACF.CreateReceiverMenu(Data, Menu)

		Menu:AddLabel(Text:format(Data.Mass))

		ACF.SetClientData("PrimaryClass", "acf_receiver")
	end
end