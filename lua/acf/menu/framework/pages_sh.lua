local ACF = ACF
ACF.Menu       = ACF.Menu or {}
ACF.Menu.PageRegistry = ACF.Menu.PageRegistry or {}

--- Looks up a registered page by id (used by both realms; the server needs it for func commits).
function ACF.Menu.GetPage(ID)
	return ACF.Menu.PageRegistry[ID]
end

if CLIENT then
	local function CreateContexts(Def)
		if not Def.Contexts or Def._Contexts then return end

		Def._Contexts = {}

		for Name, ClassName in pairs(Def.Contexts) do
			Def._Contexts[Name] = ACF.Menu.Context(ClassName)
		end

		if Def.LinkContexts then Def.LinkContexts(Def._Contexts) end
	end

	function ACF.Menu.GetPageContext(Def, Name)
		CreateContexts(Def)

		return Def._Contexts and Def._Contexts[Name]
	end

	--- The page that edits ClassName and the name of its context for it.
	--- Pages can turn down data with Def.AcceptsCopy(ClassName, Data)
	function ACF.Menu.FindPage(ClassName, Data)
		local Found, FoundName

		for _, Def in pairs(ACF.Menu.PageRegistry) do
			for Name, Class in pairs(Def.Contexts or {}) do
				if Class ~= ClassName then continue end
				if Def.AcceptsCopy and not Def.AcceptsCopy(ClassName, Data) then continue end
				if Found and (Found.Order or 1) <= (Def.Order or 1) then continue end

				Found, FoundName = Def, Name
			end
		end

		return Found, FoundName
	end

	local function CollectTypes(Instance, Out)
		for _, Value in pairs(Instance) do
			if istable(Value) and Value.GetType then
				Out[#Out + 1] = Value:GetType()

				CollectTypes(Value, Out)
			end
		end

		return Out
	end

	--- Loads serialized data into one of a page's contexts, then opens the page on it.
	--- Pages keeping their own state can match it up in Def.PrepareCopy(ContextName, Data, Context), which runs before the data goes in
	function ACF.Menu.OpenPageWith(Def, ContextName, Data)
		local Context = ACF.Menu.GetPageContext(Def, ContextName)
		if not Context then return false end

		if Def.PrepareCopy then Def.PrepareCopy(ContextName, Data, Context) end

		Context:Hydrate(Data)
		ACF.Menu.QueuePersist(Context)

		Def._Pending = { Context = Context, Data = Data }

		return true
	end

	--- Opens a page: marks it active, lazily creates + hydrates its contexts, builds instructions,
	--- and runs its Build function to populate the menu panel.
	function ACF.Menu.OpenPage(Def, Menu)
		ACF.Menu.ActivePage = Def

		CreateContexts(Def)

		ACF.Menu.ActiveInstructions = ACF.Menu.BuildInstructions(Def)

		local Pending = Def._Pending

		Def._Pending = nil

		-- Type combos pick what was loaded in instead of their saved choice
		if Pending then ACF.Menu.PreferredTypes = CollectTypes(Pending.Context.Instance, {}) end

		for _, Context in pairs(Def._Contexts or {}) do
			Context:RemovePanelCallbacks()
		end

		if Def.Build then
			ProtectedCall(Def.Build, Menu, Def._Contexts or {})
		end

		if not Pending then return end

		ACF.Menu.PreferredTypes = nil

		-- Combo handlers reset some fields while the page builds
		Pending.Context:Hydrate(Pending.Data)
		ACF.Menu.QueuePersist(Pending.Context)
	end
end

local CopyActions = {
	{ Bind = "alt+left",       Commit = "copy",              Desc = "Copy the entity you're aiming at into the menu." },
	{ Bind = "alt+shift+left", Commit = "copy", Pick = true, Desc = "Pick what to copy from the entity you're aiming at." },
}

-- After the page's own left click actions
local function AddCopyActions(Actions)
	local Index = 1

	for I, Action in ipairs(Actions) do
		if Action.Bind and Action.Bind:find("left", 1, true) then Index = I + 1 end
	end

	for I, Action in ipairs(CopyActions) do
		table.insert(Actions, Index + I - 1, Action)
	end
end

--- Registers a menu page (see the Def shape above).
function ACF.Menu.RegisterPage(Def)
	Def.ID = Def.ID or (tostring(Def.Category) .. "/" .. tostring(Def.Name))

	if Def.Contexts and Def.Actions then AddCopyActions(Def.Actions) end

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
