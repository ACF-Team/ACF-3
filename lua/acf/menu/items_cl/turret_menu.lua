local ACF		= ACF
local Turrets	= ACF.Classes.Turrets

local function CreateMenu(Menu)
	local Entries = Turrets.GetEntries()

	ACF.SetToolMode("acf_menu", "Spawner", "Component")

	ACF.SetClientData("PrimaryClass", "N/A")
	ACF.SetClientData("SecondaryClass", "N/A")

	Menu:AddTitle("Procedural Turrets")
	Menu:AddLabel("Warning: Experimental!\nTurret entities are a work in progress, and may lead to some strange events!\nReport any crashes or other issues if you come across them!")

	Menu:AddLabel("Typically, place the horizontal turret, and then parent a vertical turret to it to make a fully functional turret. You can parent anything directly to the turret pieces and they will be attached and rotate correctly.")

	local ClassList		= Menu:AddComboBox()
	local ClassDesc		= Menu:AddLabel()
	local ComponentClass	= Menu:AddComboBox()

	local Base			= Menu:AddCollapsible("Turret Components")
	local ComponentName	= Base:AddTitle()
	local ComponentDesc	= Base:AddLabel()

	Base.ApplySchemeSettings = function(Panel)
		Panel:SetBGColor(Color(175,175,175))
	end

	function ClassList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index	= Index
		self.Selected		= Data

		ClassDesc:SetText(Data.Description or "No description provided.")

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