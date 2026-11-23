local ACF     = ACF
local Classes = ACF.Classes

local function GetItems(Group)
	if Classes.GetTypeName(Group) == "ACF.Turrets.Drive" then return ACF.GetTurretDrives() end

	return Classes.GetChildren(Group)
end

-- The drive type a copied acf_turret was spawned with
local function GetCopiedDrive(Data)
	local Turret = Data.Turret

	return Classes.GetTypeByName(istable(Turret) and Turret.Type or Turret)
end

local function CreateBuild(PAGE, GroupName, ShowGuide)
	return function(Menu, Contexts)
		local Ctx   = Contexts.Component
		local Group = Classes.GetTypeByName(GroupName)

		Menu:AddTitle("#acf.menu.turrets.menu_title")
		Menu:AddPonderAddonCategory("acf", "tankbasics")

		if ShowGuide then Menu:AddLabel("#acf.menu.turrets.menu_desc") end

		if not Group then return end

		Menu:AddLabel(Group.Description or "#acf.menu.no_description_provided")

		local ComponentClass = Menu:AddComboBox()

		Menu:AddPresets(Ctx)

		local Base             = Menu:AddCollapsible("#acf.menu.turrets.components", nil, "icon16/cd_edit.png")
		local ComponentName    = Base:AddTitle()
		local ComponentDesc    = Base:AddLabel()
		local ComponentPreview = Base:AddModelPreview(nil, true, "Primary")
		Base.ComponentPreview  = ComponentPreview -- the builders scale this via Menu.ComponentPreview

		function ComponentClass:OnSelect(Index, _, Data)
			if self.Selected == Data then return end
			self.ListData.Index = Index
			self.Selected = Data
			ACF.Menu.SaveClassCombo(PAGE, "item", Data)

			ComponentName:SetText(Data.Name)
			ComponentDesc:SetText(Data.Description or "#acf.menu.no_description_provided")
			ComponentPreview:UpdateModel(Data.Model)
			ComponentPreview:UpdateSettings(Data.Preview)

			Menu:ClearTemporal(Base)
			Menu:StartTemporal(Base)
			if Group.CreateMenu then Group.CreateMenu(Data, Base, Ctx) end
			Menu:EndTemporal(Base)
		end

		local Items = GetItems(Group)

		-- Nothing to pick from a single choice
		ComponentClass:SetVisible(table.Count(Items) > 1)

		ACF.Menu.LoadClassCombo(ComponentClass, Items, "Name", "Model", PAGE, "item")
	end
end

local function RegisterTurretPage(Page)
	local Group = Page.Group

	ACF.Menu.RegisterPage({
		ID       = Page.ID,
		Category = "#acf.menu.turrets",
		Name     = Page.Name,
		Icon     = Page.Icon,
		Order    = Page.Order,

		Contexts = { Component = Page.Entity },

		-- Rings, servos and actuators are all acf_turret
		AcceptsCopy = Page.Entity == "acf_turret" and function(_, Data)
			local Drive = GetCopiedDrive(Data)

			if not Drive then return Group == "ACF.Turrets.Drive" end
			if Group ~= "ACF.Turrets.Drive" then return Classes.IsAssignableTo(Drive, Classes.GetTypeByName(Group)) end

			return not Classes.IsAssignableTo(Drive, Classes.GetTypeByName("ACF.Turrets.Servo"))
				and not Classes.IsAssignableTo(Drive, Classes.GetTypeByName("ACF.Turrets.Actuator"))
		end or nil,

		Actions = {
			{ Bind = "left",  Context = "Component", Preview = true, Desc = "Spawn a new turret component, or update the one you're aiming at." },
			{ Bind = "right", Commit = "link", Desc = "Select entities, then a turret component, to link them (hold R to unlink)." },
		},

		Build = CreateBuild(Page.ID, Group, Page.ShowGuide),
	})
end

RegisterTurretPage({ ID = "acf_turret", Group = "ACF.Turrets.Drive", Entity = "acf_turret", Name = "#acf.menu.turrets.rings", Icon = "arrow_rotate_anticlockwise", Order = 1, ShowGuide = true })
RegisterTurretPage({ ID = "acf_turret_servo", Group = "ACF.Turrets.Servo", Entity = "acf_turret", Name = "#acf.menu.turrets.servos", Icon = "arrow_switch", Order = 2 })
RegisterTurretPage({ ID = "acf_turret_actuator", Group = "ACF.Turrets.Actuator", Entity = "acf_turret", Name = "#acf.menu.turrets.actuators", Icon = "arrow_inout", Order = 3 })
RegisterTurretPage({ ID = "acf_turret_motor", Group = "ACF.Turrets.Motor", Entity = "acf_turret_motor", Name = "#acf.menu.turrets.motors", Icon = "cog", Order = 4 })
RegisterTurretPage({ ID = "acf_turret_gyro", Group = "ACF.Turrets.Gyro", Entity = "acf_turret_gyro", Name = "#acf.menu.turrets.gyros", Icon = "arrow_refresh", Order = 5 })
RegisterTurretPage({ ID = "acf_turret_computer", Group = "ACF.Turrets.Computer", Entity = "acf_turret_computer", Name = "#acf.menu.turrets.computers", Icon = "calculator", Order = 6 })
RegisterTurretPage({ ID = "acf_turret_controller", Group = "ACF.Turrets.Controller", Entity = "acf_turret_controller", Name = "#acf.menu.turrets.controllers", Icon = "controller", Order = 7 })
