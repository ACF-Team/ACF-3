local ACF     = ACF
local Classes = ACF.Classes

ACF.Menu = ACF.Menu or {}

-- Strips a trailing "[]" array marker off a field type.
local function BaseType(TypeStr)
	if TypeStr:sub(-2) == "[]" then return TypeStr:sub(1, -3) end
	return TypeStr
end

-- Unpacks an Options.Min/Max/Decimals entry (a number, a Vector/Angle, or nil) into X/Y/Z pieces.
local function Unpack3(Value, Fallback)
	if Value == nil then return Fallback, Fallback, Fallback end
	if isnumber(Value) then return Value, Value, Value end
	return Value:Unpack()
end

-- Removes a widget's context callback when the widget is destroyed (menu rebuilds), so stale
-- callbacks don't pile up on a long-lived context.
local function BindCleanup(Panel, Context, Field)
	local Old = Panel.OnRemove

	function Panel:OnRemove()
		if Old then Old(self) end
		Context:RemoveCallback(self, Field)
	end
end

-- =============================================================================================
-- Combo selection persistence. Two-level "pick a type" combos (the dynamic-class pages) default to
-- their first option on every open, which both resets the UI and clobbers the persisted context.
-- These helpers let a page restore a combo's last selection from page UI state instead, and save it
-- on change. IdOf(Data) maps a choice's backing data to a stable string id; for the common case of
-- class-object combos that's the type's FQN.
-- =============================================================================================

--- Selects the combo option whose backing data's IdOf() matches the saved page-UI value; falls back
--- to option 1 (so first-time users and removed types behave exactly as before). Call this in place
--- of `Combo:ChooseOptionID(1)`, after the combo has been populated.
function ACF.Menu.RestoreCombo(Combo, PageID, Key, IdOf)
	local Choices = Combo.ListData and Combo.ListData.Choices
	if not (Choices and Choices[1] ~= nil) then return end

	local Saved  = ACF.Menu.GetUIState(PageID, Key)
	local Target = 1

	if Saved ~= nil and IdOf then
		for I, Data in ipairs(Choices) do
			if IdOf(Data) == Saved then
				Target = I
				break
			end
		end
	end

	Combo:ChooseOptionID(Target)
end

function ACF.Menu.RestoreClassCombo(Combo, PageID, Key)
	ACF.Menu.RestoreCombo(Combo, PageID, Key, Classes.GetTypeName)
end

function ACF.Menu.SaveClassCombo(PageID, Key, Data)
	ACF.Menu.SetUIState(PageID, Key, Classes.GetTypeName(Data))
end

function ACF.Menu.PopulateCombo(Combo, List, Member, IconMember)
	local Handler  = Combo.OnSelect
	Combo.OnSelect = function() end
	ACF.LoadSortedList(Combo, List, Member, IconMember)
	Combo.OnSelect = Handler
end

--- Populates a class-object combo (like ACF.LoadSortedList) and selects the choice persisted under
--- (PageID, Key) instead of defaulting to the first option. This is the correct replacement for a
--- `LoadSortedList(...)` + `RestoreClassCombo(...)` pair: ACF.LoadSortedList auto-selects its first
--- entry, and AddChoice's select flag FIRES OnSelect -- so the page's select handler would run for the
--- wrong type (rebuilding sub-controls, clamping values) and SaveClassCombo would overwrite the saved
--- selection before RestoreClassCombo could read it. We suppress OnSelect across population, then fire
--- it exactly once for the restored (or, first-time, the first) choice.
function ACF.Menu.LoadClassCombo(Combo, List, Member, IconMember, PageID, Key)
	local Saved = ACF.Menu.GetUIState(PageID, Key)

	ACF.Menu.PopulateCombo(Combo, List, Member, IconMember)

	local Choices = Combo.ListData and Combo.ListData.Choices
	if not (Choices and Choices[1] ~= nil) then return end

	local Target = 1
	if Saved ~= nil then
		for I, Data in ipairs(Choices) do
			if Classes.GetTypeName(Data) == Saved then
				Target = I
				break
			end
		end
	end

	Combo:ChooseOptionID(Target)
end

-- =============================================================================================
-- Per-type builders. Each writes user input into the context and reflects external context changes
-- back into the widget, using a _Suppress guard to avoid feedback loops.
-- =============================================================================================

