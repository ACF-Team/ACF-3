local ACF     = ACF
local Classes = ACF.Classes

local function GetGroups(BaseName)
	local Base = Classes.GetTypeByName(BaseName)

	return Base and Classes.GetChildren(Base) or {}
end

local function CreateBuild(PAGE, BaseName, WikiName, WikiURL)
	return function(Menu, Contexts)
		local Ctx    = Contexts.Sensor
		local Groups = GetGroups(BaseName)

		if not next(Groups) then
			Menu:AddTitle("#acf.menu.sensors.none_registered")
			Menu:AddLabel("#acf.menu.sensors.none_registered_desc")
			return
		end

		Menu:AddTitle("#acf.menu.sensors.settings")

		if WikiURL then Menu:AddWikiLink(WikiName, WikiURL) end

		local SensorClass = Menu:AddComboBox()
		local SensorList  = Menu:AddComboBox()

		Menu:AddPresets(Ctx)

		local Base          = Menu:AddCollapsible("#acf.menu.sensors.sensor_info", nil, "icon16/transmit_edit.png")
		local SensorName    = Base:AddTitle()
		local SensorDesc    = Base:AddLabel()
		local SensorPreview = Base:AddModelPreview(nil, true, "Primary")

		-- Nothing to pick from a single choice
		SensorClass:SetVisible(table.Count(Groups) > 1)

		function SensorClass:OnSelect(Index, _, Data)
			if self.Selected == Data then return end
			self.ListData.Index = Index
			self.Selected = Data
			ACF.Menu.SaveClassCombo(PAGE, "group", Data)

			local Children = Classes.GetChildren(Data)

			SensorList:SetVisible(table.Count(Children) > 1)
			ACF.Menu.LoadClassCombo(SensorList, Children, "ID", "Model", PAGE, "item")
		end

		function SensorList:OnSelect(Index, _, Data)
			if self.Selected == Data then return end
			self.ListData.Index = Index
			self.Selected = Data
			ACF.Menu.SaveClassCombo(PAGE, "item", Data)

			local Group = SensorClass.Selected

			-- Write the concrete sensor into the entity's nested "Sensor" field.
			Ctx:Set("Sensor", { Type = Classes.GetTypeName(Data), Data = {} })

			SensorName:SetText(Data.Name)
			SensorDesc:SetText(Data.Description or "#acf.menu.no_description_provided")
			SensorPreview:UpdateModel(Data.Model)
			SensorPreview:UpdateSettings(Data.Preview)

			Menu:ClearTemporal(Base)
			Menu:StartTemporal(Base)
			if Group.CreateMenu then Group.CreateMenu(Data, Base, Ctx) end
			Menu:EndTemporal(Base)
		end

		-- Restore the last-used group (which cascades to restore its item), else the first group.
		ACF.Menu.LoadClassCombo(SensorClass, Groups, "ID", "SpawnModel", PAGE, "group")
	end
end

local function RegisterSensorPage(ClassName, BaseName, Name, Icon, Order, WikiName, WikiURL)
	ACF.Menu.RegisterPage({
		ID       = ClassName,
		Category = "#acf.menu.sensors",
		Name     = Name,
		Icon     = Icon,
		Order    = Order,

		Contexts = { Sensor = ClassName },

		Actions = {
			{ Bind = "left",  Context = "Sensor", Preview = true, Desc = "Spawn a new sensor, or update the one you're aiming at." },
			{ Bind = "right", Commit = "link", Desc = "Select entities, then a sensor, to link them (hold R to unlink)." },
		},

		Build = CreateBuild(ClassName, BaseName, WikiName, WikiURL),
	})
end

RegisterSensorPage("acf_radar", "ACF.Sensors.Radar", "#acf.menu.sensors.radar", "transmit_blue", 1, "Radars", "docs/acf_missiles_tutorials/radars.html")
RegisterSensorPage("acf_irst", "ACF.Sensors.IRST", "#acf.menu.sensors.irst", "eye", 2)
RegisterSensorPage("acf_receiver", "ACF.Sensors.Receiver", "#acf.menu.sensors.receivers", "transmit_go", 3, "Warning Receivers", "docs/acf_missiles_tutorials/warning_receivers.html")
