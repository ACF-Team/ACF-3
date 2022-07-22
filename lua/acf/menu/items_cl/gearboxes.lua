local ACF = ACF
local Gearboxes = ACF.Classes.Gearboxes

local function CreateMenu(Menu)
	local Entries = Gearboxes.GetEntries()

	Menu:AddTitle("Gearbox Settings")

	local GearboxClass = Menu:AddComboBox()
	local GearboxList = Menu:AddComboBox()

	local Base = Menu:AddCollapsible("Gearbox Information")
	local GearboxName = Base:AddTitle()
	local GearboxDesc = Base:AddLabel()
	local GearboxPreview = Base:AddModelPreview(nil, true)

	ACF.SetClientData("PrimaryClass", "acf_gearbox")
	ACF.SetClientData("SecondaryClass", "N/A")

	ACF.SetToolMode("acf_menu", "Spawner", "Gearbox")

	function GearboxClass:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		ACF.SetClientData("GearboxClass", Data.ID)

		ACF.LoadSortedList(GearboxList, Data.Items, "ID")
	end

	function GearboxList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		local ClassData = GearboxClass.Selected

		ACF.SetClientData("Gearbox", Data.ID)

		GearboxName:SetText(Data.Name)
		GearboxDesc:SetText(Data.Description)

		GearboxPreview:UpdateModel(Data.Model)
		GearboxPreview:UpdateSettings(Data.Preview)

		Menu:ClearTemporal(Base)
		Menu:StartTemporal(Base)

		if ClassData.CreateMenu then
			ClassData:CreateMenu(Data, Menu, Base)
		end

		Menu:EndTemporal(Base)
	end

	ACF.LoadSortedList(GearboxClass, Entries, "ID")
end

ACF.AddMenuItem(301, "Entities", "Gearboxes", "cog", CreateMenu)
