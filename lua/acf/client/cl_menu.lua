local Options = {}
local Lookup = {}
local Count = 0

do -- Menu population functions
	local function DefaultAction(Menu)
		Menu:AddTitle("There's nothing here.")
		Menu:AddLabel("This option is either a work in progress or something isn't working as intended.")
	end

	local function MissilesMenu(Menu)
		Menu:AddTitle("ACF-3 Missiles is not installed.")
		Menu:AddLabel("This option requires ACF-3 Missiles to be installed. You can get it here:")

		local Link = Menu:AddButton("ACF-3 Missiles Repository")

		function Link:DoClickInternal()
			gui.OpenURL("https://github.com/TwistedTail/ACF-3-Missiles")
		end
	end

	function ACF.AddOption(Name, Icon)
		if not Name then return end

		if not Lookup[Name] then
			Count = Count + 1

			Options[Count] = {
				Name = Name,
				Icon = "icon16/" .. (Icon or "plugin") .. ".png",
				Lookup = {},
				List = {},
				Count = 0,
			}

			Lookup[Name] = Options[Count]
		else
			local Option = Lookup[Name]

			Option.Icon = "icon16/" .. (Icon or "plugin") .. ".png"
		end
	end

	function ACF.AddOptionItem(Option, Name, Icon, Action)
		if not Option then return end
		if not Name then return end
		if not Lookup[Option] then return end

		local Items = Lookup[Option]
		local Item = Items.Lookup[Name]

		if not Item then
			Items.Count = Items.Count + 1

			Items.List[Items.Count] = {
				Icon = "icon16/" .. (Icon or "plugin") .. ".png",
				Action = Action or DefaultAction,
				Name = Name,
			}

			Items.Lookup[Name] = Items.List[Items.Count]
		else
			Item.Icon = "icon16/" .. (Icon or "plugin") .. ".png"
			Item.Action = Action or DefaultAction
			Item.Name = Name
		end
	end

	-- Small workaround to give the correct order to the items
	ACF.AddOption("About the Addon", "information")
	ACF.AddOptionItem("About the Addon", "Online Wiki", "book_open")
	ACF.AddOptionItem("About the Addon", "Updates", "newspaper")
	ACF.AddOptionItem("About the Addon", "Contact Us", "feed")

	ACF.AddOption("Entities", "brick")
	ACF.AddOptionItem("Entities", "Weapons", "gun")
	ACF.AddOptionItem("Entities", "Missiles", "wand", MissilesMenu)
	ACF.AddOptionItem("Entities", "Engines", "car")
	ACF.AddOptionItem("Entities", "Gearboxes", "cog")
	ACF.AddOptionItem("Entities", "Sensors", "transmit")
	ACF.AddOptionItem("Entities", "Components", "drive")
end

do -- ACF Menu context panel
	local function PopulateTree(Tree)
		local First

		Tree.BaseHeight = Count + 0.5

		for _, Option in ipairs(Options) do
			local Parent = Tree:AddNode(Option.Name, Option.Icon)
			local SetExpanded = Parent.SetExpanded

			Parent.Action = Option.Action
			Parent.Master = true
			Parent.Count = Option.Count
			Parent.SetExpanded = function(Panel, Bool)
				if not Panel.AllowExpand then return end

				SetExpanded(Panel, Bool)

				Panel.AllowExpand = nil
			end

			for _, Data in ipairs(Option.List) do
				local Child = Parent:AddNode(Data.Name, Data.Icon)

				Child.Action = Data.Action
				Child.Parent = Parent

				if not Parent.Selected then
					Parent.Selected = Child

					if not First then
						Tree:SetSelectedItem(Child)
						First = true
					end
				end
			end
		end
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

	function ACF.BuildContextPanel(Panel)
		local Menu = ACF.Menu

		if not IsValid(Menu) then
			Menu = vgui.Create("ACF_Panel")
			Menu.Panel = Panel

			Panel:AddItem(Menu)

			ACF.Menu = Menu
		else
			Menu:ClearAllTemporal()
			Menu:ClearAll()
		end

		local Reload = Menu:AddButton("Reload Menu")
		Reload:SetTooltip("You can also type 'acf_reload_menu' in console.")
		function Reload:DoClickInternal()
			ACF.BuildContextPanel(Panel)
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

			ACF.SetToolMode("acf_menu2", "Main", "Idle")

			Menu:ClearTemporal()
			Menu:StartTemporal()

			Node.Action(Menu)

			Menu:EndTemporal()
		end

		PopulateTree(Tree)
	end
end
