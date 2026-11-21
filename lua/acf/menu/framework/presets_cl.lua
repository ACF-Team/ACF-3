local ACF           = ACF
local Folder        = "acf/presets"
local MaxNameLength = 48
local Gap           = 4

ACF.Menu = ACF.Menu or {}

local LastLoaded = {} -- [Folder] = preset name, so the list still shows it after the page rebuilds

local function GetFolder(ClassName, Group)
	if not Group then return Folder .. "/" .. ClassName end

	return Folder .. "/" .. ClassName .. "/" .. Group:lower():gsub("[^%w_]", "_")
end

local function GetFile(Name)
	return (Name:lower():gsub("%s", "_")) .. ".json"
end

--- Strips a preset name down to something safe to use as a file name, nil if nothing's left
function ACF.Menu.CleanPresetName(Name)
	if not isstring(Name) then return end

	Name = Name:gsub("[^%w%s%-_]", ""):Trim():sub(1, MaxNameLength)

	return Name ~= "" and Name or nil
end

--- Sorted preset names of an entity class. Group keeps presets of different weapons apart, for example
function ACF.Menu.GetPresets(ClassName, Group)
	local Path  = GetFolder(ClassName, Group)
	local Names = {}

	for _, Name in ipairs(file.Find(Path .. "/*.json", "DATA")) do
		local Saved = ACF.LoadFromFile(Path, Name)

		if istable(Saved) and isstring(Saved.Name) then
			Names[#Names + 1] = Saved.Name
		end
	end

	table.sort(Names, function(A, B) return A:lower() < B:lower() end)

	return Names
end

function ACF.Menu.HasPreset(ClassName, Group, Name)
	return file.Exists(GetFolder(ClassName, Group) .. "/" .. GetFile(Name), "DATA")
end

--- Saved with the entity's version, like dupes, for the compatibility patches
function ACF.Menu.SavePreset(ClassName, Group, Name, Data)
	ACF.SaveToJSON(GetFolder(ClassName, Group), GetFile(Name), {
		Name    = Name,
		Version = ACF.Menu.GetEntityVersion(ClassName),
		Data    = Data,
	})
end

--- The serialized settings saved in a preset and the entity class they're for, nil if it's gone.
--- Presets go through the same compatibility patches as dupes, which can also change the class
function ACF.Menu.LoadPreset(ClassName, Group, Name)
	local Saved = ACF.LoadFromFile(GetFolder(ClassName, Group), GetFile(Name))
	if not istable(Saved) or not istable(Saved.Data) then return end

	return ACF.Menu.PatchSaved(ClassName, Saved.Data, Saved.Version)
end

function ACF.Menu.DeletePreset(ClassName, Group, Name)
	file.Delete(GetFolder(ClassName, Group) .. "/" .. GetFile(Name))
end

local function AddButtons(Row, Control, Buttons)
	Control:Dock(NODOCK)

	for _, Button in ipairs(Buttons) do
		Button:SetParent(Row)
	end

	function Row:PerformLayout(W)
		local H = Control:GetTall()
		local X = W

		for I = #Buttons, 1, -1 do
			X = X - H

			Buttons[I]:SetSize(H, H)
			Buttons[I]:SetPos(X, 0)

			X = X - Gap
		end

		Control:SetPos(0, 0)
		Control:SetWide(X)

		self:SetTall(H)
	end
end

local function MakeButton(Icon, Tooltip, DoClick)
	local Button = vgui.Create("DButton")
	Button:SetText("")
	Button:SetImage(Icon)
	Button:SetTooltip(Tooltip)
	Button.DoClick = DoClick

	return Button
end

--- Adds a row to load, save and delete presets of a context's entity.
--- Options.Group() names the group presets are listed and saved under, nil to list none.
--- Options.Keep lists fields that stay as the menu has them when a preset loads, or is a function returning that list
function ACF.Menu.AddPresets(Menu, Context, Options)
	Options = Options or {}

	local Row   = Menu:AddPanel("ACF_Panel")
	local Combo = Row:AddComboBox()

	local function GetGroup()
		if not Options.Group then return end

		return Options.Group() or false
	end

	local function GetChosen()
		local _, Name = Combo:GetSelected()

		return Name
	end

	function Row:Refresh()
		local Group = GetGroup()
		local Names = Group ~= false and ACF.Menu.GetPresets(Context.ClassName, Group) or {}
		local Last  = LastLoaded[GetFolder(Context.ClassName, Group or nil)]

		Combo:Clear()
		Combo:SetValue(#Names > 0 and "#acf.menu.presets.pick" or "#acf.menu.presets.none")

		for _, Name in ipairs(Names) do
			Combo:AddChoice(Name, Name, Name == Last)
		end
	end

	function Row:SetContext(New)
		if not New or New == Context then return end

		Context = New

		self:Refresh()
	end

	local function Load()
		local Name  = GetChosen()
		local Group = GetGroup()
		if not Name or Group == false then return end

		local Data, ClassName = ACF.Menu.LoadPreset(Context.ClassName, Group, Name)

		if not Data then
			Row:Refresh()
			return
		end

		LastLoaded[GetFolder(Context.ClassName, Group)] = Name

		-- A patch moved it to another kind of entity, so the fields kept from this one don't apply
		if ClassName ~= Context.ClassName then
			ACF.Menu.Copy.ToMenu(ClassName, Data)
			return
		end

		local Current = Context:Serialize()
		local Keep    = Options.Keep

		if isfunction(Keep) then Keep = Keep() end

		for _, Field in ipairs(Keep or {}) do
			Data[Field] = Current[Field]
		end

		ACF.Menu.Copy.ToMenu(ClassName, Data)
	end

	local function Save()
		local Group = GetGroup()
		if Group == false then return end

		Derma_StringRequest("#acf.menu.presets.save", "#acf.menu.presets.save_desc", GetChosen() or "", function(Text)
			local Name = ACF.Menu.CleanPresetName(Text)
			if not Name then return end

			local function Write()
				ACF.Menu.SavePreset(Context.ClassName, Group, Name, Context:Serialize())

				LastLoaded[GetFolder(Context.ClassName, Group)] = Name

				Row:Refresh()
			end

			if not ACF.Menu.HasPreset(Context.ClassName, Group, Name) then return Write() end

			Derma_Query(language.GetPhrase("acf.menu.presets.overwrite"):format(Name), "#acf.menu.presets.save",
				"#acf.menu.presets.yes", Write,
				"#acf.menu.presets.no")
		end, nil, "#acf.menu.presets.save", "#acf.menu.presets.cancel")
	end

	local function Delete()
		local Name  = GetChosen()
		local Group = GetGroup()
		if not Name or Group == false then return end

		Derma_Query(language.GetPhrase("acf.menu.presets.delete_query"):format(Name), "#acf.menu.presets.delete",
			"#acf.menu.presets.yes", function()
				ACF.Menu.DeletePreset(Context.ClassName, Group, Name)
				Row:Refresh()
			end,
			"#acf.menu.presets.no")
	end

	AddButtons(Row, Combo, {
		MakeButton("icon16/folder_go.png", "#acf.menu.presets.load", Load),
		MakeButton("icon16/disk.png", "#acf.menu.presets.save", Save),
		MakeButton("icon16/delete.png", "#acf.menu.presets.delete", Delete),
	})

	Row:Refresh()

	return Row
end