local function AddNumber(Menu, Context, Field, Options, Title, Overrides)
	local Min = Options.Min or 0
	local Max = Options.Max or 100
	local Dec = Options.Decimals or 0

	local Panel
	if Overrides.wang then
		Panel = Menu:AddNumberWang(Title, Min, Max, Dec)
	else
		Panel = Menu:AddSlider(Title, Min, Max, Dec)
	end

	Panel:SetValue(Context:Get(Field) or Options.Default or Min)

	function Panel:OnValueChanged(Value)
		if self._Suppress then return end
		Context:Set(Field, Value)
	end

	Context:OnChange(Panel, Field, function(_, _, Value)
		if not IsValid(Panel) then return end
		Panel._Suppress = true
		Panel:SetValue(Value)
		Panel._Suppress = false
	end)

	BindCleanup(Panel, Context, Field)

	return Panel
end

local function AddBoolean(Menu, Context, Field, Options, Title)
	local Panel = Menu:AddCheckBox(Title)
	Panel:SetValue(Context:Get(Field) and true or  Options.Default or false)

	function Panel:OnChange(Value)
		if self._Suppress then return end
		Context:Set(Field, Value and true or false)
	end

	Context:OnChange(Panel, Field, function(_, _, Value)
		if not IsValid(Panel) then return end
		Panel._Suppress = true
		Panel:SetValue(Value and true or false)
		Panel._Suppress = false
	end)

	BindCleanup(Panel, Context, Field)

	return Panel
end

local function AddString(Menu, Context, Field, Options, Title, Overrides)
	local Choices = Overrides.Choices or Options.Choices

	if Choices then
		local Combo = Menu:AddComboBox()

		for _, Choice in ipairs(Choices) do
			-- Accept either "value" strings or { Value, Label } pairs.
			if istable(Choice) then
				Combo:AddChoice(Choice.Label or Choice.Value, Choice.Value)
			else
				Combo:AddChoice(Choice, Choice)
			end
		end

		function Combo:OnSelect(_, _, Data)
			if self._Suppress then return end
			Context:Set(Field, Data)
		end

		Context:OnChange(Combo, Field, function(_, _, Value)
			if not IsValid(Combo) then return end
			Combo._Suppress = true
			Combo:SetValue(tostring(Value))
			Combo._Suppress = false
		end)

		BindCleanup(Combo, Context, Field)

		return Combo
	end

	local _, _, Entry = Menu:AddTextEntry(Title)
	Entry:SetValue(tostring(Context:Get(Field) or ""))

	function Entry:OnValueChange(Value)
		if self._Suppress then return end
		Context:Set(Field, Value)
	end

	Context:OnChange(Entry, Field, function(_, _, Value)
		if not IsValid(Entry) then return end
		Entry._Suppress = true
		Entry:SetValue(tostring(Value or ""))
		Entry._Suppress = false
	end)

	BindCleanup(Entry, Context, Field)

	return Entry
end

local function AddVectorLike(Menu, Context, Field, Options, Title, IsAngle)
	local MinX, MinY, MinZ = Unpack3(Options.Min, 0)
	local MaxX, MaxY, MaxZ = Unpack3(Options.Max, 100)
	local DecX, DecY, DecZ = Unpack3(Options.Decimals, 2)

	local Axes = {
		{ Key = "x", Min = MinX, Max = MaxX, Dec = DecX },
		{ Key = "y", Min = MinY, Max = MaxY, Dec = DecY },
		{ Key = "z", Min = MinZ, Max = MaxZ, Dec = DecZ },
	}

	local Make = IsAngle and Angle or Vector

	for I, Axis in ipairs(Axes) do
		local Slider = Menu:AddSlider(Title .. " " .. Axis.Key:upper(), Axis.Min, Axis.Max, Axis.Dec)
		local Current = Context:Get(Field)
		Slider:SetValue(Current and Current[Axis.Key] or 0)

		function Slider:OnValueChanged(Value)
			if self._Suppress then return end
			local V = Context:Get(Field)
			V = (V and (IsAngle and isangle(V) or isvector(V))) and Make(V.x, V.y, V.z) or Make(0, 0, 0)
			V[Axis.Key] = Value
			Context:Set(Field, V)
		end

		Context:OnChange(Slider, Field, function(_, _, Value)
			if not IsValid(Slider) then return end
			if not Value then return end
			Slider._Suppress = true
			Slider:SetValue(Value[Axis.Key])
			Slider._Suppress = false
		end)

		BindCleanup(Slider, Context, Field)
		Axes[I].Slider = Slider
	end

	return Axes
end

