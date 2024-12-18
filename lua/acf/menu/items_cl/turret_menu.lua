local ACF		= ACF
local Turrets	= ACF.Classes.Turrets

local function CreateMenu(Menu)
	local Entries = Turrets.GetEntries()

	ACF.SetToolMode("acf_menu", "Spawner", "Turret")

	ACF.SetClientData("PrimaryClass", "N/A")
	ACF.SetClientData("SecondaryClass", "N/A")

	Menu:AddTitle("Procedural Turrets")
	Menu:AddLabel("Typically, place the horizontal turret, and then parent a vertical turret to it to make a fully functional turret. You can parent anything directly to the turret pieces and they will be attached and rotate correctly.")

	local ClassList		= Menu:AddComboBox()
	local ClassDesc		= Menu:AddLabel()
	local ComponentClass	= Menu:AddComboBox()

	local Base			= Menu:AddCollapsible("Turret Components")
	local ComponentName	= Base:AddTitle()
	local ComponentDesc	= Base:AddLabel()
	local ComponentPreview = Base:AddModelPreview(_, true)

	function ClassList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index	= Index
		self.Selected		= Data

		ClassDesc:SetText(Data.Description or "No description provided.")

		ACF.SetToolMode("acf_menu", "Spawner", Data.ID)
		ACF.LoadSortedList(ComponentClass, Data.Items, "Name")
	end

	function ComponentClass:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		local ClassData = ClassList.Selected

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

	ACF.LoadSortedList(ClassList, Entries, "ID")
end

ACF.AddMenuItem(51, "Entities", "Turrets", "shape_align_center", CreateMenu)