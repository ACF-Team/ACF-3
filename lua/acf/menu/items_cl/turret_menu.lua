local ACF		= ACF
local Turrets	= ACF.Classes.Turrets

local function CreateMenu(Menu)
	local Entries = Turrets.GetEntries()

	ACF.SetToolMode("acf_menu", "Spawner", "Turret")

	ACF.SetClientData("PrimaryClass", "N/A")
	ACF.SetClientData("SecondaryClass", "N/A")

	Menu:AddTitle("#acf.menu.turrets.menu_title")
	Menu:AddPonderAddonCategory("acf", "turrets")
	Menu:AddLabel("#acf.menu.turrets.menu_desc")

	local ClassList		= Menu:AddComboBox()
	local ClassDesc		= Menu:AddLabel()
	local ComponentClass	= Menu:AddComboBox()

	local Base			= Menu:AddCollapsible("#acf.menu.turrets.components", nil, "icon16/cd_edit.png")
	local ComponentName	= Base:AddTitle()
	local ComponentDesc	= Base:AddLabel()
	local ComponentPreview = Base:AddModelPreview(_, true)

	function ClassList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index	= Index
		self.Selected		= Data

		ClassDesc:SetText(Data.Description or "#acf.menu.no_description_provided")

		ACF.SetToolMode("acf_menu", "Spawner", Data.ID)
		ACF.LoadSortedList(ComponentClass, Data.Items, "Name", "Model")
	end

	function ComponentClass:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		local ClassData = ClassList.Selected

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

	ACF.LoadSortedList(ClassList, Entries, "ID", "SpawnModel")
end

ACF.AddMenuItem(51, "#acf.menu.entities", "#acf.menu.turrets", "shape_align_center", CreateMenu)