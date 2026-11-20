local ACF     = ACF
local Overlay = ACF.Overlay

local ROW_HEIGHT   = 24
local GAP          = 4
local BAR_HEIGHT   = 30
local SWATCH_WIDTH = 8
local COUNT_WIDTH  = 56
local MAX_NAME     = 24 -- Same as the KindName field
local DIVIDER_GRAB = 6 -- Pixels either side of a divider that pick it up
local NUMBER_FONT  = "DermaDefault"
local ENTRY_FONT   = "ACF_Control"
local BAR_BACKDROP = Color(30, 30, 30)
local ROW_FILL     = Color(0, 0, 0, 14)
local ROW_SELECTED = Color(60, 130, 220, 70)
local ROW_INVALID  = Color(220, 60, 60, 60)

-- A crate's kinds of rounds as a list, with a bar to split the crate between them by dragging dividers.
-- Only shows and reports, whoever owns it decides what an edit does.
--   Kinds: { Name, AutoName, Icon, Count, OverrideTracerColor, TracerColor, HasSmoke, OverrideSmokeColor, SmokeColor,
--   Invalid, Locked } top first. Invalid is the reason the crate can't hold it, those rows sit out of the bar
--   Callbacks: OnSelectRound(Index), OnAddRound(DupeOf), OnRemoveRound(Index), OnMoveRound(Index, Step),
--   OnCountsChanged(Counts), OnCountTyped(Index, Value), OnRename(Index, Name),
--   OnColor(Index, Which = "Tracer" or "Smoke", Override, Packed), OnLockRound(Index, Locked).
--   Not OnRemove and the like, those are vgui's own
local PANEL = {}

function PANEL:Init()
	self.Kinds    = {}
	self.Rows     = {}
	self.Capacity = 1
	self.Selected = 1
	self.MaxKinds = ACF.MaxRoundKinds
	self.CanAdd   = true
	self.BarData  = {}

	self:CreateBar()

	local AddButton = self:Add("DButton")
	AddButton:SetText("Add Round")
	AddButton:SetFont(ENTRY_FONT)
	AddButton:SetImage("icon16/add.png")
	AddButton:SetTooltip("Adds a copy of the selected round, change its type and settings below")

	function AddButton.DoClick()
		if self.OnAddRound then self:OnAddRound(self.Selected) end
	end

	self.AddButton = AddButton
end

