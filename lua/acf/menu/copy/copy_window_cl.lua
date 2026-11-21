local ACF          = ACF
local Classes      = ACF.Classes
local Copy         = ACF.Menu.Copy
local IncludedIcon = "icon16/accept.png"
local SkippedIcon  = "icon16/delete.png"
local Unbounded    = 1e6
local Gap          = 4
local Padding      = 8

local function GetTitle(Field)
	return Field.Options.Title or Field.Name
end

local function GetPrintName(ClassName)
	local Stored = scripted_ents.GetStored(ClassName)
	local Name   = Stored and Stored.t.PrintName

	return Name and Name ~= "" and Name or ClassName
end

-- Children finish their layout after the parent sized itself to them
local function FollowHeight(Panel)
	local Layout = Panel.PerformLayout

	function Panel:PerformLayout(W, H)
		if Layout then Layout(self, W, H) end

		local Tall = self:GetTall()
		if Tall == self.LastTall then return end

		self.LastTall = Tall

		local Parent = self:GetParent()
		if IsValid(Parent) then Parent:InvalidateLayout() end
	end
end

-- Nested panels go a bit darker each level
local function PaintInset(_, W, H)
	surface.SetDrawColor(0, 0, 0, 25)
	surface.DrawRect(0, 0, W, H)
end

local BuildFields

