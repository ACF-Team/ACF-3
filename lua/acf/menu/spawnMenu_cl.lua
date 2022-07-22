ACF.MenuOptions = ACF.MenuOptions or {}
ACF.MenuLookup = ACF.MenuLookup or {}
ACF.MenuCount = ACF.MenuCount or 0

local Options = ACF.MenuOptions
local Lookup = ACF.MenuLookup

do -- Menu population functions
	local function DefaultAction(Menu)
		Menu:AddTitle("There's nothing here.")
		Menu:AddLabel("This option is either a work in progress or something isn't working as intended.")
	end

	function ACF.AddMenuOption(Index, Name, Icon, Enabled)
		if not Index then return end
		if not Name then return end
		if not isfunction(Enabled) then Enabled = nil end

		if not Lookup[Name] then
			local Count = ACF.MenuCount + 1

			Options[Count] = {
				Icon = "icon16/" .. (Icon or "plugin") .. ".png",
				IsEnabled = Enabled,
				Index = Index,
				Name = Name,
				Lookup = {},
				List = {},
				Count = 0,
			}

			Lookup[Name] = Options[Count]

			ACF.MenuCount = Count
		else
			local Option = Lookup[Name]

			Option.Icon = "icon16/" .. (Icon or "plugin") .. ".png"
			Option.IsEnabled = Enabled
			Option.Index = Index
		end
	end

	function ACF.AddMenuItem(Index, Option, Name, Icon, Action, Enabled)
		if not Index then return end
		if not Option then return end
		if not Name then return end
		if not Lookup[Option] then return end
		if not isfunction(Enabled) then Enabled = nil end

		local Items = Lookup[Option]
		local Item = Items.Lookup[Name]

		if not Item then
			Items.Count = Items.Count + 1

			Items.List[Items.Count] = {
				Icon = "icon16/" .. (Icon or "plugin") .. ".png",
				Action = Action or DefaultAction,
				IsEnabled = Enabled,
				Option = Option,
				Index = Index,
				Name = Name,
			}

			Items.Lookup[Name] = Items.List[Items.Count]
		else
			Item.Icon = "icon16/" .. (Icon or "plugin") .. ".png"
			Item.Action = Action or DefaultAction
			Item.IsEnabled = Enabled
			Item.Option = Option
			Item.Index = Index
			Item.Name = Name
		end
	end

	ACF.AddMenuOption(1, "About the Addon", "information")
	ACF.AddMenuOption(101, "Settings", "wrench")
	ACF.AddMenuOption(201, "Entities", "brick")
	ACF.AddMenuOption(9999, "Fun Stuff", "bricks")
end

