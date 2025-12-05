local Overlay = ACF.Overlay
local ELEMENT = {}

local function GetText(Slot)
    local Health    = Slot.Data[2]
    local MaxHealth = Slot.Data[3]
    local Unit      = Slot.NumData >= 4 and Slot.Data[4] or ""
    local Decimals  = Slot.NumData >= 5 and Slot.Data[5] or 0

    local Ratio = Health / MaxHealth
    return ("%d/%d%s (%." .. Decimals .. "f%%)"):format(Health, MaxHealth, Unit, Ratio * 100), Ratio
end

local function GetTextTime(Slot)
    local NextTime    = Slot.Data[2]
    local TotalTime   = Slot.Data[3]

    local Remaining = math.max(0, NextTime - CurTime())
    local Ratio = math.Clamp(Remaining / TotalTime, 0, 1)
    if Slot.NumData >= 4 and Slot.Data[4] == true then
        Ratio = 1 - Ratio
    end
    return ("%.1f seconds"):format(Remaining), Ratio
end


function ELEMENT.Render(_, Slot, TextMethod)
   -- Our horizontal positions here are dependent on the final size of everything.
    -- So those will be adjusted in PostRender, and we'll allocate our size here.

    local Text      = Slot.Data[1]

    local W1, H1 = Overlay.GetTextSize(Overlay.PROGRESS_BAR_TEXT, Text)
    local W2, H2 = Overlay.GetTextSize(Overlay.PROGRESS_BAR_TEXT, (TextMethod or GetText)(Slot))
    H2 = H2 + 4
    Overlay.AppendSlotSize(W1 + W2 + 32, math.max(H1, H2))
    Overlay.PushWidths(W1, W2)
end

local HEALTH_BAD  = Color(255, 40, 30)
local HEALTH_GOOD = Color(30, 255, 50)
local PROGRESS_EMPTY   = Color(66, 96, 116)
local PROGRESS_FULL    = Color(112, 191, 243)
local ColorCache = Color(255, 255, 255)
local function LerpColor(T, A, B)
    local R1, G1, B1, A1 = A:Unpack()
    local R2, G2, B2, A2 = B:Unpack()
    ColorCache:SetUnpacked(
        Lerp(T, R1, R2),
        Lerp(T, G1, G2),
        Lerp(T, B1, B2),
        Lerp(T, A1, A2)
    )
    ColorCache:SetBrightness(1)
    return ColorCache:Copy()
end

local FakeScanlines = Material("vgui/gradient_down")

local ClipDir_1 = Vector(1, 0, 0)
local ClipDir_2 = Vector(-1, 0, 0)
local function RenderBar(Slot, MinColor, MaxColor, TextMethod)
    local TotalW = Overlay.GetOverlaySize()

    local Text      = Slot.Data[1]
    local Health    = Slot.Data[2]
    local MaxHealth = Slot.Data[3]
    local InnerText, Ratio = (TextMethod or GetText)(Slot)

    local ValueX    = Overlay.GetKVValueX()
    local _, H1 = Overlay.GetTextSize(Overlay.PROGRESS_BAR_TEXT, Text)
    local _, H2 = Overlay.GetTextSize(Overlay.PROGRESS_BAR_TEXT, (TextMethod or GetText)(Slot))

    Overlay.SimpleText(Text, Overlay.KEY_TEXT_FONT, KeyX, 0, Overlay.COLOR_TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    Overlay.DrawKVDivider()
    local X, Y = ValueX, 0
    local W, H = (TotalW / 2) - 32, math.max(H1, H2)

    local CV = Overlay.GetOverlayOffset()
    local ClipTextRatio = (CV[1] + X) + (W * Ratio)

    Overlay.PushCustomClipPlane(ClipDir_1, ClipTextRatio)
    Overlay.SimpleText(InnerText, Overlay.PROGRESS_BAR_TEXT, X + (W / 2), Y + (H / 2) - 1, Overlay.COLOR_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    Overlay.PopCustomClipPlane()

    local BarColor = LerpColor(Ratio, MinColor, MaxColor)
    Overlay.DrawRect(X, Y, W * Ratio, H, BarColor)
    Overlay.SetMaterial(FakeScanlines)
    local BarScanlinesColor = BarColor:Copy()
    BarScanlinesColor:SetBrightness(0.8)
    local Now = RealTime() % 1
    Overlay.DrawTexturedRectUV(X, Y, W * Ratio, H, 0, Now, 0, Now + 8, BarScanlinesColor)
    Overlay.NoTexture()

    local BackColor = LerpColor(Ratio, MinColor, MaxColor)
    BackColor:SetBrightness(0.3)
    Overlay.DrawOutlinedRect(X, Y, W, H, BackColor, 2)

    local BackTextColor = LerpColor(Health / MaxHealth, MinColor, MaxColor)
    BackTextColor:SetSaturation(0.3)
    BackTextColor:SetBrightness(1)

    Overlay.PushCustomClipPlane(ClipDir_2, -ClipTextRatio)
    Overlay.SimpleText(InnerText, Overlay.PROGRESS_BAR_TEXT, X + (W / 2), Y + (H / 2) - 1, Overlay.COLOR_TEXT_DARK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    Overlay.PopCustomClipPlane()
end

function ELEMENT.PostRender(_, Slot)
    RenderBar(Slot, HEALTH_BAD, HEALTH_GOOD)
end

Overlay.DefineElementType("Health", ELEMENT)

local PROGRESS_BAR = {}
PROGRESS_BAR.Render = ELEMENT.Render
function PROGRESS_BAR.PostRender(_, Slot)
    RenderBar(Slot, PROGRESS_EMPTY, PROGRESS_FULL)
end
Overlay.DefineElementType("ProgressBar", PROGRESS_BAR)

local TIME_LEFT = {}
TIME_LEFT.Render = ELEMENT.Render
function TIME_LEFT.PostRender(_, Slot)
    RenderBar(Slot, PROGRESS_EMPTY, PROGRESS_FULL, GetTextTime)
end
Overlay.DefineElementType("TimeLeft", TIME_LEFT)