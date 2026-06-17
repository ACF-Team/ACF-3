local ACF     = ACF
local Classes = ACF.Classes

local GroupBases = { "ACF.Sensors.Radar", "ACF.Sensors.Receiver" }

local function GetGroups()
	local Groups = {}

	for _, BaseName in ipairs(GroupBases) do
		local Base = Classes.GetTypeByName(BaseName)
		if not Base then continue end

		for _, Group in pairs(Classes.GetChildren(Base)) do
			Groups[#Groups + 1] = Group
		end
	end

	return Groups
end

local function CreateMenu(Menu)
	local Groups = GetGroups()

	ACF.SetClientData("PrimaryClass", "N/A")
	ACF.SetClientData("SecondaryClass", "N/A")

	ACF.SetToolMode("acf_menu", "Spawner", "Sensor")

	if not next(Groups) then
		Menu:AddTitle("#acf.menu.sensors.none_registered")
		Menu:AddLabel("#acf.menu.sensors.none_registered_desc")
		return
	end

	Menu:AddTitle("#acf.menu.sensors.settings")

	Menu:AddWikiLink("Radars", "docs/acf_missiles_tutorials/radars.html")
	Menu:AddWikiLink("Warning Receivers", "docs/acf_missiles_tutorials/warning_receivers.html")


	local SensorClass = Menu:AddComboBox()
	local SensorList = Menu:AddComboBox()

	local Base = Menu:AddCollapsible("#acf.menu.sensors.sensor_info", nil, "icon16/transmit_edit.png")
	local SensorName = Base:AddTitle()
	local SensorDesc = Base:AddLabel()
	local SensorPreview = Base:AddModelPreview(nil, true, "Primary")

	function SensorClass:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		ACF.LoadSortedList(SensorList, Classes.GetChildren(Data), "ID", "Model")
	end

	function SensorList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		local Group = SensorClass.Selected

		ACF.SetClientData("PrimaryClass", Group.Entity)
		ACF.SetClientData("Sensor", { Type = Classes.GetTypeName(Data), Data = {} })

		SensorName:SetText(Data.Name)
		SensorDesc:SetText(Data.Description or "#acf.menu.no_description_provided")

		SensorPreview:UpdateModel(Data.Model)
		SensorPreview:UpdateSettings(Data.Preview)

		Menu:ClearTemporal(Base)
		Menu:StartTemporal(Base)

		if Group.CreateMenu then
			Group.CreateMenu(Base, Data)
		end

		Menu:EndTemporal(Base)
	end

	ACF.LoadSortedList(SensorClass, Groups, "ID", "SpawnModel")
end

ACF.AddMenuItem(401, "#acf.menu.entities", "#acf.menu.sensors", "transmit", CreateMenu)
