-- Draws the tool picker's list next to the crosshair, in the overlay's style
-- Loads before tool_picker_sh.lua
local ACF        = ACF
local Overlay    = ACF.Overlay
local ToolPicker = ACF.ToolPicker or {}

ACF.ToolPicker = ToolPicker

local MAX_ROWS     = 8
local REFRESH_RATE = 0.1
local OFFSET       = 32 -- From the crosshair, same as the overlay on the other side
local PADDING      = 12
local GAP          = 4
local ROW_GAP      = 2
local STRIPE_WIDTH = 4
local MIN_WIDTH    = 240
local MAX_WIDTH    = 420
local SLIDE_SPEED  = 45
local FADE_IN      = 6
local FADE_OUT     = 9
local FOOTER       = "Scroll up/down to select an option"
local ROW_FILL     = Color(0, 0, 0, 50)
local ELLIPSIS     = "..."

local Target, Picker, Rows, Layout
local LastMode
local NextRefresh = 0
local ShownAt     = 0
local HiddenAt
local Scroll      = 1 -- First row shown
local SlideRow    = 1
local SlideScroll = 1
local Snap        = false
local Materials   = {}
local TextColors  = {}
local Dim         = Color(0, 0, 0)

local function GetRow()
	return math.Clamp(ToolPicker.RowVar:GetInt(), 1, Rows and #Rows or 1)
end

local function GetMaterial(Path)
	local Mat = Materials[Path]

	if not Mat then
		Mat = Material(Path, "smooth mips")
		Materials[Path] = Mat
	end

	return Mat
end

local function TextWidth(Font, Text)
	surface.SetFont(Font)

	local Width = surface.GetTextSize(Text)

	return Width
end

-- Cuts the text with an ellipsis to fit
local function Fit(Text, Font, Width)
	if TextWidth(Font, Text) <= Width then return Text end

	local Chars = {}

	for _, Code in utf8.codes(Text) do Chars[#Chars + 1] = utf8.char(Code) end

	for Count = #Chars - 1, 0, -1 do
		local Cut = table.concat(Chars, "", 1, Count) .. ELLIPSIS

		if Count == 0 or TextWidth(Font, Cut) <= Width then return Cut end
	end
end

local function Wrap(Text, Font, Width)
	local Lines   = {}
	local Current = ""

	for Word in Text:gmatch("%S+") do
		local Test = Current == "" and Word or Current .. " " .. Word

		if Current ~= "" and TextWidth(Font, Test) > Width then
			Lines[#Lines + 1] = Current
			Current           = Word
		else
			Current = Test
		end
	end

	if Current ~= "" then Lines[#Lines + 1] = Current end

	return Lines
end

-- Sizes and cut texts, worked out when the rows refresh instead of every frame
local function BuildLayout()
	local Scale     = Overlay.GetScaleMult()
	local Font      = Overlay.MAIN_FONT
	local NameFont  = Overlay.BOLD_TEXT_FONT -- The regular one is too thin to read dark on the highlight
	local Title     = Picker.Title or "Apply To"
	local _, TitleH = Overlay.GetTextSize(Overlay.SUBHEADER_FONT, Title)
	local _, TextH  = Overlay.GetTextSize(Font, "A")

	local Padding = math.Round(PADDING * Scale)
	local Gap     = math.Round(GAP * Scale)
	local RowH    = TextH + math.Round(12 * Scale)
	local Swatch  = RowH - math.Round(10 * Scale)
	local IconW   = math.Round(16 * Scale)
	local StripeW = math.max(2, math.Round(STRIPE_WIDTH * Scale))

	-- What each row needs besides its text
	local function Fixed(Row)
		local Width = Gap + Swatch + Gap

		if Row.Stripe then Width = Width + StripeW end
		if Row.Icon then Width = Width + IconW + Gap end
		if Row.Note then Width = Width + TextWidth(NameFont, Row.Note) + Gap end

		return Width + Gap
	end

	local Width = math.max(TextWidth(Overlay.SUBHEADER_FONT, Title), TextWidth(Font, FOOTER))

	for _, Row in ipairs(Rows) do
		Width = math.max(Width, Fixed(Row) + TextWidth(NameFont, Row.Text or ""))
	end

	Width = math.Clamp(Width, MIN_WIDTH * Scale, MAX_WIDTH * Scale)

	local HelpLines = 0

	for _, Row in ipairs(Rows) do
		Row.Shown     = Fit(Row.Text or "", NameFont, Width - Fixed(Row))
		Row.HelpLines = Row.Help and Wrap(Row.Help, Font, Width) or {}

		HelpLines = math.max(HelpLines, #Row.HelpLines)
	end

	local Footer  = Wrap(FOOTER, Font, Width)
	local Visible = math.min(#Rows, MAX_ROWS)
	local ListY   = Padding + TitleH + Gap
	local ListH   = Visible * (RowH + ROW_GAP) - ROW_GAP
	local HelpY   = ListY + ListH + Gap

	-- Room for the longest help, the frame keeps its size while scrolling
	local FooterY = HelpY + HelpLines * TextH + (HelpLines > 0 and Gap or 0)

	Layout = {
		Title = Title, TitleH = TitleH, Font = Font, NameFont = NameFont, TextH = TextH,
		Padding = Padding, Gap = Gap, RowH = RowH, Swatch = Swatch, IconW = IconW, StripeW = StripeW,
		Visible = Visible, ListY = ListY, ListH = ListH, HelpY = HelpY, Footer = Footer, FooterY = FooterY,
		W = Width + Padding * 2,
		H = FooterY + #Footer * TextH + Padding,
	}
end

local function Refresh()
	local New = Picker.GetRows and Picker.GetRows(Target)

	Rows = New and New[2] and New or nil

	-- Nothing to pick, clicks go to the entity
	if not Rows then
		if ToolPicker.RowVar:GetInt() ~= 1 then ToolPicker.RowVar:SetInt(1) end

		return
	end

	if ToolPicker.RowVar:GetInt() > #Rows then ToolPicker.RowVar:SetInt(#Rows) end

	BuildLayout()
end

local function GetToolMode(Player)
	local Weapon = Player:GetActiveWeapon()

	if not IsValid(Weapon) or Weapon:GetClass() ~= "gmod_tool" then return end

	return Weapon:GetMode()
end

hook.Add("Think", "ACF_ToolPicker", function()
	local Player = LocalPlayer()
	local Mode   = IsValid(Player) and GetToolMode(Player)

	-- A new tool starts on the entity
	if Mode and Mode ~= LastMode then
		if LastMode then ToolPicker.RowVar:SetInt(1) end

		LastMode = Mode
	end

	local Entity = Mode and Player:GetEyeTrace().Entity
	local Found  = Mode and ToolPicker.Get(Mode, Entity)
	local Now    = RealTime()

	if Found and (Entity ~= Target or Found ~= Picker) then
		local WasShown = Target ~= nil

		Target, Picker, NextRefresh = Entity, Found, 0

		if not WasShown then
			ShownAt  = Now
			HiddenAt = nil
			Snap     = true
		end
	elseif not Found and Target then
		Target   = nil
		HiddenAt = Now
	end

	if not Target then return end

	if Now >= NextRefresh then
		NextRefresh = Now + REFRESH_RATE

		Refresh()
	end

	if not Rows then return end

	local Row = GetRow()

	Scroll = math.Clamp(Scroll, Row - MAX_ROWS + 1, Row)
	Scroll = math.Clamp(Scroll, 1, math.max(1, #Rows - MAX_ROWS + 1))

	-- Snaps on a new target instead of sliding in from wherever it was
	if Snap then
		SlideRow, SlideScroll, Snap = Row, Scroll, false
	end

	local Ease = 1 - math.exp(-RealFrameTime() * SLIDE_SPEED)

	SlideRow    = Lerp(Ease, SlideRow, Row)
	SlideScroll = Lerp(Ease, SlideScroll, Scroll)
end)

-- Weapon selectors take the scroll too, ULib runs this before them
hook.Add("PlayerBindPress", "ACF_ToolPicker", function(_, Bind, Pressed)
	if not Pressed or not Target or not Rows then return end

	local Step = (Bind == "invnext" and 1) or (Bind == "invprev" and -1)

	if not Step then return end

	local Row = GetRow()
	local New = math.Clamp(Row + Step, 1, #Rows)

	if New ~= Row then
		ToolPicker.RowVar:SetInt(New)
		surface.PlaySound("buttons/lightswitch2.wav")
	end

	return true
end, HOOK_HIGH)

local function GetTextColor(Index, Selected)
	local Col = TextColors[Index]

	if not Col then
		Col = Color(0, 0, 0)
		TextColors[Index] = Col
	end

	local Light, Dark = Overlay.COLOR_TEXT, Overlay.COLOR_TEXT_DARK

	Col:SetUnpacked(
		Lerp(Selected, Light.r, Dark.r),
		Lerp(Selected, Light.g, Dark.g),
		Lerp(Selected, Light.b, Dark.b),
		Lerp(Selected, Light.a, Dark.a)
	)

	return Col
end

local function DrawRow(Row, Index, X, Y, W, L)
	local RowH     = L.RowH
	local Selected = math.Clamp(1 - math.abs(SlideRow - Index), 0, 1)
	local Text     = GetTextColor(Index, Selected)
	local Left     = X
	local Right    = X + W - L.Gap
	local Middle   = Y + RowH * 0.5

	if Row.Stripe then
		surface.SetDrawColor(Row.Stripe)
		surface.DrawRect(Left, Y, L.StripeW, RowH)

		Left = Left + L.StripeW
	end

	Left = Left + L.Gap

	if Row.Icon then
		surface.SetMaterial(GetMaterial(Row.Icon))
		surface.SetDrawColor(255, 255, 255)
		surface.DrawTexturedRect(Left, Middle - L.IconW * 0.5, L.IconW, L.IconW)
		draw.NoTexture()

		Left = Left + L.IconW + L.Gap
	end

	draw.SimpleText(Row.Shown, L.NameFont, Left, Middle, Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

	local SwatchY = Middle - L.Swatch * 0.5

	Right = Right - L.Swatch

	if Row.Swatch then
		surface.SetDrawColor(Row.Swatch)
		surface.DrawRect(Right, SwatchY, L.Swatch, L.Swatch)
		surface.SetDrawColor(Text)
		surface.DrawOutlinedRect(Right, SwatchY, L.Swatch, L.Swatch, 1)
	end

	if Row.Note then
		local Alpha = Text.a

		Text.a = Alpha * 0.6
		draw.SimpleText(Row.Note, L.NameFont, Right - L.Gap, Middle, Text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		Text.a = Alpha
	end
end

local function DrawPicker(Alpha)
	local L       = Layout
	local W, H    = L.W, L.H
	local X       = math.Round(ScrW() * 0.5 + OFFSET)
	local Y       = math.Round(math.Clamp(ScrH() * 0.5 - H * 0.5, 8, ScrH() - H - 8))
	local Padding = L.Padding
	local InnerX  = X + Padding
	local InnerW  = W - Padding * 2
	local Step    = L.RowH + ROW_GAP
	local ListY   = Y + L.ListY
	local Text    = Overlay.COLOR_TEXT
	local Old     = surface.GetAlphaMultiplier()

	surface.SetAlphaMultiplier(Old * Alpha)

	Overlay.DrawFrameBackground(X, Y, W, H)

	Dim:SetUnpacked(Text.r, Text.g, Text.b, 100)

	draw.SimpleText(L.Title, Overlay.SUBHEADER_BACK_FONT, X + W * 0.5, Y + Padding, Dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	draw.SimpleText(L.Title, Overlay.SUBHEADER_FONT, X + W * 0.5, Y + Padding, Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

	render.SetScissorRect(X, ListY, X + W, ListY + L.ListH, true)

	local First = math.max(1, math.floor(SlideScroll))
	local Last  = math.min(#Rows, math.ceil(SlideScroll) + L.Visible)

	for Index = First, Last do
		surface.SetDrawColor(ROW_FILL)
		surface.DrawRect(InnerX, ListY + (Index - SlideScroll) * Step, InnerW, L.RowH)
	end

	surface.SetDrawColor(Overlay.COLOR_PRIMARY_COLOR)
	surface.DrawRect(InnerX, ListY + (SlideRow - SlideScroll) * Step, InnerW, L.RowH)

	for Index = First, Last do
		DrawRow(Rows[Index], Index, InnerX, ListY + (Index - SlideScroll) * Step, InnerW, L)
	end

	render.SetScissorRect(0, 0, 0, 0, false)

	if #Rows > L.Visible then
		local BarW   = math.max(2, math.Round(Padding * 0.5))
		local BarX   = X + W - Padding + (Padding - BarW) * 0.5
		local ThumbH = L.ListH * L.Visible / #Rows
		local ThumbY = (L.ListH - ThumbH) * (SlideScroll - 1) / (#Rows - L.Visible)

		surface.SetDrawColor(ROW_FILL)
		surface.DrawRect(BarX, ListY, BarW, L.ListH)
		surface.SetDrawColor(Overlay.COLOR_PRIMARY_COLOR)
		surface.DrawRect(BarX, ListY + ThumbY, BarW, ThumbH)
	end

	Dim.a = Text.a * 0.75

	for I, Line in ipairs(Rows[GetRow()].HelpLines) do
		draw.SimpleText(Line, L.Font, InnerX, Y + L.HelpY + (I - 1) * L.TextH, Dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end

	Dim.a = Text.a * 0.55

	for I, Line in ipairs(L.Footer) do
		draw.SimpleText(Line, L.Font, InnerX, Y + L.FooterY + (I - 1) * L.TextH, Dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end

	Overlay.DrawFrameBorder(X, Y, W, H)

	surface.SetAlphaMultiplier(Old)
end

hook.Add("HUDPaint", "ACF_ToolPicker", function()
	if not Rows or not Layout then return end

	local Now   = RealTime()
	local Alpha = math.ease.InSine(math.Clamp((Now - ShownAt) * FADE_IN, 0, 1))

	if HiddenAt then
		local Out = math.Clamp((Now - HiddenAt) * FADE_OUT, 0, 1)

		if Out == 1 then
			Rows, Layout = nil, nil

			return
		end

		Alpha = Alpha * math.ease.OutCirc(1 - Out)
	end

	DrawPicker(Alpha)
end)
