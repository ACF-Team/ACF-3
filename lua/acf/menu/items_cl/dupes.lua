-- Returns the information header and the remaining dupe string of an ad2 file without deserializing the dupe
local function getInfo(str)
	local last = str:find("\2")
	if not last then
		error("Attempt to read AD2 file with malformed info block!")
	end
	local info = {}
	local ss = str:sub(1, last - 1)
	for k, v in ss:gmatch("(.-)\1(.-)\1") do
		info[k] = v
	end

	if info.check ~= "\r\n\t\n" then
		if info.check == "\10\9\10" then
			error("Detected AD2 file corrupted in file transfer (newlines homogenized)(when using FTP, transfer AD2 files in image/binary mode, not ASCII/text mode)!")
		elseif info.check ~= nil then
			error("Detected AD2 file corrupted by newline replacements (copy/pasting the data in various editors can cause this!)")
		else
			error("Attempt to read AD2 file with malformed info block!")
		end
	end
	return info, str:sub(last + 2)
end

local function LoadDupe(name, path)
	local read = file.Read(path, "GAME")
	local success, dupe, info, moreinfo = AdvDupe2.Decode(read)

	if success then
		AdvDupe2.SendFile(name, read)
		AdvDupe2.LoadGhosts(dupe, info, moreinfo, name)
		AdvDupe2.Notify("Dupe Loaded: " .. name, NOTIFY_GENERIC)
	else
		AdvDupe2.Notify("File could not be decoded. (" .. dupe .. ") Upload Canceled.", NOTIFY_ERROR)
	end
end

