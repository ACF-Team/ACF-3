local DefaultDescription = [[
!Some vehicles may not have everything listed below!

Look at baseplate or wheels with physgun and press R to unfreeze. Then press ALT + E anywhere on the vehicle to enter.

W/A/S/D/Space for movement and brakes
R to toggle turret lock
Mouse3 for ballistic computer lase

Mouse1 for primary weapon
Mouse2 for secondary weapon
Left Alt for tertiary weapon
Shift for smokes

Number 1/2/3/... to select the next ammo type to load, double press to force a reload
]]

-- Returns the information header and the remaining dupe string of an ad2 file without deserializing the dupe
local function GetInfo(str)
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
		AdvDupe2.Notify("Dupe Loaded: " .. name, NOTIFY_GENERIC)

		-- Yes, this sucks, but there doesn't seem to be a way to detect when ActivateTool is correct otherwise,
		-- the other hooks are predicted which would introduce headache in singleplayer, etc. So this is the best solution I have for now...
		-- If you have a better way please god suggest it I hate this so much - March
		-- (and no PlayerSwitchWeapon is not enough, it says not to use it to detect weapon switching, and again its predicted)
		local Start = SysTime()
		hook.Add("Think", "ACF_WaitForToolGun", function()
			local Player = LocalPlayer()
			local InvalidConditions = (SysTime() - Start > 5) or not IsValid(Player)
			local Weapon = Player:GetActiveWeapon()
			local IsToolGun = IsValid(Weapon) and Weapon:GetClass() == "gmod_tool"
			local ValidConditions = IsToolGun and Weapon:GetMode() == "advdupe2"

			if InvalidConditions or ValidConditions then
				if ValidConditions then
					AdvDupe2.LoadGhosts(dupe, info, moreinfo, name)
				end
				hook.Remove("Think", "ACF_WaitForToolGun")
			end
		end)
		spawnmenu.ActivateTool("advdupe2")
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
		local DupePath = "data_static/acf_public_dupes"
		local ImagePath = "materials/acf_public_dupes"

		-- SQL Initialization
		sql.Query("DROP TABLE IF EXISTS DupeData")
		sql.Query("DROP TABLE IF EXISTS PackData")

		local Schema = file.Read(DupePath .. "/schema.txt", "GAME")
		if Schema then sql.Query(Schema) end

		local _, DupePacks = file.Find(DupePath .. "/*", "GAME")
		for _, DupePack in ipairs(DupePacks) do
			local PackData = file.Read(DupePath .. "/" .. DupePack .. "/pack.txt", "GAME")
			if PackData then sql.Query(PackData) end
		end

		local SW, SH = ScrW(), ScrH()
		-- Window: fixed proportion of the actual screen, works at any resolution
		local WinW = math.Round(SW * 0.633)
		local WinH = math.Round(SH * 0.778)
		-- UI element scale: min of both axes so nothing overflows on non-16:9
		local Scale = math.min(SW / 1920, SH / 1080)
		local FontScale = math.Clamp(Scale, 0.75, 1)
		local SideW = math.max(220, math.Round(WinW * 0.2))

		surface.CreateFont("ACF_Dupe_Title", { font = "Roboto", size = math.max(10, math.Round(18 * FontScale)), weight = 850, antialias = true })
		surface.CreateFont("ACF_Dupe_Label", { font = "Roboto", size = math.max(10, math.Round(14 * FontScale)), weight = 650, antialias = true })
		surface.CreateFont("ACF_Dupe_Control", { font = "Roboto", size = math.max(10, math.Round(14 * FontScale)), weight = 550, antialias = true })

		local ElemH = math.max(18, math.Round(22 * FontScale))
		local CollH = math.max(18, math.Round(24 * FontScale))
		local SliderH = math.max(36, math.Round(43 * FontScale))

		-- Main Window (Still a Frame, but we'll use ACF_Panel for the guts)
		local DupeFrame = vgui.Create("DFrame")
		DupeFrame:SetTitle("ACF Community Dupe Browser")
		DupeFrame:SetSize(WinW, WinH)
		DupeFrame:Center()
		DupeFrame:MakePopup()
		DupeFrame:SetSizable(true)

		-- Right Panel: Info (Using ACF_Panel wrapper)
		local InfoPanel = vgui.Create("ACF_Panel", DupeFrame)
		InfoPanel:Dock(RIGHT)
		InfoPanel:SetWide(SideW)

		-- File Info Section
		local FileInfoContent, FileInfoCat = InfoPanel:AddCollapsible("Dupe Information (File)", true)
		FileInfoCat.Header:SetFont("ACF_Dupe_Title")
		FileInfoCat.Header:SetTall(CollH)
		local DupeLabels = {}
		for _, name in ipairs({"Name", "Date", "Time", "Size"}) do
			DupeLabels[name] = FileInfoContent:AddLabel(name .. ": ")
			DupeLabels[name]:SetFont("ACF_Dupe_Label")
		end

		local MetaInfoContent, MetaInfoCat = InfoPanel:AddCollapsible("Dupe Information (Meta)", true)
		MetaInfoCat.Header:SetFont("ACF_Dupe_Title")
		MetaInfoCat.Header:SetTall(CollH)
		local MetaLabels = {}
		for _, name in ipairs({"Author", "Type", "Weight", "Cost", "Description"}) do
			MetaLabels[name] = MetaInfoContent:AddLabel(name .. ": ")
			MetaLabels[name]:SetFont("ACF_Dupe_Label")
		end

		-- Load Button
		local DupeLoadButton = InfoPanel:AddButton("Load Selected")
		DupeLoadButton:SetFont("ACF_Dupe_Control")
		DupeLoadButton:SetTall(ElemH)
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

			local success, info = pcall(GetInfo, readData:sub(7))

			if success then
				DupeLabels.Name:SetText("Name: " .. (New.Data.name or "Unknown"))
				DupeLabels.Date:SetText("Date: " .. (info.date or "Unknown"))
				DupeLabels.Time:SetText("Time: " .. (info.time or "Unknown"))
				DupeLabels.Size:SetText("Size: " .. string.NiceSize(tonumber(info.size or 0)))

				for name, label in pairs(MetaLabels) do
					label:SetText(name .. ": " .. (New.Data[string.lower(name)] or "Unknown"))
				end

				local Description = New.Data.description ~= "" and New.Data.description or DefaultDescription
				MetaLabels.Description:SetText("Description: " .. Description)

				CurrentDupeName = New.Data.name
				CurrentDupePath = FilePath
			end
		end

		DupeLoadButton.DoClick = function()
			if CurrentDupePath then
				DupeFrame:Close()
				LoadDupe(CurrentDupeName, CurrentDupePath)
			end
		end

		-- Left Panel: Filters
		local FilterPanel = vgui.Create("ACF_Panel", DupeFrame)
		FilterPanel:Dock(LEFT)
		FilterPanel:SetWide(SideW)

		local FilterContent, FilterCat = FilterPanel:AddCollapsible("Dupe Filters", true)
		FilterCat.Header:SetFont("ACF_Dupe_Title")
		FilterCat.Header:SetTall(CollH)

		local FilterAuthor = FilterContent:AddComboBox("Author")
		FilterAuthor:SetFont("ACF_Dupe_Control")
		FilterAuthor:SetTall(ElemH)
		FilterAuthor:AddChoice("Any Author", nil)
		FilterAuthor:ChooseOptionID(1)
		local Authors = sql.Query("SELECT DISTINCT author FROM PackData")
		if Authors then
			for _, author in ipairs(Authors) do FilterAuthor:AddChoice(author.author, author.author) end
		end

		local FilterType = FilterContent:AddComboBox("Type")
		FilterType:SetFont("ACF_Dupe_Control")
		FilterType:SetTall(ElemH)
		FilterType:AddChoice("Any Type", nil)
		FilterType:ChooseOptionID(1)
		local Types = sql.Query("SELECT DISTINCT type FROM DupeData")
		if Types then
			for _, type in ipairs(Types) do FilterType:AddChoice(type.type, type.type) end
		end

		local WeightData = sql.QueryRow("SELECT min(weight) AS Min, max(weight) AS Max FROM DupeData")
		local WMin, WMax = WeightData.Min, WeightData.Max
		local FilterWeightMin = FilterContent:AddSlider("Min Weight", WMin, WMax)
		FilterWeightMin.Label:SetFont("ACF_Dupe_Control")
		FilterWeightMin:SetTall(SliderH)
		local FilterWeightMax = FilterContent:AddSlider("Max Weight", WMin, WMax)
		FilterWeightMax.Label:SetFont("ACF_Dupe_Control")
		FilterWeightMax:SetTall(SliderH)
		FilterWeightMax:SetValue(WMax)

		local CostData = sql.QueryRow("SELECT min(cost) AS Min, max(cost) AS Max FROM DupeData")
		local CMin, CMax = CostData.Min, CostData.Max
		local FilterCostMin = FilterContent:AddSlider("Min Cost", CMin, CMax)
		FilterCostMin.Label:SetFont("ACF_Dupe_Control")
		FilterCostMin:SetTall(SliderH)
		local FilterCostMax = FilterContent:AddSlider("Max Cost", CMin, CMax)
		FilterCostMax.Label:SetFont("ACF_Dupe_Control")
		FilterCostMax:SetTall(SliderH)
		FilterCostMax:SetValue(CMax)

		local FilterMobility = FilterContent:AddComboBox("Mobility")
		FilterMobility:SetFont("ACF_Dupe_Control")
		FilterMobility:SetTall(ElemH)
		FilterMobility:AddChoice("Any Mobility", nil)
		FilterMobility:ChooseOptionID(1)
		local MobilityOptions = sql.Query("SELECT DISTINCT mobility FROM DupeData")
		if MobilityOptions then
			for _, option in ipairs(MobilityOptions) do FilterMobility:AddChoice(option.mobility, option.mobility) end
		end

		local ApplyFilter = FilterPanel:AddButton("Apply Filters")
		ApplyFilter:SetFont("ACF_Dupe_Control")
		ApplyFilter:SetTall(ElemH)
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
				local FilePath = ImagePath .. "/" .. dupe.packid .. "/" .. dupe.path
				local Icon = vgui.Create("DImageButton")
				Icon:SetSize(256 * Scale, 256 * Scale)
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