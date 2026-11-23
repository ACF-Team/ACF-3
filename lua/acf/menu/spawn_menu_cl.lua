local hook = hook
local ACF  = ACF

ACF.MenuOptions   = ACF.MenuOptions or {}
ACF.MenuLookup    = ACF.MenuLookup or {}
ACF.MenuCount     = ACF.MenuCount or 0
ACF.MenuRootItems = ACF.MenuRootItems or { Lookup = {}, List = {}, Count = 0 }

local Options   = ACF.MenuOptions
local Lookup    = ACF.MenuLookup
local RootItems = ACF.MenuRootItems

do -- Menu population functions
	local function DefaultAction(Menu)
		Menu:AddTitle("#acf.menu.default_action_title")
		Menu:AddLabel("#acf.menu.default_action_desc")
	end

	--- Adds a group to the menu tree. Parent is the name of the group it goes in, nil for the top level.
	--- The parent doesn't need to exist yet, the tree is put together when the menu gets built.
	function ACF.AddMenuGroup(Index, Parent, Name, Icon, Enabled)
		if not Index then return end
		if not Name then return end
		if not isfunction(Enabled) then Enabled = nil end

		local Group = Lookup[Name]

		if not Group then
			local Count = ACF.MenuCount + 1

			Group = {
				Name = Name,
				Lookup = {},
				List = {},
				Count = 0,
			}

			Options[Count] = Group
			Lookup[Name]   = Group

			ACF.MenuCount = Count
		end

		Group.Icon = "icon16/" .. (Icon or "plugin") .. ".png"
		Group.IsEnabled = Enabled
		Group.Parent = Parent
		Group.Index = Index
	end

	function ACF.AddMenuOption(Index, Name, Icon, Enabled)
		ACF.AddMenuGroup(Index, nil, Name, Icon, Enabled)
	end

	function ACF.GetMenuItem(Option, Name)
		return (Option and Lookup[Option] or RootItems).Lookup[Name]
	end

	--- Adds a page to a group, or to the top level if Option is nil.
	function ACF.AddMenuItem(Index, Option, Name, Icon, Action, Enabled)
		if not Index then return end
		if not Name then return end
		if Option and not Lookup[Option] then return end
		if not isfunction(Enabled) then Enabled = nil end

		local Items = Option and Lookup[Option] or RootItems
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

	ACF.AddMenuOption(1, "#acf.menu.about", "information")
	ACF.AddMenuOption(101, "#acf.menu.entities", "brick")
	ACF.AddMenuOption(301, "#acf.menu.settings", "wrench")
	ACF.AddMenuOption(9999, "#acf.menu.fun", "bricks")

	ACF.AddMenuGroup(1, "#acf.menu.entities", "#acf.menu.weaponry", "bomb")
	ACF.AddMenuGroup(11, "#acf.menu.entities", "#acf.menu.turrets", "shape_align_center")
	ACF.AddMenuGroup(201, "#acf.menu.entities", "#acf.menu.mobility", "lorry")
	ACF.AddMenuGroup(401, "#acf.menu.entities", "#acf.menu.sensors", "transmit")
	ACF.AddMenuGroup(501, "#acf.menu.entities", "#acf.menu.support", "box")
	ACF.AddMenuGroup(201, "#acf.menu.settings", "#acf.menu.permissions", "gun")
end