do -- ACF Menu context panel
	local function GetSortedList(List)
		local Result = {}

		for K, V in ipairs(List) do
			Result[K] = V
		end

		table.SortByMember(Result, "Index", true)

		return Result
	end

	local function AllowOption(Option)
		if Option.IsEnabled and not Option:IsEnabled() then return false end

		return hook.Run("ACF_AllowMenuOption", Option.Index, Option.Name) ~= false
	end

	local function AllowItem(Item)
		if Item.IsEnabled and not Item:IsEnabled() then return false end

		return hook.Run("ACF_AllowMenuItem", Item.Index, Item.Option, Item.Name) ~= false
	end

	local function UpdateTree(Tree, Old, New)
		local OldParent = Old and Old.Parent
		local NewParent = New.Parent

		if OldParent == NewParent then return end

		if OldParent then
			OldParent.AllowExpand = true
			OldParent:SetExpanded(false)
		end

		NewParent.AllowExpand = true
		NewParent:SetExpanded(true)

		Tree:SetHeight(Tree:GetLineHeight() * (Tree.BaseHeight + NewParent.Count))
	end

	local function PopulateTree(Tree)
		local OptionList = GetSortedList(Options)
		local First

		Tree.BaseHeight = 0.5

		for _, Option in ipairs(OptionList) do
			if not AllowOption(Option) then continue end

			local Parent = Tree:AddNode(Option.Name, Option.Icon)
			local SetExpanded = Parent.SetExpanded
			local Expander = Parent.Expander

			Parent.Action = Option.Action
			Parent.Master = true
			Parent.Count = 0

			function Parent:SetExpanded(Bool)
				if not self.AllowExpand then return end

				SetExpanded(self, Bool)

				self.AllowExpand = nil
			end

			function Expander:DoClick()
				local Node = Parent:GetParentNode()

				Node:OnNodeSelected(Parent)
			end

			Tree.BaseHeight = Tree.BaseHeight + 1

			local ItemList = GetSortedList(Option.List)
			for _, Item in ipairs(ItemList) do
				if not AllowItem(Item) then continue end

				local Child = Parent:AddNode(Item.Name, Item.Icon)
				Child.Action = Item.Action
				Child.Parent = Parent

				Parent.Count = Parent.Count + 1

				if not Parent.Selected then
					Parent.Selected = Child

					if not First then
						First = Child
					end
				end
			end
		end

		Tree:SetSelectedItem(First)
	end

	function ACF.CreateSpawnMenu(Panel)
		local Menu = ACF.SpawnMenu

		if not IsValid(Menu) then
			Menu = vgui.Create("ACF_Panel")
			Menu.Panel = Panel

			Panel:AddItem(Menu)

			ACF.SpawnMenu = Menu
		else
			Menu:ClearAllTemporal()
			Menu:ClearAll()
		end

		local Reload = Menu:AddButton("Reload Menu")
		Reload:SetTooltip("You can also type 'acf_reload_spawn_menu' in console.")
		function Reload:DoClickInternal()
			ACF.CreateSpawnMenu(Panel)
		end

		local Tree = Menu:AddPanel("DTree")
		function Tree:OnNodeSelected(Node)
			if self.Selected == Node then return end

			if Node.Master then
				self:SetSelectedItem(Node.Selected)
				return
			end

			UpdateTree(self, self.Selected, Node)

			Node.Parent.Selected = Node
			self.Selected = Node

			ACF.SetToolMode("acf_menu", "Main", "Idle")
			ACF.SetClientData("Destiny")

			Menu:ClearTemporal()
			Menu:StartTemporal()

			Node.Action(Menu)

			Menu:EndTemporal()
		end

		PopulateTree(Tree)
	end
end

do -- Client and server settings
	ACF.SettingsPanels = ACF.SettingsPanels or {
		Client = {},
		Server = {},
	}

	local Settings = ACF.SettingsPanels

	--- Generates the following functions:
	-- ACF.AddClientSettings(Index, Name, Function)
	-- ACF.RemoveClientSettings(Name)
	-- ACF.GenerateClientSettings(MenuPanel)
	-- ACF.AddServerSettings(Index, Name, Function)
	-- ACF.RemoveServerSettings(Name)
	-- ACF.GenerateServerSettings(MenuPanel)

	for Realm, Destiny in pairs(Settings) do
		local Hook    = "ACF_On" .. Realm .. "SettingsLoaded"
		local Message = "No %sside settings have been registered."

		ACF["Add" .. Realm .. "Settings"] = function(Index, Name, Function)
			if not isnumber(Index) then return end
			if not isstring(Name) then return end
			if not isfunction(Function) then return end

			Destiny[Name] = {
				Create = Function,
				Index = Index,
			}
		end

		ACF["Remove" .. Realm .. "Settings"] = function(Name)
			if not isstring(Name) then return end

			Destiny[Name] = nil
		end

		ACF["Generate" .. Realm .. "Settings"] = function(Menu)
			if not ispanel(Menu) then return end

			if not next(Destiny) then
				Menu:AddTitle("Nothing to see here.")
				Menu:AddLabel(Message:format(Realm))
				return
			end

			for Name, Data in SortedPairsByMemberValue(Destiny, "Index") do
				local Base, Section = Menu:AddCollapsible(Name, false)

				function Section:OnToggle(Bool)
					if not Bool then return end
					if self.Created then return end

					Data.Create(Base)

					hook.Run(Hook, Name, Base)

					self.Created = true
				end
			end
		end
	end
end
