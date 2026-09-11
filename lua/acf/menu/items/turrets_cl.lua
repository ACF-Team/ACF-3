local ACF     = ACF
local Classes = ACF.Classes
local PAGE    = "acf_turret"

local CTX_NAMES = { "Drive", "Motor", "Gyro", "Computer" }

local function GetGroups()
	local Groups = {}
	local Root   = Classes.GetTypeByName("ACF.Turrets.Component")
	if not Root then return Groups end

	for _, Group in pairs(Classes.GetChildren(Root)) do
		Groups[#Groups + 1] = Group
	end

	return Groups
end

local function Build(Menu, Contexts)
	-- Maps a group's target SENT to the matching context.
	local function ContextFor(Group)
		for _, Name in ipairs(CTX_NAMES) do
			local Ctx = Contexts[Name]
			if Ctx and Ctx.ClassName == Group.Entity then return Ctx end
		end
	end

	Menu:AddTitle("#acf.menu.turrets.menu_title")
	Menu:AddPonderAddonCategory("acf", "turrets")
	Menu:AddLabel("#acf.menu.turrets.menu_desc")

	local ClassList      = Menu:AddComboBox()
	local ClassDesc      = Menu:AddLabel()
	local ComponentClass = Menu:AddComboBox()

	local Base             = Menu:AddCollapsible("#acf.menu.turrets.components", nil, "icon16/cd_edit.png")
	local ComponentName    = Base:AddTitle()
	local ComponentDesc    = Base:AddLabel()
	local ComponentPreview = Base:AddModelPreview(nil, true, "Primary")
	Base.ComponentPreview  = ComponentPreview -- the builders scale this via Menu.ComponentPreview

	function ClassList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end
		self.ListData.Index = Index
		self.Selected = Data
		ACF.Menu.SaveClassCombo(PAGE, "group", Data)

		ClassDesc:SetText(Data.Description or "#acf.menu.no_description_provided")
		Contexts.Active = ContextFor(Data)

		ACF.Menu.LoadClassCombo(ComponentClass, Classes.GetChildren(Data), "Name", "Model", PAGE, "item")
	end

	function ComponentClass:OnSelect(Index, _, Data)
		if self.Selected == Data then return end
		self.ListData.Index = Index
		self.Selected = Data
		ACF.Menu.SaveClassCombo(PAGE, "item", Data)

		local Group = ClassList.Selected
		local Ctx   = ContextFor(Group)
		Contexts.Active = Ctx

		ComponentName:SetText(Data.Name)
		ComponentDesc:SetText(Data.Description or "#acf.menu.no_description_provided")
		ComponentPreview:UpdateModel(Data.Model)
		ComponentPreview:UpdateSettings(Data.Preview)

		Menu:ClearTemporal(Base)
		Menu:StartTemporal(Base)
		if Group.CreateMenu then Group.CreateMenu(Data, Base, Ctx) end
		Menu:EndTemporal(Base)
	end

	ACF.Menu.LoadClassCombo(ClassList, GetGroups(), "ID", "SpawnModel", PAGE, "group")
end

ACF.Menu.RegisterPage({
	ID       = "acf_turret",
	Category = "#acf.menu.entities",
	Name     = "#acf.menu.turrets",
	Icon     = "shape_align_center",
	Order    = 51,

	Contexts = {
		Drive    = "acf_turret",
		Motor    = "acf_turret_motor",
		Gyro     = "acf_turret_gyro",
		Computer = "acf_turret_computer",
	},
	LinkContexts = function(Contexts) Contexts.Active = Contexts.Drive end,

	Actions = {
		{ Bind = "left",  Context = "Active", Preview = true, Desc = "Spawn a new turret component, or update the one you're aiming at." },
		{ Bind = "right", Commit = "link", Desc = "Select entities, then a turret component, to link them (hold R to unlink)." },
	},

	Build = Build,
})
