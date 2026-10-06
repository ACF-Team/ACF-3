-- Builds the "Armor Comparison" collapsible grid inside the armor mesh tool's Material Info panel,
-- letting the user pick any two stats and listing every registered armor type's ratio between them,
-- alongside the raw value of the remaining stats.

local Axes = {
	{ Key = "KineticMul",  Label = "KE", FullLabel = "Kinetic Multiplier",  Tooltip = "Kinetic effectiveness." },
	{ Key = "ChemicalMul", Label = "CE", FullLabel = "Chemical Multiplier", Tooltip = "Chemical effectiveness." },
	{ Key = "CostMul",     Label = "$",  FullLabel = "Cost Multiplier",        Tooltip = "Points per cubic meter." },
	{ Key = "HealthMul",   Label = "HP", FullLabel = "Health Multiplier",      Tooltip = "Health per volume." },
	{ Key = "Density",     Label = "Rh", FullLabel = "Density",                Tooltip = "Mass per volume." },
	{ Key = "SpallMul",    Label = "Sp", FullLabel = "Spall Multiplier",       Tooltip = "Spall fragment mass." },
}

return function(CostBase, ArmorTypes)
	local Numerator   = CostBase:AddComboBox()
	local Denominator = CostBase:AddComboBox()
	local FlipButton  = CostBase:AddButton("Flip")

	for _, Axis in ipairs(Axes) do
		Numerator:AddChoice(Axis.FullLabel, Axis, Axis == Axes[1])
		Denominator:AddChoice(Axis.FullLabel, Axis, Axis == Axes[2])
	end

	local CostList

	local function BuildRows(NumKey, DenKey, LeftoverAxes)
		local Rows = {}

		for _, Data in pairs(ArmorTypes.GetEntries()) do
			if Data.SuppressLoad then continue end

			local Num = Data[NumKey] or 0
			local Den = Data[DenKey] or 0

			local Row = {
				Name  = Data.ShortName or Data.Name,
				Ratio = Den ~= 0 and (Num / Den) or math.huge,
			}

			for _, Axis in ipairs(LeftoverAxes) do
				Row[Axis.Key] = Data[Axis.Key] or 0
			end

			Rows[#Rows + 1] = Row
		end

		table.SortByMember(Rows, "Name", true)

		return Rows
	end

	-- DListView has no way to add/remove columns after creation, so the panel is rebuilt whenever the
	-- selected axes change the set of leftover columns.
	local function RebuildCostList()
		local NumAxis = Numerator:GetOptionData(Numerator:GetSelectedID())
		local DenAxis = Denominator:GetOptionData(Denominator:GetSelectedID())
		if not NumAxis or not DenAxis then return end

		if CostList then CostList:Remove() end

		local LeftoverAxes = {}
		for _, Axis in ipairs(Axes) do
			if Axis ~= NumAxis and Axis ~= DenAxis then
				LeftoverAxes[#LeftoverAxes + 1] = Axis
			end
		end

		CostList = CostBase:AddListView()

		CostList:AddColumn("Name").Header:SetTooltip("The armor type's name.")
		CostList:AddColumn("Ratio").Header:SetTooltip(NumAxis.Label .. "/" .. DenAxis.Label .. ": " .. NumAxis.Tooltip .. " over " .. DenAxis.Tooltip)

		for _, Axis in ipairs(LeftoverAxes) do
			CostList:AddColumn(Axis.Label).Header:SetTooltip(Axis.Tooltip)
		end

		local Rows = BuildRows(NumAxis.Key, DenAxis.Key, LeftoverAxes)

		for _, Row in ipairs(Rows) do
			local Line = { Row.Name, Row.Ratio }

			for _, Axis in ipairs(LeftoverAxes) do
				Line[#Line + 1] = Row[Axis.Key]
			end

			CostList:AddLine(unpack(Line))
		end
	end

	function Numerator:OnSelect()
		RebuildCostList()
	end

	function Denominator:OnSelect()
		RebuildCostList()
	end

	function FlipButton:DoClick()
		local NumID, DenID = Numerator:GetSelectedID(), Denominator:GetSelectedID()

		Numerator:ChooseOptionID(DenID)
		Denominator:ChooseOptionID(NumID)
	end

	RebuildCostList()
end
