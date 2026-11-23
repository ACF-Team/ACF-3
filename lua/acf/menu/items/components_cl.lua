local ACF     = ACF
local Classes = ACF.Classes

local COMPONENT_BASE = "ACF.Components.BaseComponent"

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

-- Component groups that spawn ClassName
local function GetGroups(ClassName)
	local Groups = {}
	local Base   = Classes.GetTypeByName(COMPONENT_BASE)
	if not Base then return Groups end

	for Name, Group in pairs(Classes.GetChildren(Base)) do
		if Group.Entity == ClassName then Groups[Name] = Group end
	end

	return Groups
end

local function CreateBuild(PAGE, ClassName)
	return function(Menu, Contexts)
		local Ctx    = Contexts.Component
		local Groups = GetGroups(ClassName)

		if not next(Groups) then
			Menu:AddTitle("#acf.menu.components.none_registered")
			Menu:AddLabel("#acf.menu.components.none_registered_desc")
			return
		end

		Menu:AddTitle("#acf.menu.components.settings")

		local ComponentClass = Menu:AddComboBox()
		local ComponentList  = Menu:AddComboBox()

		Menu:AddPresets(Ctx)

		local Base             = Menu:AddCollapsible("#acf.menu.components.component_info", nil, "icon16/drive_edit.png")
		local ComponentName    = Base:AddTitle()
		local ComponentDesc    = Base:AddLabel()
		local ComponentPreview = Base:AddModelPreview(nil, true, "Primary")
		Base.ComponentPreview  = ComponentPreview

		-- Nothing to pick from a single choice
		ComponentClass:SetVisible(table.Count(Groups) > 1)

		function ComponentClass:OnSelect(Index, _, Data)
			if self.Selected == Data then return end
			self.ListData.Index = Index
			self.Selected = Data
			ACF.Menu.SaveClassCombo(PAGE, "group", Data)

			local Children = Classes.GetChildren(Data)
			local Options  = table.Count(Children) > 0 and Children or { [Classes.GetTypeName(Data)] = Data }

			ComponentList:SetVisible(table.Count(Options) > 1)
			ACF.Menu.LoadClassCombo(ComponentList, Options, "Name", nil, PAGE, "item")
		end

		function ComponentList:OnSelect(Index, _, Data)
			if self.Selected == Data then return end
			self.ListData.Index = Index
			self.Selected = Data
			ACF.Menu.SaveClassCombo(PAGE, "item", Data)

			local ClassData = ComponentClass.Selected

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

		ACF.Menu.LoadClassCombo(ComponentClass, Groups, "Name", "Icon", PAGE, "group")
	end
end

local function RegisterComponentPage(ClassName, Category, Name, Icon, Order)
	ACF.Menu.RegisterPage({
		ID       = ClassName,
		Category = Category,
		Name     = Name,
		Icon     = Icon,
		Order    = Order,

		Contexts = { Component = ClassName },

		Actions = {
			{ Bind = "left",  Context = "Component", Preview = true, Desc = "Spawn a new component, or update the one you're aiming at." },
			{ Bind = "right", Commit = "link", Desc = "Select entities, then a component, to link them (hold R to unlink)." },
		},

		Build = CreateBuild(ClassName, ClassName),
	})
end

RegisterComponentPage("acf_autoloader", "#acf.menu.weaponry", "#acf.menu.components.autoloaders", "arrow_rotate_clockwise", 201)
RegisterComponentPage("acf_computer", "#acf.menu.weaponry", "#acf.menu.components.computers", "computer", 301)
RegisterComponentPage("acf_waterjet", "#acf.menu.mobility", "#acf.menu.components.waterjets", "water", 401)
RegisterComponentPage("acf_sensorsync", "#acf.menu.sensors", "#acf.menu.sensors.sync", "arrow_join", 4)
RegisterComponentPage("acf_supply", "#acf.menu.support", "#acf.menu.components.supply", "package", 1)
RegisterComponentPage("acf_groundloader", "#acf.menu.support", "#acf.menu.components.groundloaders", "lorry_go", 2)