local function AddArrayEditor(Editor, Context, Field)
	local Value = Context:Get(Field.Name)

	Editor:AddLabel(GetTitle(Field))

	if Field.Type ~= "Number[]" then
		Editor:AddLabel(language.GetPhrase("acf.menu.copy.values"):format(istable(Value) and #Value or 0))
		return
	end

	local Options = Field.Options

	for I in ipairs(Value or {}) do
		local Wang = Editor:AddNumberWang(tostring(I), Options.Min or -Unbounded, Options.Max or Unbounded, Options.Decimals or 2)
		Wang:SetValue(Value[I])

		function Wang:OnValueChanged(New)
			local List = table.Copy(Context:Get(Field.Name) or {})
			List[I] = New

			Context:Set(Field.Name, List)
		end
	end
end

-- Returns the panel that should go dim when the field is skipped
local function AddEditor(Editor, Entry, Context, Path, Field)
	local Name    = Field.Name
	local Options = Field.Options

	if Copy.GetNestedClass(Field) then
		Editor:AddLabel(GetTitle(Field))

		local Handle = Editor:AddField(Context, Name, {
			BuildFields = function(SubPanel, SubContext)
				SubPanel:DockPadding(8, 6, 6, 0)
				SubPanel.Paint = PaintInset

				FollowHeight(SubPanel)

				BuildFields(SubPanel, Entry, SubContext, Path .. ".")
			end,
		})

		-- Sub-fields still get copied with the type skipped, only the type combo goes dim
		return Handle and Handle.ComboBox
	end

	if Field.Type:sub(-2) == "[]" then
		AddArrayEditor(Editor, Context, Field)
		return Editor
	end

	local Overrides = { Title = GetTitle(Field) }

	-- No range to put on a slider
	if Field.Type == "Number" and (Options.Min == nil or Options.Max == nil) then
		Overrides.wang     = true
		Overrides.Min      = Options.Min or -Unbounded
		Overrides.Max      = Options.Max or Unbounded
		Overrides.Decimals = Options.Decimals or 2
	end

	Editor:AddField(Context, Name, Overrides)

	return Editor
end

local function AddFieldRow(Menu, Entry, Context, Path, Field)
	local Row = Menu:AddPanel("ACF_Panel")
	Row:DockMargin(0, 0, 0, Gap)

	local Toggle = Row:Add("DImageButton")
	Toggle:SetSize(16, 16)
	Toggle:SetPos(0, 4)
	Toggle:SetTooltip("#acf.menu.copy.toggle")

	local Editor = Row:Add("ACF_Panel")
	Editor:Dock(TOP)
	Editor:DockMargin(16 + Gap * 2, 0, 0, 0)

	FollowHeight(Row)
	FollowHeight(Editor)

	local Dimmed = AddEditor(Editor, Entry, Context, Path, Field)

	local function Refresh()
		if not IsValid(Toggle) then return end

		local Included = not Entry.Skip[Path]

		Toggle:SetImage(Included and IncludedIcon or SkippedIcon)

		if IsValid(Dimmed) then
			Dimmed:SetAlpha(Included and 255 or 90)
			Dimmed:SetMouseInputEnabled(Included)
		end
	end

	function Toggle:DoClick()
		Entry.Skip[Path] = not Entry.Skip[Path] or nil
		Refresh()
	end

	Entry.Rows[#Entry.Rows + 1] = Refresh

	Refresh()
end

function BuildFields(Menu, Entry, Context, Prefix)
	for _, Field in ipairs(Classes.GetTypeFields(Context.Class)) do
		if Copy.IsCopyable(Field) then
			AddFieldRow(Menu, Entry, Context, Prefix .. Field.Name, Field)
		end
	end
end

local function SetAllSkipped(Entry, Skipped)
	local Context = Entry.Context

	Entry.Skip = {}

	if Skipped then
		for _, Path in ipairs(Copy.GetPaths(Context.Class, Context.Instance)) do
			Entry.Skip[Path] = true
		end
	end

	for _, Refresh in ipairs(Entry.Rows) do Refresh() end
end

local function AddAllButtons(Window, Entry)
	local Row     = Window:Add("Panel")
	local Include = Row:Add("DButton")
	local Skip    = Row:Add("DButton")

	Row:Dock(TOP)
	Row:SetTall(22)

	Include:SetText("#acf.menu.copy.include_all")
	Skip:SetText("#acf.menu.copy.skip_all")

	function Include:DoClick() SetAllSkipped(Entry, false) end
	function Skip:DoClick() SetAllSkipped(Entry, true) end

	function Row:PerformLayout(W, H)
		local Half = (W - Gap) * 0.5

		Include:SetPos(0, 0)
		Include:SetSize(Half, H)
		Skip:SetPos(Half + Gap, 0)
		Skip:SetSize(Half, H)
	end
end

--- Opens a window to pick which of an entity's settings go into the menu, and change them first
function Copy.OpenWindow(ClassName, Data)
	if IsValid(Copy.Window) then Copy.Window:Close() end

	local Context = ACF.Menu.Context(ClassName, false)
	if not Context then return end

	Context:Hydrate(Data)

	local Entry  = { Context = Context, Skip = {}, Rows = {} }
	local Window = vgui.Create("DFrame")

	Window:SetSize(420, math.min(640, ScrH() * 0.8))
	Window:SetMinWidth(300)
	Window:SetMinHeight(240)
	Window:SetSizable(true)
	Window:SetTitle(language.GetPhrase("acf.menu.copy.window_title"):format(GetPrintName(ClassName)))
	Window:DockPadding(Padding, 24 + Gap, Padding, Padding)
	Window:Center()
	Window:MakePopup()

	Copy.Window = Window

	AddAllButtons(Window, Entry)

	local Paste = Window:Add("DButton")
	Paste:Dock(BOTTOM)
	Paste:SetTall(28)
	Paste:SetFont("ACF_Control")
	Paste:SetText("#acf.menu.copy.to_menu")

	function Paste:DoClick()
		Copy.ToMenu(ClassName, Context:Serialize(), Entry.Skip)
		Window:Close()
	end

	local Back = Window:Add("DPanel")
	Back:Dock(FILL)
	Back:DockMargin(0, Gap, 0, Gap)

	local Scroll = Back:Add("DScrollPanel")
	Scroll:Dock(FILL)

	local Menu = Scroll:Add("ACF_Panel")
	Menu:Dock(TOP)
	Menu:DockPadding(Padding, Padding, Padding, 0)

	BuildFields(Menu, Entry, Context, "")

	return Window
end
