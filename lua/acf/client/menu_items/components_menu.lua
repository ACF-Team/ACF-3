local ACF = ACF
local Components = ACF.Classes.Components

local function CreateMenu(Menu)
	ACF.SetClientData("PrimaryClass", "N/A")
	ACF.SetClientData("SecondaryClass", "N/A")

	ACF.SetToolMode("acf_menu", "Spawner", "Component")

	if not next(Components) then
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
	local ComponentPreview = Base:AddModelPreview()

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

		local Preview = Data.Preview
		local ClassData = ComponentClass.Selected

		ACF.SetClientData("Component", Data.ID)

		ComponentName:SetText(Data.Name)
		ComponentDesc:SetText(Data.Description or "No description provided.")

		ComponentPreview:SetModel(Data.Model)
		ComponentPreview:SetCamPos(Preview and Preview.Offset or Vector(45, 60, 45))
		ComponentPreview:SetLookAt(Preview and Preview.Position or Vector())
		ComponentPreview:SetHeight(Preview and Preview.Height or 80)
		ComponentPreview:SetFOV(Preview and Preview.FOV or 75)

		Menu:ClearTemporal(Base)
		Menu:StartTemporal(Base)

		local CustomMenu = Data.CreateMenu or ClassData.CreateMenu

		if CustomMenu then
			CustomMenu(Data, Base)
		end

		Menu:EndTemporal(Base)
	end

	ACF.LoadSortedList(ComponentClass, Components, "ID")
end

ACF.AddMenuItem(501, "Entities", "Components", "drive", CreateMenu)
