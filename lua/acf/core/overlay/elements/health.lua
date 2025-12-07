local Overlay = ACF.Overlay
local ELEMENT = {}

-- Data slots are as follows:
--   [1]: Label
--   [2]: Value or Time to End
--   [3]: Max Value or Total Time
--   [4]: Unit?
--   [5]: Decimals?
--   [6]: Min Color?
--   [7]: Max Color?


local HEALTH_BAD  = Color(255, 40, 30)
local HEALTH_GOOD = Color(30, 255, 50)
local PROGRESS_EMPTY   = Color(66, 96, 116)
local PROGRESS_FULL    = Color(112, 191, 243)

-- These methods return
    -- Formatted text for the slots data
    -- The 0 to 1 ratio for the progress bar
    -- Minimum color
    -- Maximum color
    -- Optionally an interpolation function for the progress bars color
local function GetPropertiesHealth(Slot)
    local Health    = Slot.Data[2]
    local MaxHealth = Slot.Data[3]
    local Unit      = Slot.NumData >= 4 and Slot.Data[4] or ""
    local Decimals  = Slot.NumData >= 5 and Slot.Data[5] or 0

    local MinColor  = Slot.NumData >= 6 and Slot.Data[6] or HEALTH_BAD
    local MaxColor  = Slot.NumData >= 6 and Slot.Data[6] or HEALTH_GOOD

    local Ratio = Health / MaxHealth
    return ("%d/%d%s (%." .. Decimals .. "f%%)"):format(Health, MaxHealth, Unit, Ratio * 100), Ratio, MinColor, MaxColor
end

local function GetPropertiesProgress(Slot)
    local Health    = Slot.Data[2]
    local MaxHealth = Slot.Data[3]
    local Unit      = Slot.NumData >= 4 and Slot.Data[4] or ""
    local Decimals  = Slot.NumData >= 5 and Slot.Data[5] or 0

    local MinColor  = Slot.NumData >= 6 and Slot.Data[6] or PROGRESS_EMPTY
    local MaxColor  = Slot.NumData >= 6 and Slot.Data[6] or PROGRESS_FULL

    local Ratio = Health / MaxHealth
    return ("%d/%d%s (%." .. Decimals .. "f%%)"):format(Health, MaxHealth, Unit, Ratio * 100), Ratio, MinColor, MaxColor
end

local function GetPropertiesTime(Slot)
    local NextTime    = Slot.Data[2]
    local TotalTime   = Slot.Data[3]

    local Remaining = math.max(0, NextTime - CurTime())
    local Ratio = math.Clamp(Remaining / TotalTime, 0, 1)
    if Slot.NumData >= 4 and Slot.Data[4] == true then
        Ratio = 1 - Ratio
    end

    local MinColor  = Slot.NumData >= 6 and Slot.Data[6] or PROGRESS_EMPTY
    local MaxColor  = Slot.NumData >= 6 and Slot.Data[6] or HEALTH_GOOD

    return ("%.1f seconds"):format(Remaining), Ratio, MinColor, MaxColor, math.ease.InExpo
end


local function Render(Slot, TextMethod)
    -- Our horizontal positions here are dependent on the final size of everything.
    -- So those will be adjusted in PostRender, and we'll allocate our size here.

    local W1, H1 = Overlay.GetTextSize(Overlay.PROGRESS_BAR_TEXT, Slot.Data[1])
    local ProgressText = TextMethod(Slot)
    local W2, H2 = Overlay.GetTextSize(Overlay.PROGRESS_BAR_TEXT, ProgressText)
    H2 = H2 + 4
    Overlay.AppendSlotSize(W1 + W2 + 32, math.max(H1, H2))
    Overlay.PushWidths(W1, W2)
end

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
local function Linear(x) return x end
local function RenderBar(Slot, TextMethod)
    local TotalW = Overlay.GetOverlaySize()

    local Text      = Slot.Data[1]
    local InnerText, Ratio, MinC, MaxC, ColorInterp = TextMethod(Slot)
    Ratio = math.Clamp(Ratio, 0, 1)
    ColorInterp     = ColorInterp or Linear

    local ValueX    = Overlay.GetKVValueX()
    local _, H1 = Overlay.GetTextSize(Overlay.PROGRESS_BAR_TEXT, Text)
    local _, H2 = Overlay.GetTextSize(Overlay.PROGRESS_BAR_TEXT, InnerText)

    Overlay.SimpleText(Text, Overlay.KEY_TEXT_FONT, Overlay.GetKVKeyX(), 0, Overlay.COLOR_TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    Overlay.DrawKVDivider()
    local X, Y = ValueX, 0
    local W, H = (TotalW / 2) - 32, math.max(H1, H2)

    local CV = Overlay.GetOverlayOffset()
    local ClipTextRatio = (CV[1] + X) + (W * Ratio)

    Overlay.PushCustomClipPlane(ClipDir_1, ClipTextRatio)
    Overlay.SimpleText(InnerText, Overlay.PROGRESS_BAR_TEXT, X + (W / 2), Y + (H / 2) - 1, Overlay.COLOR_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    Overlay.PopCustomClipPlane()

    local ColorRatio = ColorInterp(Ratio)

    local BarColor = LerpColor(ColorRatio, MinC, MaxC)
    Overlay.DrawRect(X, Y, W * Ratio, H, BarColor)
    Overlay.SetMaterial(FakeScanlines)
    local BarScanlinesColor = BarColor:Copy()
    BarScanlinesColor:SetBrightness(0.8)
    local Now = RealTime() % 1
    Overlay.DrawTexturedRectUV(X, Y, W * Ratio, H, 0, Now, 0, Now + 8, BarScanlinesColor)
    Overlay.NoTexture()

    local BackColor = LerpColor(ColorRatio, MinC, MaxC)
    BackColor:SetBrightness(0.3)
    Overlay.DrawOutlinedRect(X, Y, W, H, BackColor, 2)

    local BackTextColor = LerpColor(ColorRatio, MinC, MaxC)
    BackTextColor:SetSaturation(0.3)
    BackTextColor:SetBrightness(1)

    Overlay.PushCustomClipPlane(ClipDir_2, -ClipTextRatio)
    Overlay.SimpleText(InnerText, Overlay.PROGRESS_BAR_TEXT, X + (W / 2), Y + (H / 2) - 1, Overlay.COLOR_TEXT_DARK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    Overlay.PopCustomClipPlane()
end

function ELEMENT.Render(_, Slot) Render(Slot, GetPropertiesHealth) end
function ELEMENT.PostRender(_, Slot) RenderBar(Slot, GetPropertiesHealth) end

Overlay.DefineElementType("Health", ELEMENT)

local PROGRESS_BAR = {}
function PROGRESS_BAR.Render(_, Slot) Render(Slot, GetPropertiesProgress) end
function PROGRESS_BAR.PostRender(_, Slot) RenderBar(Slot, GetPropertiesProgress) end
Overlay.DefineElementType("ProgressBar", PROGRESS_BAR)

local TIME_LEFT = {}
function TIME_LEFT.Render(_, Slot) Render(Slot, GetPropertiesTime) end
function TIME_LEFT.PostRender(_, Slot) RenderBar(Slot, GetPropertiesTime) end
Overlay.DefineElementType("TimeLeft", TIME_LEFT)