-- The rows that take part in the bar, invalid ones don't
function PANEL:GetValidRows()
	local Valid = {}

	for Index, Kind in ipairs(self.Kinds) do
		if not Kind.Invalid then Valid[#Valid + 1] = Index end
	end

	return Valid
end

function PANEL:GetBarHeight()
	return Overlay.GetSegmentBarHeight(Overlay.SurfacePainter, BAR_HEIGHT, NUMBER_FONT)
end

do -- MARK: Bar
	-- Rounds before the divider after a section
	function PANEL:Boundary(Section)
		local Counts, Sum = self.BarCounts, 0

		for I = 1, Section do Sum = Sum + Counts[I] end

		return Sum
	end

	-- Moves a divider to sit after the given number of rounds, every kind keeping a round
	function PANEL:MoveDivider(Section, Rounds)
		local Counts = self.BarCounts
		local Low    = self:Boundary(Section - 1) + 1
		local High   = self:Boundary(Section + 1) - 1
		local Delta  = math.Clamp(math.Round(Rounds), Low, High) - self:Boundary(Section)

		Counts[Section]     = Counts[Section] + Delta
		Counts[Section + 1] = Counts[Section + 1] - Delta
	end

	-- The counts of the bar's sections, copied so dragging doesn't touch the kinds until it's let go
	function PANEL:ResetBarCounts()
		local Counts = {}

		for Section, Index in ipairs(self:GetValidRows()) do
			Counts[Section] = self.Kinds[Index].Count
		end

		self.BarCounts = Counts
	end

	--- Reports the bar's counts as the rows' counts
	function PANEL:CommitBarCounts()
		local Counts = {}

		for Index, Kind in ipairs(self.Kinds) do Counts[Index] = Kind.Count end
		for Section, Index in ipairs(self:GetValidRows()) do Counts[Index] = self.BarCounts[Section] end

		if self.OnCountsChanged then self:OnCountsChanged(Counts) end
	end

	function PANEL:CreateBar()
		local List = self
		local Bar  = self:Add("Panel")

		self.Bar = Bar

		-- The rightmost divider under the cursor, so dividers bunched together can still be pulled apart
		local function DividerAt(X)
			local Capacity = math.max(List.Capacity, 1)
			local Valid    = List:GetValidRows()

			for Section = #List.BarCounts - 1, 1, -1 do
				local DividerX = Bar:GetWide() * List:Boundary(Section) / Capacity
				local Locked   = List.Kinds[Valid[Section]].Locked or List.Kinds[Valid[Section + 1]].Locked

				if not Locked and math.abs(DividerX - X) <= DIVIDER_GRAB then return Section end
			end
		end

		function Bar:OnMousePressed()
			List:ResetBarCounts()

			self.Dragging = DividerAt(self:CursorPos())
			self:MouseCapture(self.Dragging ~= nil)
		end

		function Bar:OnMouseReleased()
			if not self.Dragging then return end

			self.Dragging = nil
			self:MouseCapture(false)

			List:CommitBarCounts()
		end

		-- Held keeps the bar as it is, ponder drags it by itself
		function Bar:Think()
			if List.Held then return end

			if not self.Dragging then
				List:ResetBarCounts()
				self:SetCursor(DividerAt(self:CursorPos()) and "sizewe" or "arrow")

				return
			end

			List:MoveDivider(self.Dragging, self:CursorPos() / self:GetWide() * List.Capacity)
		end

		function Bar:Paint(W)
			local Data, Sections = List.BarData, 0

			for Section, Index in ipairs(List:GetValidRows()) do
				local Base  = (Section - 1) * 4
				local Count = List.BarCounts[Section] or 0

				Data[Base + 1] = List.Kinds[Index].Icon or ""
				Data[Base + 2] = Count
				Data[Base + 3] = Count
				Data[Base + 4] = ACF.GetRoundKindColor(Section)

				Sections = Section
			end

			surface.SetDrawColor(BAR_BACKDROP)
			surface.DrawRect(0, 0, W, BAR_HEIGHT)

			Overlay.DrawSegmentBar(Overlay.SurfacePainter, 0, 0, W, BAR_HEIGHT, math.max(List.Capacity, 1), Data, 1, Sections, NUMBER_FONT, color_black)
		end
	end
end

do -- MARK: Rows
	-- Characters, not bytes. gmod's utf8.offset doesn't count like Lua 5.3's
	local function CutName(Value)
		Value = Value:gsub("%c", "")

		if #Value <= MAX_NAME then return Value end
		if not utf8.len(Value) then return Value:sub(1, MAX_NAME) end

		local Count = 0

		for Position in utf8.codes(Value) do
			Count = Count + 1

			if Count > MAX_NAME then return Value:sub(1, Position - 1) end
		end

		return Value
	end

	local function SquareButton(Row, Icon, Tooltip, OnClick)
		local Button = Row:Add("DButton")
		Button:SetText("")
		Button:SetImage(Icon)
		Button:SetTooltip(Tooltip)
		Button.DoClick = OnClick

		return Button
	end

	local PICKER_WIDTH   = 260
	local PICKER_SECTION = 220

	-- A checkbox to follow the color under it and a mixer for its own
	local function AddColorSection(List, Index, Parent, Which, InheritText)
		local Kind     = List.Kinds[Index]
		local Override = Kind["Override" .. Which .. "Color"] or false

		local Inherit = Parent:Add("DCheckBoxLabel")
		Inherit:Dock(TOP)
		Inherit:DockMargin(0, 0, 0, GAP)
		Inherit:SetText(InheritText)
		Inherit:SetValue(not Override)

		local Mixer = Parent:Add("DColorMixer")
		Mixer:Dock(TOP)
		Mixer:SetTall(PICKER_SECTION - 20 - GAP * 2)
		Mixer:DockMargin(0, 0, 0, GAP)
		Mixer:SetPalette(false)
		Mixer:SetAlphaBar(false)
		Mixer:SetWangs(true)
		Mixer:SetColor(ACF.UnpackColor(Kind[Which .. "Color"] or 0xFFFFFF))
		Mixer:SetEnabled(Override)
		Mixer:SetAlpha(Override and 255 or 90)

		local function Send()
			if not IsValid(List) or not List.OnColor then return end

			List:OnColor(Index, Which, not Inherit:GetChecked(), ACF.PackColor(Mixer:GetColor()))
		end

		function Inherit:OnChange(Value)
			Mixer:SetEnabled(not Value)
			Mixer:SetAlpha(Value and 90 or 255)
			Send()
		end

		function Mixer:ValueChanged()
			if Inherit:GetChecked() then return end

			Send()
		end
	end

	-- Opens a small window to pick a kind's tracer color, and smoke color if it has smoke
	local function OpenColorPicker(List, Index, Button)
		local Kind   = List.Kinds[Index]
		local Frame  = vgui.Create("DFrame")
		local Height = 30 + 6 + PICKER_SECTION * (Kind.HasSmoke and 2 or 1)

		Frame:SetTitle(Kind.HasSmoke and "Tracer and Smoke Color" or "Tracer Color")
		Frame:SetSize(PICKER_WIDTH, Height)
		Frame:DockPadding(6, 30, 6, 6)

		local X, Y = Button:LocalToScreen(0, Button:GetTall())

		Frame:SetPos(math.min(X, ScrW() - PICKER_WIDTH), math.min(Y, ScrH() - Height))
		Frame:MakePopup()

		if Kind.HasSmoke then
			AddColorSection(List, Index, Frame, "Tracer", "Tracer same as the crate's color")
			AddColorSection(List, Index, Frame, "Smoke", "Smoke same as the tracer color")
		else
			AddColorSection(List, Index, Frame, "Tracer", "Same as the crate's color")
		end
	end

	-- The kind's own colors, nil where it follows the crate's
	local function GetButtonColors(Kind)
		local Tracer = Kind.OverrideTracerColor and ACF.UnpackColor(Kind.TracerColor or 0xFFFFFF) or nil

		if not Kind.HasSmoke then return Tracer, Tracer end

		local Smoke = Kind.OverrideSmokeColor and ACF.UnpackColor(Kind.SmokeColor or 0xFFFFFF) or Tracer

		return Tracer, Smoke
	end

	function PANEL:BuildRows()
		for _, Row in ipairs(self.Rows) do Row:Remove() end

		self.Rows = {}

		local List = self

		for Index in ipairs(self.Kinds) do
			local Row = self:Add("Panel")

			Row.Index = Index

			function Row:Paint(W, H)
				local Kind = List.Kinds[Index]
				local Fill = Kind and Kind.Invalid and ROW_INVALID or Index == List.Selected and ROW_SELECTED or ROW_FILL

				surface.SetDrawColor(Fill)
				surface.DrawRect(0, 0, W, H)

				surface.SetDrawColor(ACF.GetRoundKindColor(List:GetSection(Index) or Index))
				surface.DrawRect(0, 0, SWATCH_WIDTH, H)
			end

			function Row:OnMousePressed()
				List:Select(Index)
			end

			local Icon = Row:Add("DImage")
			Icon:SetMouseInputEnabled(false)

			local Name = Row:Add("DTextEntry")
			Name:SetFont(ENTRY_FONT)
			Name:SetUpdateOnType(true)

			-- The base one gives the spawn menu keyboard focus
			function Name:OnGetFocus()
				DTextEntry.OnGetFocus(self)
				List:Select(Index)
			end

			function Name:OnValueChange(Value)
				-- Cut to the field's limit as you type, the server cuts the same way
				local Cut = CutName(Value)

				if Cut ~= Value then
					self:SetText(Cut)
					self:SetCaretPos(#Cut)
				end

				if List.OnRename then List:OnRename(Index, Cut) end
			end

			local Lock = SquareButton(Row, "icon16/lock_open.png", "", function()
				local Kind = List.Kinds[Index]

				if Kind and List.OnLockRound then List:OnLockRound(Index, not Kind.Locked) end
			end)

			local Count = Row:Add("DTextEntry")
			Count:SetFont(ENTRY_FONT)
			Count:SetNumeric(true)
			Count:SetTooltip("How many rounds of this kind the crate holds")

			function Count:OnGetFocus()
				DTextEntry.OnGetFocus(self)
				List:Select(Index)
			end

			local function SendCount()
				local Value = tonumber(Count:GetValue())

				if Value and List.OnCountTyped then List:OnCountTyped(Index, Value) end
			end

			local LoseFocus = Count.OnLoseFocus

			Count.OnEnter     = SendCount
			Count.OnLoseFocus = function(self)
				SendCount()
				LoseFocus(self)
			end

			local ColorButton = Row:Add("DButton")
			ColorButton:SetText("")
			ColorButton:SetTooltip("Tracer color")

			-- Top half tracer, bottom half smoke
			function ColorButton:Paint(W, H)
				local Kind = List.Kinds[Index]

				derma.SkinHook("Paint", "Button", self, W, H)

				if not Kind then return end

				local Tracer, Smoke = GetButtonColors(Kind)

				if not (Tracer or Smoke) then
					surface.SetDrawColor(255, 255, 255)
					surface.SetMaterial(List.InheritIcon)
					surface.DrawTexturedRect(W * 0.5 - 8, H * 0.5 - 8, 16, 16)

					return
				end

				local Half = math.floor((H - 8) * 0.5)

				if Tracer then
					surface.SetDrawColor(Tracer)
					surface.DrawRect(4, 4, W - 8, Half)
				end

				if Smoke then
					surface.SetDrawColor(Smoke)
					surface.DrawRect(4, 4 + Half, W - 8, H - 8 - Half)
				end
			end

			function ColorButton.DoClick() OpenColorPicker(List, Index, ColorButton) end

			Row.Icon   = Icon
			Row.Name   = Name
			Row.Lock   = Lock
			Row.Count  = Count
			Row.Buttons = {
				ColorButton,
				SquareButton(Row, "icon16/page_copy.png", "Copy this round", function() if List.OnAddRound then List:OnAddRound(Index) end end),
				SquareButton(Row, "icon16/arrow_up.png", "Move up", function() if List.OnMoveRound then List:OnMoveRound(Index, -1) end end),
				SquareButton(Row, "icon16/arrow_down.png", "Move down", function() if List.OnMoveRound then List:OnMoveRound(Index, 1) end end),
				SquareButton(Row, "icon16/cross.png", "Remove", function() if List.OnRemoveRound then List:OnRemoveRound(Index) end end),
			}

			self.Rows[Index] = Row
		end
	end

	-- Fills the rows in, leaving whatever is being typed in alone
	function PANEL:RefreshRows()
		local Amount = #self.Kinds

		for Index, Row in ipairs(self.Rows) do
			local Kind = self.Kinds[Index]

			Row:SetTooltip(Kind.Invalid or false)
			Row.Icon:SetImage(Kind.Icon ~= "" and Kind.Icon or "icon16/bullet_white.png")
			Row.Name:SetPlaceholderText(Kind.AutoName or "")

			if not Row.Name:HasFocus() then Row.Name:SetText(Kind.Name or "") end
			if not Row.Count:HasFocus() then Row.Count:SetText(Kind.Invalid and "-" or tostring(Kind.Count or 0)) end

			Row.Count:SetEnabled(not Kind.Invalid and Amount > 1)

			local Lock = Row.Lock

			Lock:SetImage(Kind.Locked and "icon16/lock.png" or "icon16/lock_open.png")
			Lock:SetTooltip(Kind.Locked and "Unlock this count" or "Lock this count, the other rounds won't take from or give to it")
			Lock:SetEnabled(not Kind.Invalid and Amount > 1)
			Lock:SetAlpha(not Lock:IsEnabled() and 60 or Kind.Locked and 255 or 130)
			Lock:SetVisible(self.CanAdd)

			local Buttons = Row.Buttons

			Buttons[1]:SetTooltip(Kind.HasSmoke and "Tracer and smoke color" or "Tracer color")
			Buttons[2]:SetEnabled(self.CanAdd and Amount < self.MaxKinds)
			Buttons[3]:SetEnabled(Index > 1)
			Buttons[4]:SetEnabled(Index < Amount)
			Buttons[5]:SetEnabled(Amount > 1)

			for _, Button in ipairs(Buttons) do Button:SetAlpha(Button:IsEnabled() and 255 or 60) end

			Buttons[2]:SetVisible(self.CanAdd)
			Buttons[3]:SetVisible(self.CanAdd)
			Buttons[4]:SetVisible(self.CanAdd)
			Buttons[5]:SetVisible(self.CanAdd)
		end
	end
end

--- The bar section a row is drawn as, nil for rows that sit out of it
function PANEL:GetSection(Index)
	for Section, Valid in ipairs(self:GetValidRows()) do
		if Valid == Index then return Section end
	end
end

function PANEL:Select(Index)
	if self.Selected == Index then return end

	self.Selected = Index

	if self.OnSelectRound then self:OnSelectRound(Index) end
end

function PANEL:SetSelected(Index)
	self.Selected = Index
end

function PANEL:SetCapacity(Capacity)
	self.Capacity = math.max(Capacity or 0, 0)
end

function PANEL:SetMaxKinds(Amount)
	self.MaxKinds = Amount
end

--- Whether rounds can be added, moved and removed. Missile crates hold one
function PANEL:SetCanAdd(CanAdd)
	self.CanAdd = CanAdd
	self.AddButton:SetVisible(CanAdd)
	self.Bar:SetVisible(CanAdd)
end

function PANEL:SetKinds(Kinds)
	local Rebuild = #Kinds ~= #self.Rows

	self.Kinds = Kinds

	if Rebuild then self:BuildRows() end

	self:ResetBarCounts()
	self:RefreshRows()
	self:SetTall(self:GetContentHeight())
	self:InvalidateLayout()
	self:InvalidateParent()
end

function PANEL:GetContentHeight()
	local Height = #self.Rows * (ROW_HEIGHT + GAP)

	if self.CanAdd then
		Height = Height + self:GetBarHeight() + GAP

		if #self.Rows < self.MaxKinds then Height = Height + ROW_HEIGHT end
	end

	return Height
end

function PANEL:PerformLayout(W)
	local Y = 0

	if self.CanAdd then
		local BarHeight = self:GetBarHeight()

		self.Bar:SetPos(0, 0)
		self.Bar:SetSize(W, BarHeight)

		Y = BarHeight + GAP
	end

	for _, Row in ipairs(self.Rows) do
		Row:SetPos(0, Y)
		Row:SetSize(W, ROW_HEIGHT)

		local Right = W

		for I = #Row.Buttons, 1, -1 do
			local Button = Row.Buttons[I]

			if Button:IsVisible() then
				Right = Right - ROW_HEIGHT

				Button:SetPos(Right, 0)
				Button:SetSize(ROW_HEIGHT, ROW_HEIGHT)
			end
		end

		Right = Right - GAP - COUNT_WIDTH

		Row.Count:SetPos(Right, 0)
		Row.Count:SetSize(COUNT_WIDTH, ROW_HEIGHT)

		if Row.Lock:IsVisible() then
			Right = Right - GAP - ROW_HEIGHT

			Row.Lock:SetPos(Right, 0)
			Row.Lock:SetSize(ROW_HEIGHT, ROW_HEIGHT)
		end

		local Left = SWATCH_WIDTH + GAP

		Row.Icon:SetPos(Left, (ROW_HEIGHT - 16) * 0.5)
		Row.Icon:SetSize(16, 16)

		Left = Left + 16 + GAP

		Row.Name:SetPos(Left, 0)
		Row.Name:SetSize(math.max(Right - GAP - Left, 20), ROW_HEIGHT)

		Y = Y + ROW_HEIGHT + GAP
	end

	self.AddButton:SetPos(0, Y)
	self.AddButton:SetSize(W, ROW_HEIGHT)
	self.AddButton:SetVisible(self.CanAdd and #self.Rows < self.MaxKinds)
end

PANEL.InheritIcon = Material("icon16/color_wheel.png")

derma.DefineControl("ACF_RoundList", "List of a crate's kinds of rounds", PANEL, "Panel")
