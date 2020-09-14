local Components = ACF.Classes.Components
local Selected = {}
local Sorted = {}

local function LoadSortedList(Panel, List, Member)
	local Choices = Sorted[List]

	if not Choices then
		Choices = {}

		local Count = 0
		for _, V in pairs(List) do
			Count = Count + 1
			Choices[Count] = V
		end

		table.SortByMember(Choices, Member, true)

		Sorted[List] = Choices
		Selected[Choices] = 1
	end

	Panel:Clear()

	for _, V in pairs(Choices) do
		Panel:AddChoice(V.Name, V)
	end

	Panel:ChooseOptionID(Selected[Choices])
end

local function CreateMenu(Menu)
	ACF.WriteValue("PrimaryClass", "N/A")
	ACF.WriteValue("SecondaryClass", "N/A")

	ACF.SetToolMode("acf_menu2", "Main", "Spawner")

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

		self.Selected = Data

		local Choices = Sorted[Components]
		Selected[Choices] = Index

		ACF.WriteValue("ComponentClass", Data.ID)

		LoadSortedList(ComponentList, Data.Items, "ID")
	end

	function ComponentList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.Selected = Data

		local Preview = Data.Preview
		local ClassData = ComponentClass.Selected
		local Choices = Sorted[ClassData.Items]
		Selected[Choices] = Index

		ACF.WriteValue("Component", Data.ID)

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

	LoadSortedList(ComponentClass, Components, "ID")
end

ACF.AddMenuItem(501, "Entities", "Components", "drive", CreateMenu)
