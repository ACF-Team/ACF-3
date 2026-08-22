-- Builds the "Cost Comparison" collapsible grid inside the armor mesh tool's Material Info panel,
-- listing every registered armor type with its cost per kinetic/chemical effectiveness, weight, and volume.

return function(CostBase, ArmorTypes)
	local Flipped    = false
	local FlipButton = CostBase:AddButton("Flip (value per $)")

	local CostList  = CostBase:AddListView()
	local ColName   = CostList:AddColumn("Armor Type")
	local ColKE     = CostList:AddColumn("$/KE")
	local ColCE     = CostList:AddColumn("$/CE")
	local ColW      = CostList:AddColumn("$/M")
	local ColV      = CostList:AddColumn("$/V")

	ColKE.Header:SetTooltip("Cost per point of kinetic effectiveness.")
	ColCE.Header:SetTooltip("Cost per point of chemical effectiveness.")
	ColW.Header:SetTooltip("Cost per kilogram.")
	ColV.Header:SetTooltip("Cost per cubic meter.")

	-- The list view's built-in sort compares the displayed strings lexically, which breaks numeric ordering,
	-- so sorting is handled manually here on the underlying values instead.
	local SortKey  = "Name"
	local SortDesc = false

	local function BuildRows()
		local Rows = {}

		for _, Data in pairs(ArmorTypes.GetEntries()) do
			if Data.SuppressLoad then continue end

			local CostPerKE = Data.KineticMul > 0 and (Data.CostMul / Data.KineticMul) or math.huge
			local CostPerCE = Data.ChemicalMul > 0 and (Data.CostMul / Data.ChemicalMul) or math.huge
			local CostPerW  = Data.Density > 0 and (Data.CostMul / Data.Density) or math.huge
			local CostPerV  = Data.CostMul

			if Flipped then
				CostPerKE = CostPerKE ~= 0 and (1 / CostPerKE) or math.huge
				CostPerCE = CostPerCE ~= 0 and (1 / CostPerCE) or math.huge
				CostPerW  = CostPerW  ~= 0 and (1 / CostPerW)  or math.huge
				CostPerV  = CostPerV  ~= 0 and (1 / CostPerV)  or math.huge
			end

			Rows[#Rows + 1] = {
				Name = Data.ShortName or Data.Name,
				KE   = CostPerKE,
				CE   = CostPerCE,
				W    = CostPerW,
				V    = CostPerV,
			}
		end

		return Rows
	end

	local function PopulateCostList() -- Rebuilds the grid, since armor type definitions don't change at runtime but the flip toggle/sort does.
		CostList:Clear()

		local Rows = BuildRows()
		table.SortByMember(Rows, SortKey, not SortDesc)

		for _, Row in ipairs(Rows) do
			CostList:AddLine(Row.Name, string.format("%.3g", Row.KE), string.format("%.3g", Row.CE), string.format("%.3g", Row.W), string.format("%.3g", Row.V))
		end
	end

	local function SortByColumn(Column, Key)
		function Column.Header:DoClick()
			if SortKey == Key then
				SortDesc = not SortDesc
			else
				SortKey  = Key
				SortDesc = false
			end

			PopulateCostList()
		end
	end

	SortByColumn(ColName, "Name")
	SortByColumn(ColKE, "KE")
	SortByColumn(ColCE, "CE")
	SortByColumn(ColW, "W")
	SortByColumn(ColV, "V")

	function FlipButton:DoClick()
		Flipped = not Flipped

		ColKE:SetName(Flipped and "KE/$" or "$/KE")
		ColCE:SetName(Flipped and "CE/$" or "$/CE")
		ColW:SetName(Flipped and "M/$" or "$/M")
		ColV:SetName(Flipped and "V/$" or "$/V")

		PopulateCostList()
	end

	PopulateCostList()
end
