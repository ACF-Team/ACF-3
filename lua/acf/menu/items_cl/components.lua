local ACF        = ACF
local Components = ACF.Classes.Components

local function CreateMenu(Menu)
	local Entries = Components.GetEntries()

	ACF.SetClientData("PrimaryClass", "N/A")
	ACF.SetClientData("SecondaryClass", "N/A")

	ACF.SetToolMode("acf_menu", "Spawner", "Component")

	if not next(Entries) then
		Menu:AddTitle("#acf.menu.components.none_registered")
		Menu:AddLabel("#acf.menu.components.none_registered_desc")
		return
	end

	Menu:AddTitle("#acf.menu.components.settings")

	local ComponentClass = Menu:AddComboBox()
	local ComponentList = Menu:AddComboBox()

	local Base = Menu:AddCollapsible("#acf.menu.components.component_info", nil, "icon16/drive_edit.png")
	local ComponentName = Base:AddTitle()
	local ComponentDesc = Base:AddLabel()
	local ComponentPreview = Base:AddModelPreview(nil, true)

	function ComponentClass:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		ACF.SetClientData("PrimaryClass", Data.Entity)
		ACF.SetClientData("ComponentClass", Data.ID)

		ACF.LoadSortedList(ComponentList, Data.Items, "ID")
	end

	function ComponentList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		local ClassData = ComponentClass.Selected

		ACF.SetClientData("Component", Data.ID)

		ComponentName:SetText(Data.Name)
		ComponentDesc:SetText(Data.Description or "#acf.menu.no_description_provided")

		ComponentPreview:UpdateModel(Data.Model)
		ComponentPreview:UpdateSettings(Data.Preview)

		Menu:ClearTemporal(Base)
		Menu:StartTemporal(Base)

		local CustomMenu = Data.CreateMenu or ClassData.CreateMenu

		if CustomMenu then
			CustomMenu(Data, Base)
		end

		Menu:EndTemporal(Base)
	end

	ACF.LoadSortedList(ComponentClass, Entries, "ID")
end

ACF.AddMenuItem(501, "#acf.menu.entities", "#acf.menu.components", "drive", CreateMenu)