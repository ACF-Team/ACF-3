local ACF        = ACF
local Components = ACF.Classes.Components

local function CreateMenu(Menu)
	local Entries = Components.GetEntries()

	ACF.SetClientData("PrimaryClass", "N/A")
	ACF.SetClientData("SecondaryClass", "N/A")

	ACF.SetToolMode("acf_menu", "Spawner", "Component")

	if not next(Entries) then
		Menu:AddTitle("No Components Registered")
		Menu:AddLabel("No components have been registered. If this is incorrect, check your console for errors and contact the server owner.")
		return
	end

	Menu:AddTitle("Component Settings")

	local ComponentClass = Menu:AddComboBox()
	local ComponentList = Menu:AddComboBox()

	local Base = Menu:AddCollapsible("Component Information")
	local ComponentName = Base:AddTitle()
	local ComponentDesc = Base:AddLabel()
	local ComponentPreview = Base:AddModelPreview(nil, true)

	function ComponentClass:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

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
		ComponentDesc:SetText(Data.Description or "No description provided.")

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

ACF.AddMenuItem(501, "Entities", "Components", "drive", CreateMenu)
