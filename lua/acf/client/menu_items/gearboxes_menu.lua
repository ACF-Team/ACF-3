local Gearboxes = ACF.Classes.Gearboxes
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
	local GearboxClass = Menu:AddComboBox()
	local GearboxList = Menu:AddComboBox()
	local GearboxName = Menu:AddTitle()
	local GearboxDesc = Menu:AddLabel()

	ACF.WriteValue("PrimaryClass", "acf_gearbox")
	ACF.WriteValue("SecondaryClass", "N/A")

	function GearboxClass:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.Selected = Data

		local Choices = Sorted[Gearboxes]
		Selected[Choices] = Index

		ACF.WriteValue("GearboxClass", Data.ID)

		LoadSortedList(GearboxList, Data.Items, "ID")
	end

	function GearboxList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.Selected = Data

		local ClassData = EngineClass.Selected
		local Choices = Sorted[ClassData.Items]
		Selected[Choices] = Index

		ACF.WriteValue("Gearbox", Data.ID)

		GearboxName:SetText(Data.Name)
		GearboxDesc:SetText(Data.Description)

		Menu:ClearTemporal(self)
		Menu:StartTemporal(self)

		if Data.SetupMenu then
			Data.SetupMenu(Menu)
		end

		Menu:EndTemporal(self)
	end

	LoadSortedList(GearboxClass, Gearboxes, "ID")
end

ACF.AddOptionItem("Entities", "Gearboxes", "cog", CreateMenu)
