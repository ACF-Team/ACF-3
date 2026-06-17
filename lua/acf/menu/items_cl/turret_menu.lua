local ACF     = ACF
local Classes = ACF.Classes

-- Group ID -> menu builder. The builders live in util_cl.lua; resolve lazily at
-- menu-open time so load order doesn't matter.
local function GetGroupMenu(GroupID)
	return ({
		["1-Turret"]   = ACF.CreateTurretMenu,
		["2-Motor"]    = ACF.CreateTurretMotorMenu,
		["3-Gyro"]     = ACF.CreateTurretGyroMenu,
		["4-Computer"] = ACF.CreateTurretComputerMenu,
	})[GroupID]
end

-- The turret "classes" (Turrets, Motors, Gyroscopes, Computers) are the direct
-- children of the component root; each class' own children are its items.
local function GetGroups()
	local Groups = {}
	local Root   = Classes.GetTypeByName("ACF.Turrets.Component")
	if not Root then return Groups end

	for _, Group in pairs(Classes.GetChildren(Root)) do
		Groups[#Groups + 1] = Group
	end

	return Groups
end

local function CreateMenu(Menu)
	local Groups = GetGroups()

	ACF.SetToolMode("acf_menu", "Spawner", "Turret")

	ACF.SetClientData("PrimaryClass", "N/A")
	ACF.SetClientData("SecondaryClass", "N/A")

	Menu:AddTitle("#acf.menu.turrets.menu_title")
	Menu:AddPonderAddonCategory("acf", "turrets")
	Menu:AddLabel("#acf.menu.turrets.menu_desc")

	local ClassList		= Menu:AddComboBox()
	ClassList:SetName("TurretClass")
	local ClassDesc		= Menu:AddLabel()
	local ComponentClass	= Menu:AddComboBox()
	ComponentClass:SetName("TurretComponentClass")

	local Base			= Menu:AddCollapsible("#acf.menu.turrets.components", nil, "icon16/cd_edit.png")
	local ComponentName	= Base:AddTitle()
	local ComponentDesc	= Base:AddLabel()
	local ComponentPreview = Base:AddModelPreview(nil, true, "Primary")
	Base.ComponentPreview = ComponentPreview

	function ClassList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index	= Index
		self.Selected		= Data

		ClassDesc:SetText(Data.Description or "#acf.menu.no_description_provided")

		ACF.SetToolMode("acf_menu", "Spawner", Data.ID)
		ACF.LoadSortedList(ComponentClass, Classes.GetChildren(Data), "Name", "Model")
	end

	function ComponentClass:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		local ClassData = ClassList.Selected

		ComponentName:SetText(Data.Name)
		ComponentDesc:SetText(Data.Description or "#acf.menu.no_description_provided")

		ComponentPreview:UpdateModel(Data.Model)
		ComponentPreview:UpdateSettings(Data.Preview)

		Menu:ClearTemporal(Base)
		Menu:StartTemporal(Base)

		local CustomMenu = GetGroupMenu(ClassData.ID)

		if CustomMenu then
			CustomMenu(Data, Base)
		end

		Menu:EndTemporal(Base)
	end

	ACF.LoadSortedList(ClassList, Groups, "ID", "SpawnModel")
end

ACF.AddMenuItem(51, "#acf.menu.entities", "#acf.menu.turrets", "shape_align_center", CreateMenu)
