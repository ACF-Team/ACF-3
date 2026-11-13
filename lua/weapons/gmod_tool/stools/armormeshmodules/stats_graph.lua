-- Builds the hexagon skill graph inside the armor mesh tool's Material Info panel, overlaying the
-- toggled-on armor types' KE, CE, density, spall, health, and cost, normalized against the toggled-on set.
-- Axes are ordered/rotated so KE/CE sit at the top, density/health at the sides, and cost/spall at the bottom.

local Axes = {
	{ Key = "ChemicalMul", Label = "CE",      Tooltip = "Chemical effectiveness." },
	{ Key = "Density",     Label = "Density", Tooltip = "Mass per volume." },
	{ Key = "CostMul",     Label = "Cost",    Tooltip = "Points per cubic meter." },
	{ Key = "SpallMul",    Label = "Spall",   Tooltip = "Spall fragment mass." },
	{ Key = "HealthMul",   Label = "Health",  Tooltip = "Health per volume." },
	{ Key = "KineticMul",  Label = "KE",      Tooltip = "Kinetic effectiveness." },
}

local function GetAxisValue(Data, Key)
	return Data[Key] or 0
end

-- Every axis is anchored at 0, only the outer edge (Max) varies per axis.
local function GetAxisFraction(Data, Axis, Max)
	local Value = GetAxisValue(Data, Axis.Key)
	local Fraction = Max > 0 and (Value / Max) or 0

	if Axis.Reversed then
		Fraction = 1 - Fraction
	end

	return math.Clamp(Fraction, 0, 1)
end

-- Only ranges over the toggled-on materials, so the axes rescale to whatever is currently selected.
local function BuildAxisRanges(List, Visible)
	local Ranges = {}

	for _, Axis in ipairs(Axes) do
		Ranges[Axis.Key] = 0
	end

	for _, Data in ipairs(List) do
		if not Visible[Data] then continue end

		for _, Axis in ipairs(Axes) do
			local Value = GetAxisValue(Data, Axis.Key)

			Ranges[Axis.Key] = math.max(Ranges[Axis.Key], Value)
		end
	end

	return Ranges
end

