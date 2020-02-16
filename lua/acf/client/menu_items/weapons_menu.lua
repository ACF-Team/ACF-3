local Weapons = ACF.Classes.Weapons
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
	local ClassList = Menu:AddComboBox()
	local EntList = Menu:AddComboBox()
	local Title = Menu:AddTitle()
	local ClassDesc = Menu:AddParagraph()

	local Test1 = Menu:AddSlider("Test1", 37, 140, 2)
	Test1:SetDataVariable("Test")

	local Test2 = Menu:AddSlider("Test2", 37, 140, 2)
	Test2:SetDataVariable("Test")

	ACF.WriteValue("Class", "acf_gun")

	function ClassList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.Selected = Data

		local Choices = Sorted[Weapons]
		Selected[Choices] = Index

		ClassDesc:SetText(Data.Description)

		LoadSortedList(EntList, Data.Items, "Caliber")
	end

	function EntList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.Selected = Data

		local Choices = Sorted[ClassList.Selected.Items]
		Selected[Choices] = Index

		Title:SetText(Data.Name)
	end

	LoadSortedList(ClassList, Weapons, "Name")
end

ACF.AddOptionItem("Entities", "Weapons", "gun", CreateMenu)
