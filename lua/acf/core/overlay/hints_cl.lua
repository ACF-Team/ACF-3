-- Shows how to fix a build hint or legality restriction inline under its line while the context menu is held or the chat is open
local Overlay = ACF.Overlay or {}
ACF.Overlay = Overlay

local INLINE_W     = 340
local INLINE_GAP   = 2
local EXPAND_SPEED = 6
local FOOTER_SLOT  = 1024 -- Past any real element slot, so the footer gets its own slot cache

local TAP_PERIOD   = 1.8 -- Seconds between taps of the footer key
local TAP_DOWN     = 0.08
local TAP_UP       = 0.16

local Expand     = 0 -- 0 to 1, how far the inline help is open
local HasHelp    = false -- Whether the overlay being rendered has a line with help, for the footer
local Colors     = {} -- Render calls run after every slot is laid out, so each line needs its own color
local ColorCount = 0
local ChatOpen   = false

hook.Add("StartChat", "ACF_OverlayHelp", function() ChatOpen = true end)
hook.Add("FinishChat", "ACF_OverlayHelp", function() ChatOpen = false end)

local function IsHelpOpen()
	return ChatOpen or IsValid(g_ContextMenu) and g_ContextMenu:IsVisible()
end

-- Eases the inline help open while it is requested, called once per frame before the overlays render
function Overlay.UpdateHelpExpand()
	Expand     = math.Approach(Expand, IsHelpOpen() and 1 or 0, RealFrameTime() * EXPAND_SPEED)
	ColorCount = 0
end

local function NextColor(Base, Alpha)
	ColorCount = ColorCount + 1

	local Col = Colors[ColorCount]

	if not Col then
		Col                = Color(0, 0, 0)
		Colors[ColorCount] = Col
	end

	Col:SetUnpacked(Base.r, Base.g, Base.b, Base.a * Alpha)

	return Col
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

-- Names where to read more about a diagnostic, its Ponder storyboard when Ponder is installed or its wiki article
local function GetPointer(Def)
	local Storyboard = Def.Ponder and Ponder and Ponder.API.RegisteredStoryboards[Def.Ponder]

	if Storyboard then return "More in the \"" .. Storyboard.Name .. "\" Ponder." end
	if Def.Wiki then return "More in the wiki: " .. Def.Wiki .. "." end
end

-- Called by the Warning and Error elements after their label, grows the slot to fit the help under it while expanded
function Overlay.RenderHelp(Slot, LabelW, LabelH)
	local Def = ACF.Diagnostics.GetHelp(Slot:GetElementData(2))
	if not Def then return end

	HasHelp = true

	if Expand == 0 then return end

	local Ease     = math.ease.OutCubic(Expand)
	local Font     = Overlay.MAIN_FONT
	local Width    = math.max(LabelW, INLINE_W * Overlay.GetScaleMult())
	local Pointer  = GetPointer(Def)
	local Lines    = Wrap(Pointer and Def.Help .. " " .. Pointer or Def.Help, Font, Width)
	local _, LineH = Overlay.GetTextSize(Font, "A")
	local Top      = LabelH + INLINE_GAP
	local Bottom   = LabelH + (INLINE_GAP + #Lines * LineH) * Ease

	-- Each line fades in as the slot grows past it
	for I, Line in ipairs(Lines) do
		local Y     = Top + (I - 1) * LineH
		local Alpha = math.Clamp((Bottom - Y) / LineH, 0, 1)
		if Alpha == 0 then break end

		Overlay.SimpleText(Line, Font, 0, Y, NextColor(Overlay.COLOR_TEXT, 0.75 * Alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	end

	Overlay.AppendSlotSize(Width, Bottom)
end

-- How far the footer key is pushed down, 0 to 1: a short tap every TAP_PERIOD, held down while the help is open
local function GetKeyPress()
	local Time = RealTime() % TAP_PERIOD
	local Tap  = 0

	if Time < TAP_DOWN then
		Tap = Time / TAP_DOWN
	elseif Time < TAP_DOWN + TAP_UP then
		Tap = 1 - (Time - TAP_DOWN) / TAP_UP
	end

	return math.max(math.ease.OutCubic(Tap), math.ease.OutCubic(Expand))
end

-- Called after the last element, tells the player how to expand the help when any line has some
function Overlay.RenderHelpFooter()
	if not HasHelp then return end

	HasHelp = false

	local Font  = Overlay.MAIN_FONT
	local Text  = Overlay.COLOR_TEXT
	local Alpha = Lerp(math.ease.OutCubic(Expand), 0.8, 0.65)
	local Key   = input.LookupBinding("+menu_context")

	if not Key then
		Overlay.SimpleText("Hold the context menu key or open chat for more information", Font, 0, 0, NextColor(Text, Alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		Overlay.PushSlotSizeToTotal(FOOTER_SLOT)

		return
	end

	-- Laid out as "Hold [key] or open chat for more information", with the key drawn as a keycap whose face sits on a darker side
	local Scale          = Overlay.GetScaleMult()
	local Label          = Key:upper()
	local KeyFont        = Overlay.BOLD_TEXT_FONT
	local Before         = "Hold"
	local After          = "or open chat for more information"
	local BeforeW        = Overlay.GetTextSize(Font, Before)
	local AfterW, H      = Overlay.GetTextSize(Font, After)
	local LabelW, LabelH = Overlay.GetTextSize(KeyFont, Label)
	local Space          = Overlay.GetTextSize(Font, " ") + 2 * Scale
	local Depth          = math.max(3, math.Round(4 * Scale))
	local FaceH          = H + math.Round(3 * Scale)
	local KeyW           = math.max(LabelW + math.Round(13 * Scale), FaceH)
	local Radius         = math.max(2, math.Round(4 * Scale))
	local TotalW         = BeforeW + Space + KeyW + Space + AfterW
	local X              = -TotalW / 2
	local TextY          = (FaceH + Depth - H) / 2
	local FaceY          = GetKeyPress() * Depth
	local SideColor      = NextColor(Overlay.COLOR_SECONDARY_COLOR, Alpha)
	local FaceColor      = NextColor(Overlay.COLOR_PRIMARY_COLOR, Alpha)

	Overlay.SimpleText(Before, Font, X + BeforeW / 2, TextY, NextColor(Text, Alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

	X = X + BeforeW + Space

	Overlay.DrawRoundedBox(Radius, X, Depth, KeyW, FaceH, SideColor)
	Overlay.DrawRoundedBox(Radius, X, FaceY, KeyW, FaceH, FaceColor)
	Overlay.SimpleText(Label, KeyFont, X + KeyW / 2, FaceY + (FaceH - LabelH) / 2, NextColor(Overlay.COLOR_TEXT_DARK, Alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

	X = X + KeyW + Space

	Overlay.SimpleText(After, Font, X + AfterW / 2, TextY, NextColor(Text, Alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	Overlay.AppendSlotSize(TotalW, FaceH + Depth)
	Overlay.PushSlotSizeToTotal(FOOTER_SLOT)
end
