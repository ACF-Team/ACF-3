local ACF = ACF
ACF.Menu       = ACF.Menu or {}
ACF.Menu.PageRegistry = ACF.Menu.PageRegistry or {}

--- Looks up a registered page by id (used by both realms; the server needs it for func commits).
function ACF.Menu.GetPage(ID)
	return ACF.Menu.PageRegistry[ID]
end

if CLIENT then
	--- Opens a page: marks it active, lazily creates + hydrates its contexts, builds instructions,
	--- and runs its Build function to populate the menu panel.
	function ACF.Menu.OpenPage(Def, Menu)
		ACF.Menu.ActivePage = Def

		if Def.Contexts and not Def._Contexts then
			Def._Contexts = {}

			for Name, ClassName in pairs(Def.Contexts) do
				Def._Contexts[Name] = ACF.Menu.Context(ClassName)
			end

			if Def.LinkContexts then Def.LinkContexts(Def._Contexts) end
		end

		ACF.Menu.ActiveInstructions = ACF.Menu.BuildInstructions(Def)

		if Def.Build then
			Def.Build(Menu, Def._Contexts or {})
		end
	end
end

--- Registers a menu page (see the Def shape above).
function ACF.Menu.RegisterPage(Def)
	Def.ID = Def.ID or (tostring(Def.Category) .. "/" .. tostring(Def.Name))

	if Def.Actions then
		for I, Action in ipairs(Def.Actions) do
			Action._Index = I
		end
	end

	ACF.Menu.PageRegistry[Def.ID] = Def

	if CLIENT then
		-- Adapt onto the existing tree: the node's action opens the page through the framework.
		ACF.AddMenuItem(Def.Order or 1, Def.Category, Def.Name, Def.Icon, function(Menu)
			ACF.Menu.OpenPage(Def, Menu)
		end, Def.Enabled)
	end
end