local function CreateMenu(Menu)
	-- Using Wrapper methods for the sidebar entries
	Menu:AddTitle("#acf.menu.dupe.desc1")
	Menu:AddLabel("#acf.menu.dupe.desc2")

	local CurrentDupeName = nil
	local CurrentDupePath = nil

	local OpenDupeWindow = Menu:AddButton("Open Dupe Browser")

	function OpenDupeWindow:DoClick()
		local DupePath = "addons/ACF-3/data_static/public_dupes"

		-- SQL Initialization
		local Schema = file.Read(DupePath .. "/schema.sql", "GAME")
		if Schema then sql.Query(Schema) end

		local _, DupePacks = file.Find(DupePath .. "/*", "GAME")
		for _, DupePack in ipairs(DupePacks) do
			local PackData = file.Read(DupePath .. "/" .. DupePack .. "/pack.sql", "GAME")
			if PackData then sql.Query(PackData) print(DupePack) end
		end

		-- Main Window (Still a Frame, but we'll use ACF_Panel for the guts)
		local DupeFrame = vgui.Create("DFrame")
		DupeFrame:SetTitle("ACF Community Dupe Browser")
		DupeFrame:SetSize(1215, 840)
		DupeFrame:Center()
		DupeFrame:MakePopup()
		DupeFrame:SetSizable(true)

		-- Right Panel: Info (Using ACF_Panel wrapper)
		local InfoPanel = vgui.Create("ACF_Panel", DupeFrame)
		InfoPanel:Dock(RIGHT)
		InfoPanel:SetWide(200)

		-- File Info Section
		local FileInfoContent, _ = InfoPanel:AddCollapsible("Dupe Information (File)", true)
		local DupeLabels = {}
		for _, name in ipairs({"Name", "Owner", "Date", "Time", "Size"}) do
			DupeLabels[name] = FileInfoContent:AddLabel(name .. ": ")
		end

		local MetaInfoContent, _ = InfoPanel:AddCollapsible("Dupe Information (Meta)", true)
		local MetaLabels = {}
		for _, name in ipairs({"Author", "Type", "Weight", "Cost", "Description"}) do
			MetaLabels[name] = MetaInfoContent:AddLabel(name .. ": ")
		end

		-- Load Button
		local DupeLoadButton = InfoPanel:AddButton("Load Selected")
		DupeLoadButton:Dock(BOTTOM)

		-- Center Panel: Selection
		local SelectPanel = vgui.Create("DPanel", DupeFrame)
		SelectPanel:Dock(FILL)

		local DupeSheet = vgui.Create("DPropertySheet", SelectPanel)
		DupeSheet:Dock(FILL)

		local ListContainer = vgui.Create("DPanel")
		DupeSheet:AddSheet("All Dupes", ListContainer, "icon16/shape_square.png")

		local DupeList = vgui.Create("DPanelSelect", ListContainer)
		DupeList:Dock(FILL)

		function DupeList:OnActivePanelChanged(_, New)
			if not New or not New.Data then return end

			local FilePath = DupePath .. "/" .. New.Data.packid .. "/" .. New.Data.path .. ".txt"
			local readFile = file.Open(FilePath, "rb", "GAME")
			if not readFile then return end

			local readData = readFile:Read(readFile:Size())
			readFile:Close()

			local success, info = pcall(getInfo, readData:sub(7))

			if success then
				DupeLabels.Name:SetText("Name: " .. (New.Data.name or "Unknown"))
				DupeLabels.Owner:SetText("Owner: " .. (info.name or "Unknown"))
				DupeLabels.Date:SetText("Date: " .. (info.date or "Unknown"))
				DupeLabels.Time:SetText("Time: " .. (info.time or "Unknown"))
				DupeLabels.Size:SetText("Size: " .. string.NiceSize(tonumber(info.size or 0)))

				for name, label in pairs(MetaLabels) do
					label:SetText(name .. ": " .. (New.Data[string.lower(name)] or "Unknown"))
				end

				CurrentDupeName = New.Data.name
				CurrentDupePath = FilePath
			end
		end

		DupeLoadButton.DoClick = function()
			if CurrentDupePath then
				DupeFrame:Close()
				spawnmenu.ActivateTool("advdupe2")
				LoadDupe(CurrentDupeName, CurrentDupePath)
			end
		end

		-- Left Panel: Filters
		local FilterPanel = vgui.Create("ACF_Panel", DupeFrame)
		FilterPanel:Dock(LEFT)
		FilterPanel:SetWide(200)

		local FilterContent, _ = FilterPanel:AddCollapsible("Dupe Filters", true)

		local FilterAuthor = FilterContent:AddComboBox("Author")
		FilterAuthor:AddChoice("Any Author", nil)
		FilterAuthor:ChooseOptionID(1)
		local Authors = sql.Query("SELECT DISTINCT author FROM PackData")
		if Authors then
			for _, author in ipairs(Authors) do FilterAuthor:AddChoice(author.author, author.author) end
		end

		local FilterType = FilterContent:AddComboBox("Type")
		FilterType:AddChoice("Any Type", nil)
		FilterType:ChooseOptionID(1)
		local Types = sql.Query("SELECT DISTINCT type FROM DupeData")
		if Types then
			for _, type in ipairs(Types) do FilterType:AddChoice(type.type, type.type) end
		end

		local WeightData = sql.QueryRow("SELECT min(weight) AS Min, max(weight) AS Max FROM DupeData")
		local WMin, WMax = WeightData.Min, WeightData.Max
		local FilterWeightMin = FilterContent:AddSlider("Min Weight", WMin, WMax)
		local FilterWeightMax = FilterContent:AddSlider("Max Weight", WMin, WMax)
		FilterWeightMax:SetValue(WMax)

		local CostData = sql.QueryRow("SELECT min(cost) AS Min, max(cost) AS Max FROM DupeData")
		local CMin, CMax = CostData.Min, CostData.Max
		local FilterCostMin = FilterContent:AddSlider("Min Cost", CMin, CMax)
		local FilterCostMax = FilterContent:AddSlider("Max Cost", CMin, CMax)
		FilterCostMax:SetValue(CMax)

		local FilterMobility = FilterContent:AddComboBox("Mobility")
		FilterMobility:AddChoice("Any Mobility", nil)
		FilterMobility:ChooseOptionID(1)
		local MobilityOptions = sql.Query("SELECT DISTINCT mobility FROM DupeData")
		if MobilityOptions then
			for _, option in ipairs(MobilityOptions) do FilterMobility:AddChoice(option.mobility, option.mobility) end
		end

		local ApplyFilter = FilterPanel:AddButton("Apply Filters")
		ApplyFilter:Dock(BOTTOM)
		ApplyFilter.DoClick = function()
			local _, author = FilterAuthor:GetSelected()
			local _, type = FilterType:GetSelected()
			local _, mobility = FilterMobility:GetSelected()
			local wmin, wmax = FilterWeightMin:GetValue(), FilterWeightMax:GetValue()
			local cmin, cmax = FilterCostMin:GetValue(), FilterCostMax:GetValue()

			local query = "SELECT * FROM DupeData NATURAL JOIN PackData WHERE weight BETWEEN " .. wmin .. " AND " .. wmax .. " AND cost BETWEEN " .. cmin .. " AND " .. cmax
			if author then query = query .. " AND author = " .. sql.SQLStr(author) end
			if type then query = query .. " AND type = " .. sql.SQLStr(type) end
			if mobility then query = query .. " AND mobility = " .. sql.SQLStr(mobility) end

			local dupes = sql.Query(query) or {}
			DupeList:Clear()
			for _, dupe in ipairs(dupes) do
				local FilePath = DupePath .. "/" .. dupe.packid .. "/" .. dupe.path
				local Icon = vgui.Create("DImageButton")
				Icon:SetSize(256, 256)
				Icon:SetMaterial(Material(FilePath .. ".jpg"))
				Icon:SetTooltip(dupe.name)
				Icon.Data = dupe
				DupeList:AddPanel(Icon)
			end
		end

		ApplyFilter.DoClick() -- Load initial list with default filters
	end
end

ACF.AddMenuItem(3, "#acf.menu.dupe", "#acf.menu.dupe", "arrow_down", CreateMenu)