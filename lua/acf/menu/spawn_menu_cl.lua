
--- Initializes an ACF menu base panel on the provided panel.
--- @param Panel any The panel to add the base panel to
--- @param Command string The command to run to reload the menu
--- @param CreateMenu string The name of the function to call to create the menu (on the ACF table)
function ACF.InitMenuReloadableBase(Panel, Command, CreateMenu)
	local BasePanel = vgui.Create("ACF_Panel", Panel)

	-- Contains the reload button
	BasePanel:AddMenuReload(Command)

	-- Actual menu exists inside this panel
	local MenuPanel = BasePanel:AddPanel("ACF_Panel")

	-- Add the console command to reload the menu
	concommand.Add(Command, function()
		MenuPanel:ClearChildren()
		ACF[CreateMenu](MenuPanel)
	end)

	-- Create the menu for the first time
	ACF[CreateMenu](MenuPanel)

	return BasePanel
end

ACF.MainMenuLookup = ACF.MainMenuLookup or {}
--- Adds a menu item to the main menu lookup.
function ACF.AddMenuItem(Order, Name, Icon, Action, Parent, Select)
	ACF.MainMenuLookup[Name] = {
		Order = Order,
		Name = Name,
		Icon = Icon,
		Action = Action,
		Parent = Parent,
		Children = {},
		Select = Select,
	}
end

--- Creates the main menu for ACF given an existing ACF_Panel
function ACF.CreateMainMenu(Menu)
	-- Add test elements
	local Tree = Menu:AddPanel("DTree")
	Tree:SetSize(300, 400)

	local Clearable = Menu:AddPanel("ACF_Panel")

	-- Build a forest from the flat lookup table (to deal with hot loading)
	local Lookup = table.Copy(ACF.MainMenuLookup)
	for _, node in pairs(Lookup) do
		if Lookup[node.Parent] then
			table.insert(Lookup[node.Parent].Children, node)
			table.sort(Lookup[node.Parent].Children, function(a, b) return a.Order < b.Order end)
		end
	end

	local function DefaultAction(Panel)
		Panel:AddLabel("This menu has not been implemented yet.")
	end

	local function ExpandRecurseSmooth(Node, Expand)
		Node:SetExpanded(Expand)
		for _, Child in pairs(Node:GetChildNodes()) do
			ExpandRecurseSmooth(Child, Expand)
		end
	end

	-- Handles what happens when a node is selected
	function Tree:UpdateTree(Old, New)
		if Old == New then return end

		ExpandRecurseSmooth(New, true)

		-- Collapse every other ancestor node
		for _, Node in pairs(Tree.Children) do
			if Node ~= New.Ancestor then
				ExpandRecurseSmooth(Node, false)
			end
		end

		local NodeData = New.NodeData or {}

		-- Clear the temporary menu panel and load the menu
		Clearable:ClearChildren()
		Clearable:AddTitle(NodeData.Name)

		if NodeData.Action then NodeData.Action(Clearable)
		else DefaultAction(Clearable) end

		Clearable:InvalidateLayout(true)
		Clearable:SizeToChildren(true, true)
	end

	function Tree:OnNodeSelected(Node)
		if self.Selected == Node then return end

		self:UpdateTree(self.Selected, Node)

		self.Selected = Node
	end

	-- Recursive function to add nodes and their children
	function AddNodeWithChildren(DTree, ParentNode, NodeData)
		local Node = ParentNode:AddNode(NodeData.Name, NodeData.Icon)
		Node.NodeData = NodeData

		-- An ancestor is any node added directly to the tree
		if ParentNode == DTree then
			Node.Ancestor = Node
			DTree.Children = DTree.Children or {}
			table.insert(DTree.Children, Node)
		end

		Node.Ancestor = Node.Ancestor or ParentNode.Ancestor

		if NodeData.Select then DTree.ToSelect = Node end

		-- Recursively add children
		if NodeData.Children then
			for _, ChildData in ipairs(NodeData.Children) do
				AddNodeWithChildren(DTree, Node, ChildData)
			end
		end
		return Node
	end

	-- Add all top-level nodes
	for _, NodeData in ipairs(Lookup.Base.Children) do
		AddNodeWithChildren(Tree, Tree, NodeData):ExpandRecurse(true)
	end

	if Tree.ToSelect then Tree:SetSelectedItem(Tree.ToSelect) end

	return Tree
end

--- Returns a function that creates a menu for the specified entity class
--- Make sure a data var scope for the EntityClass has been created before calling this.
function ACF.EntityMenuCallback(EntityClass)
	local ClassData = baseclass.Get( EntityClass )
	return function(MenuPanel)
		ACF.SetDataVar("SpawnClass", "ToolGun", EntityClass)

		MenuPanel:AddLabel(ClassData.ACF_Menu_Description or "No description available.")

		local Base = MenuPanel:AddCollapsible("Settings")
		Base:AddPresetsBar(EntityClass)
		Base:AddModelPreview(ClassData.ACF_Menu_Model or "models/hunter/blocks/cube025x025x025.mdl")
		ACF.CreatePanelsFromDataVars(Base, EntityClass)
	end
end