-- Nested class-type field: a subtype combobox + a submenu of the chosen subtype's controls. This is
-- the generalization of the old ACF.Classes.CreateTypeSelector, writing into ctx:Set instead of
-- ClientData. Classes that expose a custom CLASS.CreateMenu get it (compat escape hatch); otherwise
-- the subtype's own menu fields are rendered automatically via a sub-context.
local function AddClassField(Menu, Context, Field, FieldDef)
	local Options  = FieldDef.Options or {}
	local BaseName = BaseType(FieldDef.Type)
	local SubTypes = Classes.GetSubtypes(BaseName)

	local Combo    = Menu:AddComboBox()
	local SubPanel = Menu:AddPanel("ACF_Panel")
	local Handle   = { ComboBox = Combo, SubPanel = SubPanel, OnTypeChanged = nil }

	ACF.LoadSortedList(Combo, SubTypes, "Name", "Icon")

	local function BuildSub(TypeObj, Instance)
		SubPanel:ClearAll()

		if TypeObj.CreateMenu then
			-- Legacy per-type menu: (Panel, DataBag, Push). The live instance doubles as the data bag;
			-- Push notifies the owning context so persistence + cross-field callbacks fire.
			TypeObj.CreateMenu(SubPanel, Instance, function() Context:Set(Field, Instance) end)
		else
			local Sub = ACF.Menu.SubContext(Context, Field)
			if Sub then
				for _, F in ipairs(Classes.GetTypeFields(TypeObj)) do
					if F.Menu then ACF.Menu.AddField(SubPanel, Sub, F.Name) end
				end
			end
		end

		if Handle.OnTypeChanged then Handle.OnTypeChanged(TypeObj) end
		SubPanel:InvalidateParent()
	end

	function Combo:OnSelect(_, _, TypeObj)
		if self.Selected == TypeObj then return end
		self.Selected = TypeObj

		-- Swap the nested instance to the newly chosen subtype, carrying over any overlapping fields.
		local Current = Context:Get(Field)
		local NewInst = TypeObj()

		if Current and Current.GetType then
			for _, F in ipairs(Classes.GetTypeFields(TypeObj)) do
				local Value = rawget(Current, F.Name)
				if Value ~= nil then NewInst[F.Name] = Value end
			end
		end

		Context:Set(Field, NewInst)
		BuildSub(TypeObj, NewInst)
	end

	-- Initial selection: reflect the context's current nested instance (post-hydrate), or fall back
	-- to the field's default subtype. Pre-set Combo.Selected so ChooseOptionID's OnSelect early-returns
	-- (we must NOT replace the hydrated instance on first render).
	local CurInst = Context:Get(Field)
	local CurType = (CurInst and CurInst.GetType) and CurInst:GetType() or Classes.GetTypeByName(Options.InstantiateTypeForDefault)

	if not (CurInst and CurInst.GetType) and CurType then
		CurInst = CurType()
		Context:Set(Field, CurInst, true) -- silent: seeding a default, not a user edit
	end

	if CurType and Combo.ListData then
		local WantName = Classes.GetTypeName(CurType)
		local SelectIdx, Selected = 1, nil

		for I, TypeObj in ipairs(Combo.ListData.Choices) do
			if Classes.GetTypeName(TypeObj) == WantName then
				SelectIdx, Selected = I, TypeObj
				break
			end
		end

		Combo.Selected = Selected or CurType
		Combo:ChooseOptionID(SelectIdx)

		if Selected then BuildSub(Selected, CurInst) end
	end

	return Handle
end

-- =============================================================================================
-- Public dispatcher.
-- =============================================================================================

--- Builds and binds a control for `FieldName` on `Context`, dispatched from the field's metadata.
--- Overrides: { Title = "#phrase", wang = true, Choices = {...} }.
--- Returns the created panel/handle so callers can further customize it.
function ACF.Menu.AddField(Menu, Context, FieldName, Overrides)
	Overrides = Overrides or {}

	local FieldDef = Context:FieldDef(FieldName)
	if not FieldDef then
		ErrorNoHaltWithStack("ACF.Menu.AddField: no field '" .. tostring(FieldName) ..
			"' on class '" .. tostring(Context.ClassName) .. "'\n")
		return
	end

	local ElemType = BaseType(FieldDef.Type)
	local Options  = FieldDef.Options or {}
	local Title    = Overrides.Title or FieldName

	if ElemType == "Number" then
		return AddNumber(Menu, Context, FieldName, Options, Title, Overrides)
	elseif ElemType == "Boolean" then
		return AddBoolean(Menu, Context, FieldName, Options, Title)
	elseif ElemType == "String" then
		return AddString(Menu, Context, FieldName, Options, Title, Overrides)
	elseif ElemType == "Vector" then
		return AddVectorLike(Menu, Context, FieldName, Options, Title, false)
	elseif ElemType == "Angle" then
		return AddVectorLike(Menu, Context, FieldName, Options, Title, true)
	elseif Classes.GetTypeByName(ElemType) then
		return AddClassField(Menu, Context, FieldName, FieldDef)
	end

	ErrorNoHaltWithStack("ACF.Menu.AddField: unsupported field type '" .. tostring(FieldDef.Type) ..
		"' for '" .. tostring(FieldName) .. "'\n")
end