local function GetSortedList(RawList)
	local List = {}

	for _, Data in ipairs(RawList) do
		if Data.SuppressLoad then continue end

		List[#List + 1] = Data
	end

	return List
end

-- Extreme/off-role types that used to carry ExcludeFromStatsGraph, kept out of the static axis limits below
local StaticRangeExcludedIDs = { Default = true, Flesh = true, Wing = true, ReinforcedConcrete = true, Wood = true }

-- Rebuilding the ranges on every selection change is implemented (see Row:DoClick below) but disabled for
-- now; the axes instead stay fixed against the same static material set the old ExcludeFromStatsGraph used.
local RebuildRangesOnSelect = false

return function(Base, RawList)
	local List    = GetSortedList(RawList)
	local Visible = {}

	local StaticVisible = {}
	for _, Data in ipairs(List) do
		StaticVisible[Data] = not StaticRangeExcludedIDs[Data.ID]
	end

	local Ranges = BuildAxisRanges(List, StaticVisible)

	for _, Data in ipairs(List) do
		Visible[Data] = false
	end

	local NormalizeKey

	local NormalizeBox = Base:AddPanel("DComboBox")
	NormalizeBox:Dock(TOP)
	NormalizeBox:DockMargin(0, 0, 0, 5)
	NormalizeBox:SetValue("Normalize on...")
	NormalizeBox:SetSortItems(false)
	NormalizeBox:AddChoice("---", "")

	for _, Axis in ipairs(Axes) do
		NormalizeBox:AddChoice(Axis.Label, Axis.Key)
	end

	local Graph = Base:AddPanel("DPanel")
	Graph:SetTall(220)

	function NormalizeBox:OnSelect(_, _, Key)
		NormalizeKey = Key ~= "" and Key or nil

		if not NormalizeKey then
			self:SetValue("Normalize on...")
		end
	end

	local AxisLabels = {}

	for _, Axis in ipairs(Axes) do
		local Label = vgui.Create("DLabel", Graph)
		Label:SetText(Axis.Label)
		Label:SetDark(true)
		Label:SetContentAlignment(5)
		Label:SizeToContents()
		Label:SetMouseInputEnabled(true)
		Label:SetTooltip(Axis.Tooltip)

		AxisLabels[Axis] = Label
	end

	local function GetPoint(W, H, Index, Fraction)
		local CenterX, CenterY = W * 0.5, H * 0.5
		local Radius = math.min(W, H) * 0.5 - 20
		local Angle = math.rad(-90 + 30 + (360 / #Axes) * (Index - 1))

		return CenterX + math.cos(Angle) * Radius * Fraction, CenterY + math.sin(Angle) * Radius * Fraction
	end

	function Graph:PerformLayout(W, H)
		for Index, Axis in ipairs(Axes) do
			local X, Y = GetPoint(W, H, Index, 1.15)
			local Label = AxisLabels[Axis]

			Label:SetPos(X - Label:GetWide() * 0.5, Y - Label:GetTall() * 0.5)
		end
	end

	Graph.Paint = function(_, W, H)
		local AxisCount = #Axes

		surface.SetDrawColor(200, 200, 200, 25)
		surface.DrawRect(0, 0, W, H)

		-- Grid rings
		surface.SetDrawColor(175, 175, 175, 255)
		for Ring = 1, 4 do
			local Fraction = Ring / 4
			local Points = {}

			for Index = 1, AxisCount do
				local X, Y = GetPoint(W, H, Index, Fraction)
				Points[Index] = { x = X, y = Y }
			end

			for Index = 1, AxisCount do
				local Next = Points[Index % AxisCount + 1]
				surface.DrawLine(Points[Index].x, Points[Index].y, Next.x, Next.y)
			end
		end

		-- Axis lines
		local CenterX, CenterY = W * 0.5, H * 0.5
		for Index in ipairs(Axes) do
			local X, Y = GetPoint(W, H, Index, 1)
			surface.DrawLine(CenterX, CenterY, X, Y)
		end

		-- One filled, translucent polygon per toggled-on armor type
		draw.NoTexture()

		local AllFractions = {}
		local LongestFraction = 0

		for _, Data in ipairs(List) do
			if not Visible[Data] then continue end

			local Fractions = {}
			local NormFraction

			for Index, Axis in ipairs(Axes) do
				local Fraction = GetAxisFraction(Data, Axis, Ranges[Axis.Key])
				Fractions[Index] = Fraction

				if Axis.Key == NormalizeKey then
					NormFraction = Fraction
				end
			end

			-- Scales every axis by the same factor so the chosen axis lands exactly on the outer ring.
			if NormFraction and NormFraction > 0 then
				local Scale = 1 / NormFraction

				for Index = 1, #Fractions do
					Fractions[Index] = Fractions[Index] * Scale
				end
			end

			for _, Fraction in ipairs(Fractions) do
				LongestFraction = math.max(LongestFraction, Fraction)
			end

			AllFractions[Data] = Fractions
		end

		-- Shrinks every material by the same amount so the single longest axis across all of them just reaches the ring.
		if LongestFraction > 1 then
			for _, Fractions in pairs(AllFractions) do
				for Index = 1, #Fractions do
					Fractions[Index] = Fractions[Index] / LongestFraction
				end
			end
		end

		for ListIndex, Data in ipairs(List) do
			if not Visible[Data] then continue end

			local Col = ACF.GetIndexColor(ListIndex - 1)
			local Poly = {}
			local Fractions = AllFractions[Data]

			for Index in ipairs(Axes) do
				local X, Y = GetPoint(W, H, Index, Fractions[Index])

				Poly[Index] = { x = X, y = Y }
			end

			-- surface.DrawPoly fans from the first vertex, which fills wrong on a concave notch.
			-- Every vertex lies on a ray from center, so fanning from center instead always fills correctly.
			surface.SetDrawColor(Col.r, Col.g, Col.b, 90)
			for Index = 1, #Poly do
				local Next = Poly[Index % #Poly + 1]
				surface.DrawPoly({ { x = CenterX, y = CenterY }, Poly[Index], Next })
			end

			surface.SetDrawColor(Col.r, Col.g, Col.b, 255)
			for Index = 1, #Poly do
				local Next = Poly[Index % #Poly + 1]
				surface.DrawLine(Poly[Index].x, Poly[Index].y, Next.x, Next.y)
			end
		end
	end

	-- Legend, one swatch and label per armor type, click to toggle its polygon on the graph
	local Legend = Base:AddPanel("DPanel")
	Legend:SetTall(#List * 18)
	Legend.Paint = function() end

	for ListIndex, Data in ipairs(List) do
		local Col = ACF.GetIndexColor(ListIndex - 1)

		local Row = vgui.Create("DButton", Legend)
		Row:Dock(TOP)
		Row:SetTall(18)
		Row:SetText("")

		local Swatch = vgui.Create("DPanel", Row)
		Swatch:Dock(LEFT)
		Swatch:SetWide(18)
		Swatch:DockMargin(0, 2, 5, 2)
		Swatch.Paint = function(_, W, H)
			surface.SetDrawColor(Col.r, Col.g, Col.b, Visible[Data] and 255 or 60)
			surface.DrawRect(0, 0, W, H)
		end

		local Label = vgui.Create("DLabel", Row)
		Label:Dock(FILL)
		Label:SetText(Data.ShortName or Data.Name)
		Label:SetDark(true)
		Label:SetMouseInputEnabled(false)
		Label:SetAlpha(Visible[Data] and 255 or 120)

		function Row:DoClick()
			Visible[Data] = not Visible[Data]
			Label:SetAlpha(Visible[Data] and 255 or 120)

			if RebuildRangesOnSelect then
				Ranges = BuildAxisRanges(List, Visible)
			end
		end
	end
end
