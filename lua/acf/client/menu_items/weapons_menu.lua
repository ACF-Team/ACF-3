local AmmoTypes = ACF.Classes.AmmoTypes
local Weapons = ACF.Classes.Weapons
local Crates = ACF.Classes.Crates
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
	local EntText = "Mass:     %s kg\nFirerate: %s rpm\nSpread:  %s degrees%s"
	local MagText = "\nRounds: %s rounds\nReload:   %s seconds"

	local ClassList = Menu:AddComboBox()
	local EntList = Menu:AddComboBox()
	local EntName = Menu:AddSubtitle()
	local ClassDesc = Menu:AddParagraph()
	local EntData = Menu:AddParagraph()

	Menu:AddSubtitle("Ammo Settings")

	local CrateList = Menu:AddComboBox()
	local AmmoList = Menu:AddComboBox()

	ACF.WriteValue("Class", "acf_gun")

	function ClassList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.Selected = Data

		local Choices = Sorted[Weapons]
		Selected[Choices] = Index

		ACF.WriteValue("WeaponClass", Data.ID)

		ClassDesc:SetText(Data.Description)

		LoadSortedList(EntList, Data.Items, "Caliber")
	end

	function EntList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.Selected = Data

		local ClassData = ClassList.Selected
		local RoundVolume = 3.1416 * (Data.Caliber * 0.05) ^ 2 * Data.Round.MaxLength
		local Firerate = 60 / (((RoundVolume * 0.002) ^ 0.6) * ClassData.ROFMod * (Data.ROFMod or 1))
		local Magazine = Data.MagSize and MagText:format(Data.MagSize, Data.MagReload) or ""

		local Choices = Sorted[ClassData.Items]
		Selected[Choices] = Index

		ACF.WriteValue("Weapon", Data.ID)

		EntName:SetText(Data.Name)
		EntData:SetText(EntText:format(Data.Mass, math.Round(Firerate, 2), ClassData.Spread * 100, Magazine))
	end

	function CrateList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.Selected = Data

		local Choices = Sorted[Crates]
		Selected[Choices] = Index

		ACF.WriteValue("Crate", Data.ID)
	end

	function AmmoList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.Selected = Data

		local Choices = Sorted[AmmoTypes]
		Selected[Choices] = Index

		ACF.WriteValue("Ammo", Data.ID)

		Menu:ClearTemporal(self)
		Menu:StartTemporal(self)

		if Data.MenuAction then
			Data.MenuAction(Menu)
		end

		Menu:EndTemporal(self)
	end

	local Test = Menu:AddComboBox()
	Test:TrackDataVar("WeaponClass")
	Test:TrackDataVar("Weapon")
	Test:SetValueFunction(function()
		return ACF.ReadString("WeaponClass") .. " - " .. ACF.ReadString("Weapon")
	end)

	LoadSortedList(ClassList, Weapons, "Name")
	LoadSortedList(CrateList, Crates, "ID")
	LoadSortedList(AmmoList, AmmoTypes, "Name")
end

ACF.AddOptionItem("Entities", "Weapons", "gun", CreateMenu)