do -- ACF Menu context panel
	local Indent = 20

	local function AllowOption(Option)
		if Option.IsEnabled and not Option:IsEnabled() then return false end

		local Allow = hook.Run("ACF_OnEnableMenuOption", Option.Name)

		return Allow
	end

	local function AllowItem(Item)
		if Item.IsEnabled and not Item:IsEnabled() then return false end

		local Allow = hook.Run("ACF_OnEnableMenuItem", Item.Option, Item.Name)

		return Allow
	end

	-- Groups and items of every group, sorted together
	local function GetEntries()
		local Roots, Entries = {}, {}

		for K, Item in ipairs(RootItems.List) do
			Roots[K] = Item
		end

		for _, Group in ipairs(Options) do
			local List = {}

			for K, Item in ipairs(Group.List) do
				List[K] = Item
			end

			Entries[Group] = List
		end

		for _, Group in ipairs(Options) do
			local Parent = Group.Parent

			if not Parent then
				Roots[#Roots + 1] = Group
			elseif Lookup[Parent] then
				local List = Entries[Lookup[Parent]]

				List[#List + 1] = Group
			end
		end

		table.SortByMember(Roots, "Index", true)

		for _, List in pairs(Entries) do
			table.SortByMember(List, "Index", true)
		end

		return Roots, Entries
	end

	-- Leaves out anything disabled and groups with nothing left in them
	local function GetAllowed(List, Entries)
		local Result = {}

		for _, Entry in ipairs(List) do
			if Entry.List then
				if not AllowOption(Entry) then continue end

				local Children = GetAllowed(Entries[Entry], Entries)

				if Children[1] then
					Result[#Result + 1] = { Group = Entry, Children = Children }
				end
			elseif AllowItem(Entry) then
				Result[#Result + 1] = { Item = Entry }
			end
		end

		return Result
	end

	-- Opens the groups on the path to the selected page and closes the rest
	-- Returns how many rows are showing under Parent
	local function SetBranches(Parent, Path, Animate)
		local Rows = 0

		for _, Node in ipairs(Parent:GetChildNodes()) do
			Rows = Rows + 1

			if not Node.Master then continue end

			local Open    = Path[Node] or false
			local WasOpen = Node:GetExpanded() or false

			if Open then
				-- inner groups settle before this one animates
				Rows = Rows + SetBranches(Node, Path, Animate and WasOpen)
			end

			if Open ~= WasOpen then
				Node.AllowExpand = true
				Node:SetExpanded(Open, not Animate)
			end
		end

		return Rows
	end

	local function UpdateTree(Tree, New)
		local Path  = {}
		local Group = New:GetParentNode()

		while Group.Master do
			Path[Group] = true
			Group = Group:GetParentNode()
		end

		local Rows = SetBranches(Tree:Root(), Path, true)

		Tree:SetHeight(Tree:GetLineHeight() * (0.5 + Rows))
	end

	local function FixStupidNodeCutoffTextIssue(Node)
		function Node:AnimSlide( anim, delta, data )
			if not IsValid(self.ChildNodes) then anim:Stop() return end

			if anim.Started then
				data.To = self:GetTall()
				data.Visible = self.ChildNodes:IsVisible()
			end

			if anim.Finished then
				self:InvalidateLayout()
				self.ChildNodes:SetVisible( data.Visible )
				self:SetTall( data.To )
				self:GetParentNode():ChildExpanded()
				return
			end
			self:SetTall(Lerp(math.ease.InOutSine(delta), data.From, data.To))

			-- These fix the label overflow
			self.ChildNodes:SetVisible(true)
			self.ChildNodes:SetWide(20000)
			self.Label:SetWide(20000)

			self:GetParentNode():ChildExpanded()
		end

		function Node:PerformLayout()
			if self:IsRootNode() then
				return self:PerformRootNodeLayout()
			end

			if self.animSlide:Active() then return end

			local LineHeight = self:GetLineHeight()

			self.Expander:SetPos(-11, 0)
			self.Expander:SetSize(15, 15)
			self.Expander:SetVisible(false)

			self.Label:StretchToParent(0, nil, 0, nil)
			self.Label:SetTall(LineHeight)

			self.Icon:SetVisible(true)
			self.Icon:SetPos(self.Expander.x + self.Expander:GetWide() + 4, (LineHeight - self.Icon:GetTall()) * 0.5)
			self.Label.TextInset = self.Icon.x + self.Icon:GetWide() + 4
			self.Label:SetTextInset(self.Label.TextInset, 0)

			if not IsValid(self.ChildNodes) or not self.ChildNodes:IsVisible() then
				self:SetTall(LineHeight)
				return
			end

			self.ChildNodes:SizeToContents()
			self:SetTall(LineHeight + self.ChildNodes:GetTall())

			self.ChildNodes:StretchToParent(Indent, LineHeight, 0, 0)

			self:DoChildrenOrder()
		end

		Node:SetHideExpander(true)
		Node:SetDrawLines(false)
		Node.animSlide = Derma_Anim("Anim", Node, Node.AnimSlide)
	end

	-- The skin draws the selection at a fixed x
	local function PulseLabel(self, _, h)
		if not self.m_bSelected then return end

		local Skin = self:GetSkin()
		local Wide = self:GetTextSize()

		surface.SetAlphaMultiplier(math.Remap(math.sin(CurTime() * 7), -1, 1, 0.6, 1))
		Skin.tex.Selection((self.TextInset or 41) - 3, 0, Wide + 6, h)
		surface.SetAlphaMultiplier(1)
	end

	local function AddNodes(Parent, List, Wanted, Found)
		for _, Entry in ipairs(List) do
			local Data = Entry.Group or Entry.Item
			local Node = Parent:AddNode(Data.Name, Data.Icon)

			FixStupidNodeCutoffTextIssue(Node)

			if Entry.Group then
				local SetExpanded = Node.SetExpanded

				Node.Master = true

				function Node:SetExpanded(Bool, Instant)
					if not self.AllowExpand then return end

					SetExpanded(self, Bool, Instant)

					self.AllowExpand = nil
				end

				AddNodes(Node, Entry.Children, Wanted, Found)

				local First = Node:GetChildNode(0)

				Node.Selected = First.Master and First.Selected or First
			else
				Node.Action = Data.Action
				Node.Item   = Data

				Node.Label.Paint = PulseLabel

				if Wanted and Data.Option == Wanted.Option and Data.Name == Wanted.Name then Found.Open = Node end
				if not Found.First then Found.First = Node end
			end
		end
	end

	local function PopulateTree(Tree)
		local Roots, Entries = GetEntries()
		local Wanted = ACF.MenuItemToOpen
		local Found  = {}

		ACF.MenuItemToOpen = nil

		Tree.VBar:SetSize(0, 0)
		Tree:SetLineHeight(19)

		AddNodes(Tree, GetAllowed(Roots, Entries), Wanted, Found)

		local Open = Found.Open or Found.First

		if Open then Tree:SetSelectedItem(Open) end
	end

	local function SetupMenuTree(Menu, Tree)
		Menu.Tree = Tree

		function Tree:OnNodeSelected(Node)
			if self.Selected == Node and not self.Reopen then return end

			self.Reopen = nil

			if Node.Master then
				self:SetSelectedItem(Node.Selected)
				return
			end

			UpdateTree(self, Node)

			local Group = Node:GetParentNode()

			while Group.Master do
				Group.Selected = Node
				Group = Group:GetParentNode()
			end

			self.Selected = Node

			-- Reset new-framework tool state; a new-style page's Action re-sets it below.
			if ACF.Menu then
				ACF.Menu.ActivePage         = nil
				ACF.Menu.ActiveInstructions = nil

				-- Leaving the page drops any link selection (mirrors the old linker's OnExitOp).
				if ACF.Menu.SendLinkClear then ACF.Menu.SendLinkClear() end

				-- Release the framework ghost now (before the next page's op may create its own).
				local Tool = LocalPlayer():GetTool("acf_menu")
				if Tool and Tool.ReleaseMenuGhost then Tool:ReleaseMenuGhost() end
			end

			Menu:ClearTemporal()
			Menu:StartTemporal()

			-- Fixes menu errors just killing everything
			xpcall(function() Node.Action(Menu) end, function(err) ErrorNoHaltWithStack(err) end)

			Menu:EndTemporal()
		end

		PopulateTree(Tree)
	end

	--- Generates the menu used in the main menu tool.
	--- @param Panel panel The base panel to build the menu off of.
	function ACF.CreateSpawnMenu(Panel)
		local Menu = ACF.InitMenuBase(Panel, "SpawnMenu", "acf_reload_spawn_menu")
		local Tree = Menu:AddPanel("DTree")
		SetupMenuTree(Menu, Tree)
	end

	ACF.SetupMenuTree = SetupMenuTree

	local function FindItemNode(Parent, Option, Name)
		for _, Node in ipairs(Parent:GetChildNodes()) do
			local Item = Node.Item

			if Item and Item.Option == Option and Item.Name == Name then return Node end

			if Node.Master then
				local Found = FindItemNode(Node, Option, Name)

				if Found then return Found end
			end
		end
	end

	--- Opens an item of the main menu, rebuilding it if it's already open.
	--- If the menu isn't built yet it opens on that item once it is
	function ACF.OpenMenuItem(Option, Name)
		local Menu = ACF.SpawnMenu
		local Tree = IsValid(Menu) and Menu.Tree

		if not IsValid(Tree) then
			ACF.MenuItemToOpen = { Option = Option, Name = Name }
			return false
		end

		local Node = FindItemNode(Tree:Root(), Option, Name)

		if not Node then return false end

		Tree.Reopen = true
		Tree:SetSelectedItem(Node)

		return true
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

	--- Uses the following hooks:
	-- ACF_PreLoadServerSettings
	-- ACF_OnLoadServerSettings
	-- ACF_PostLoadServerSettings
	-- ACF_PreLoadClientSettings
	-- ACF_OnLoadClientSettings
	-- ACF_PostLoadClientSettings

	for Realm, Destiny in pairs(Settings) do
		local PreHook  = "ACF_PreLoad" .. Realm .. "Settings"
		local OnHook   = "ACF_OnLoad" .. Realm .. "Settings"
		local PostHook = "ACF_PostLoad" .. Realm .. "Settings"
		local Message  = "No %sside settings have been registered."

		local function CreateSection(Menu, Name, Data)
			local Result = hook.Run(PreHook, Name)

			if not Result then return end

			local Base, Section = Menu:AddCollapsible(Name, false)

			function Section:OnToggle(Bool)
				if not Bool then return end
				if self.Created then return end

				local Result = hook.Run(OnHook, Name, Base)

				if not Result then
					Data.Create(Base)
				end

				hook.Run(PostHook, Name, Base)

				self.Created = true
			end
		end

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
				CreateSection(Menu, Name, Data)
			end
		end
	end
end