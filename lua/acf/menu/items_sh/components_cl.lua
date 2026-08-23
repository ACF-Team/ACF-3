local ACF     = ACF
local Classes = ACF.Classes
local PAGE    = "acf_component"

local COMPONENT_BASE = "ACF.Components.BaseComponent"
local CTX_NAMES      = { "Computer", "Autoloader", "Supply", "Waterjet", "GroundLoader" }

-- Maps a component group to the context whose SENT it spawns.
local function ContextFor(Contexts, Group)
	for _, Name in ipairs(CTX_NAMES) do
		local Ctx = Contexts[Name]
		if Ctx and Ctx.ClassName == Group.Entity then return Ctx end
	end
end

-- If the context's SENT has a nested class field the selected component is assignable to (computers'
-- "Computer" field), write the chosen type into it. Other SENTs have no such field, so this no-ops.
local function SetNestedType(Ctx, Item)
	for _, Field in ipairs(Classes.GetTypeFields(Ctx.Class)) do
		if not Field.Menu then continue end

		local BaseType = Classes.GetTypeByName(Field.Type:gsub("%[%]$", ""))
		if BaseType and Classes.IsAssignableTo(Item, BaseType) then
			Ctx:Set(Field.Name, Classes.GetTypeName(Item))
			return
		end
	end
end

local function Build(Menu, Contexts)
	local Entries = Classes.GetChildren(Classes.GetTypeByName(COMPONENT_BASE))

	if not next(Entries) then
		Menu:AddTitle("#acf.menu.components.none_registered")
		Menu:AddLabel("#acf.menu.components.none_registered_desc")
		return
	end

	Menu:AddTitle("#acf.menu.components.settings")

	local ComponentClass = Menu:AddComboBox()
	local ComponentList  = Menu:AddComboBox()

	local Base             = Menu:AddCollapsible("#acf.menu.components.component_info", nil, "icon16/drive_edit.png")
	local ComponentName    = Base:AddTitle()
	local ComponentDesc    = Base:AddLabel()
	local ComponentPreview = Base:AddModelPreview(nil, true, "Primary")
	Base.ComponentPreview  = ComponentPreview

	function ComponentClass:OnSelect(Index, _, Data)
		if self.Selected == Data then return end
		self.ListData.Index = Index
		self.Selected = Data
		ACF.Menu.SaveClassCombo(PAGE, "group", Data)

		Contexts.Active = ContextFor(Contexts, Data)

		local Children = Classes.GetChildren(Data)
		local Options  = table.Count(Children) > 0 and Children or { [Classes.GetTypeName(Data)] = Data }

		ACF.Menu.LoadClassCombo(ComponentList, Options, "Name", nil, PAGE, "item")
	end

	function ComponentList:OnSelect(Index, _, Data)
		if self.Selected == Data then return end
		self.ListData.Index = Index
		self.Selected = Data
		ACF.Menu.SaveClassCombo(PAGE, "item", Data)

		local ClassData = ComponentClass.Selected
		local Ctx       = ContextFor(Contexts, ClassData)
		Contexts.Active = Ctx

		SetNestedType(Ctx, Data)

		ComponentName:SetText(Data.Name)
		ComponentDesc:SetText(Data.Description or "#acf.menu.no_description_provided")

		ComponentPreview:UpdateModel(Data.Model, Data.Material or "")
		ComponentPreview:UpdateSettings(Data.Preview)

		Menu:ClearTemporal(Base)
		Menu:StartTemporal(Base)

		local CustomMenu = Data.CreateMenu or ClassData.CreateMenu

		if CustomMenu then
			local TutorialURL = Data.TutorialURL or ClassData.TutorialURL
			if TutorialURL then Base:AddWikiLink(Data.Name, TutorialURL) end

			CustomMenu(Data, Base, Ctx)
		end

		Menu:EndTemporal(Base)
	end

	ACF.Menu.LoadClassCombo(ComponentClass, Entries, "Name", nil, PAGE, "group")
end

ACF.Menu.RegisterPage({
	ID       = "acf_component",
	Category = "#acf.menu.entities",
	Name     = "#acf.menu.components",
	Icon     = "drive",
	Order    = 501,

	Contexts = {
		Computer     = "acf_computer",
		Autoloader   = "acf_autoloader",
		Supply       = "acf_supply",
		Waterjet     = "acf_waterjet",
		GroundLoader = "acf_groundloader",
	},
	LinkContexts = function(Contexts) Contexts.Active = Contexts.Computer end,

	Actions = {
		{ Bind = "left",  Context = "Active", Preview = true, Desc = "Spawn a new component, or update the one you're aiming at." },
		{ Bind = "right", Commit = "link", Desc = "Select entities, then a component, to link them (hold R to unlink)." },
	},

	Build = Build,
})
