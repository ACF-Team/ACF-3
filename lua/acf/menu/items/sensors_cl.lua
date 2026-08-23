local ACF     = ACF
local Classes = ACF.Classes
local PAGE    = "acf_sensor"

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

local function Build(Menu, Contexts)
	local Groups = GetGroups()

	if not next(Groups) then
		Menu:AddTitle("#acf.menu.sensors.none_registered")
		Menu:AddLabel("#acf.menu.sensors.none_registered_desc")
		return
	end

	Menu:AddTitle("#acf.menu.sensors.settings")
	Menu:AddWikiLink("Radars", "docs/acf_missiles_tutorials/radars.html")
	Menu:AddWikiLink("Warning Receivers", "docs/acf_missiles_tutorials/warning_receivers.html")

	local SensorClass = Menu:AddComboBox()
	local SensorList  = Menu:AddComboBox()

	local Base          = Menu:AddCollapsible("#acf.menu.sensors.sensor_info", nil, "icon16/transmit_edit.png")
	local SensorName    = Base:AddTitle()
	local SensorDesc    = Base:AddLabel()
	local SensorPreview = Base:AddModelPreview(nil, true, "Primary")

	-- Which entity context a group spawns into.
	local function ContextFor(Group)
		return Group.Entity == "acf_receiver" and Contexts.Receiver or Contexts.Radar
	end

	function SensorClass:OnSelect(Index, _, Data)
		if self.Selected == Data then return end
		self.ListData.Index = Index
		self.Selected = Data
		ACF.Menu.SaveClassCombo(PAGE, "group", Data)

		Contexts.Active = ContextFor(Data)
		ACF.Menu.LoadClassCombo(SensorList, Classes.GetChildren(Data), "ID", "Model", PAGE, "item")
	end

	function SensorList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end
		self.ListData.Index = Index
		self.Selected = Data
		ACF.Menu.SaveClassCombo(PAGE, "item", Data)

		local Group = SensorClass.Selected
		local Ctx   = ContextFor(Group)
		Contexts.Active = Ctx

		-- Write the concrete sensor into the entity's nested "Sensor" field.
		Ctx:Set("Sensor", { Type = Classes.GetTypeName(Data), Data = {} })

		SensorName:SetText(Data.Name)
		SensorDesc:SetText(Data.Description or "#acf.menu.no_description_provided")
		SensorPreview:UpdateModel(Data.Model)
		SensorPreview:UpdateSettings(Data.Preview)

		Menu:ClearTemporal(Base)
		Menu:StartTemporal(Base)
		if Group.CreateMenu then Group.CreateMenu(Base, Data) end -- informational labels only
		Menu:EndTemporal(Base)
	end

	-- Restore the last-used group (which cascades to restore its item), else the first group.
	ACF.Menu.LoadClassCombo(SensorClass, Groups, "ID", "SpawnModel", PAGE, "group")
end

ACF.Menu.RegisterPage({
	ID       = "acf_sensor",
	Category = "#acf.menu.entities",
	Name     = "#acf.menu.sensors",
	Icon     = "transmit",
	Order    = 401,

	Contexts     = { Radar = "acf_radar", Receiver = "acf_receiver" },
	LinkContexts = function(Contexts) Contexts.Active = Contexts.Radar end, -- default committed context

	Actions = {
		{ Bind = "left",  Context = "Active", Preview = true, Desc = "Spawn a new sensor, or update the one you're aiming at." },
		{ Bind = "right", Commit = "link", Desc = "Select entities, then a sensor, to link them (hold R to unlink)." },
	},

	Build = Build,
})
