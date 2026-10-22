-- Shows how to fix a build hint or legality restriction when its line in the overlay is hovered with the cursor, such as with the context menu open
local Overlay = ACF.Overlay or {}
ACF.Overlay = Overlay

local Rects = {}
local Count = 0

local COLOR_IDLE  = Color(255, 255, 255, 40)
local COLOR_HOVER = Color(255, 255, 255, 220)
local HELP_W      = 300
local PADDING     = 8
local GAP         = 12

function Overlay.ResetHintRects()
	Count = 0
end

-- The definition of a hint or restriction, only the ones with help can be hovered
local function GetDef(Id)
	return ACF.Diagnostics.GetHelp(Id)
end

-- Stores the screen rectangle of every hint warning and restriction error, called by DrawOverlay once the final scale is known
function Overlay.CollectHintRects(State, XScale, YScale, TotalW)
	local WarningIdx = Overlay.GetElementTypeIdx("Warning")
	local ErrorIdx   = Overlay.GetElementTypeIdx("Error")
	local Offset     = Overlay.GetOverlayOffset()

	for Idx, Slot in State:IterateElementSlots() do
		local Id = Slot:GetElementData(2)
		if (Slot.Type ~= WarningIdx and Slot.Type ~= ErrorIdx) or not GetDef(Id) then continue end

		local Cache = Overlay.GetSlotDataCache(Idx)
		local Rect  = Rects[Count + 1] or {}

		Count = Count + 1
		Rects[Count] = Rect

		Rect.Id = Id
		Rect.W  = TotalW * XScale
		Rect.X  = Offset.x - Rect.W / 2
		Rect.Y  = Offset.y + Cache.Y * YScale
		Rect.H  = Cache.H * YScale
	end
end

local function GetHovered()
	local MX, MY = gui.MousePos()

	for I = 1, Count do
		local Rect = Rects[I]

		if MX >= Rect.X and MX <= Rect.X + Rect.W and MY >= Rect.Y and MY <= Rect.Y + Rect.H then return Rect end
	end
end

-- Splits the text into lines no wider than the given width
local function Wrap(Text, Font, Width)
	surface.SetFont(Font)

	local Lines   = {}
	local Current = ""

	for Word in Text:gmatch("%S+") do
		local Test = Current == "" and Word or Current .. " " .. Word

		if Current ~= "" and surface.GetTextSize(Test) > Width then
			Lines[#Lines + 1] = Current
			Current           = Word
		else
			Current = Test
		end
	end

	Lines[#Lines + 1] = Current

	return Lines
end

-- Draws the fix beside the overlay, on the right unless that would leave the screen
local function DrawHelp(Rect)
	local Def = GetDef(Rect.Id)
	if not Def then return end

	local TitleFont = Overlay.BOLD_TEXT_FONT
	local TextFont  = Overlay.MAIN_FONT
	local Lines     = Wrap(Def.Help, TextFont, HELP_W - PADDING * 2)

	surface.SetFont(TitleFont)

	local _, TitleH = surface.GetTextSize(Def.Title)

	surface.SetFont(TextFont)

	local _, LineH = surface.GetTextSize("A")
	local H        = PADDING * 2 + TitleH + 4 + #Lines * LineH
	local X        = Rect.X + Rect.W + GAP
	local Y        = Rect.Y

	if X + HELP_W > ScrW() then X = Rect.X - GAP - HELP_W end

	Y = math.Clamp(Y, 0, ScrH() - H)

	surface.SetDrawColor(Overlay.COLOR_PRIMARY_BACKGROUND)
	surface.DrawRect(X, Y, HELP_W, H)
	surface.SetDrawColor(Overlay.COLOR_BORDER_LIGHT_COLOR)
	surface.DrawOutlinedRect(X, Y, HELP_W, H, 2)

	draw.SimpleText(Def.Title, TitleFont, X + PADDING, Y + PADDING, Overlay.COLOR_WARNING_TEXT or Overlay.COLOR_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	for I, Line in ipairs(Lines) do
		draw.SimpleText(Line, TextFont, X + PADDING, Y + PADDING + TitleH + 4 + (I - 1) * LineH, Overlay.COLOR_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end
end

function Overlay.DrawHints()
	if Count == 0 or not vgui.CursorVisible() then return end

	local Hovered = GetHovered()

	for I = 1, Count do
		local Rect = Rects[I]

		surface.SetDrawColor(Rect == Hovered and COLOR_HOVER or COLOR_IDLE)
		surface.DrawOutlinedRect(Rect.X, Rect.Y, Rect.W, Rect.H)
	end

	if Hovered then DrawHelp(Hovered) end
end
