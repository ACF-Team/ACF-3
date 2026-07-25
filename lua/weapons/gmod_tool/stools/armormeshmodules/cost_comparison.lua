-- Builds the "Cost Comparison" collapsible grid inside the armor mesh tool's Material Info panel,
-- listing every registered armor type with its cost per kinetic/chemical effectiveness, weight, and volume.
return function(CostBase, ArmorTypes)
	local Flipped    = false
	local FlipButton = CostBase:AddButton("Flip (value per $)")

	local CostList = CostBase:AddListView()
	CostList:AddColumn("Armor Type")
	local ColKE = CostList:AddColumn("$/KE")
	local ColCE = CostList:AddColumn("$/CE")
	local ColW  = CostList:AddColumn("$/W")
	local ColV  = CostList:AddColumn("$/V")

	local function PopulateCostList() -- Rebuilds the grid, since armor type definitions don't change at runtime but the flip toggle does.
		CostList:Clear()

		local Entries = {}
		for _, Data in pairs(ArmorTypes.GetEntries()) do
			if Data.SuppressLoad then continue end
			Entries[#Entries + 1] = Data
		end
		table.SortByMember(Entries, "Name", true)

		for _, Data in ipairs(Entries) do
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

			CostList:AddLine(Data.Name, string.format("%.3g", CostPerKE), string.format("%.3g", CostPerCE), string.format("%.3g", CostPerW), string.format("%.3g", CostPerV))
		end
	end

	function FlipButton:DoClick()
		Flipped = not Flipped

		ColKE:SetName(Flipped and "KE/$" or "$/KE")
		ColCE:SetName(Flipped and "CE/$" or "$/CE")
		ColW:SetName(Flipped and "W/$" or "$/W")
		ColV:SetName(Flipped and "V/$" or "$/V")

		PopulateCostList()
	end

	PopulateCostList()
end
