local ACF = ACF
local Sensors = ACF.Classes.Sensors

local function CreateMenu(Menu)
	local Entries = Sensors.GetEntries()

	ACF.SetClientData("PrimaryClass", "N/A")
	ACF.SetClientData("SecondaryClass", "N/A")

	ACF.SetToolMode("acf_menu", "Spawner", "Sensor")

	if not next(Entries) then
		Menu:AddTitle("#acf.menu.sensors.none_registered")
		Menu:AddLabel("#acf.menu.sensors.none_registered_desc")
		return
	end

	Menu:AddTitle("#acf.menu.sensors.settings")

	local SensorClass = Menu:AddComboBox()
	local SensorList = Menu:AddComboBox()

	local Base = Menu:AddCollapsible("#acf.menu.sensors.sensor_info", nil, "icon16/transmit_edit.png")
	local SensorName = Base:AddTitle()
	local SensorDesc = Base:AddLabel()
	local SensorPreview = Base:AddModelPreview(nil, true)

	function SensorClass:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		ACF.SetClientData("SensorClass", Data.ID)

		ACF.LoadSortedList(SensorList, Data.Items, "ID", "Model")
	end

	function SensorList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		local ClassData = SensorClass.Selected

		ACF.SetClientData("Sensor", Data.ID)

		SensorName:SetText(Data.Name)
		SensorDesc:SetText(Data.Description or "#acf.menu.no_description_provided")

		SensorPreview:UpdateModel(Data.Model)
		SensorPreview:UpdateSettings(Data.Preview)

		Menu:ClearTemporal(Base)
		Menu:StartTemporal(Base)

		local CustomMenu = Data.CreateMenu or ClassData.CreateMenu

		if CustomMenu then
			CustomMenu(Data, Base)
		end

		Menu:EndTemporal(Base)
	end

	ACF.LoadSortedList(SensorClass, Entries, "ID", "SpawnModel")
end

ACF.AddMenuItem(401, "#acf.menu.entities", "#acf.menu.sensors", "transmit", CreateMenu)