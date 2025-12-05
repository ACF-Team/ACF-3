local Overlay = ACF.Overlay
local ELEMENT = {}

local function GetText(Slot)
    local Health    = Slot.Data[2]
    local MaxHealth = Slot.Data[3]
    local Unit      = Slot.NumData >= 4 and Slot.Data[4] or ""
    local Decimals  = Slot.NumData >= 5 and Slot.Data[5] or 0

    local Ratio = Health / MaxHealth
    return ("%d/%d%s (%." .. Decimals .. "f%%)"):format(Health, MaxHealth, Unit, Ratio * 100)
end

function ELEMENT.Render(_, Slot)
   -- Our horizontal positions here are dependent on the final size of everything.
    -- So those will be adjusted in PostRender, and we'll allocate our size here.

    local Text      = Slot.Data[1]

    local W1, H1 = Overlay.GetTextSize(Overlay.KEY_TEXT_FONT, Text)
    local W2, H2 = Overlay.GetTextSize(Overlay.KEY_TEXT_FONT, GetText(Slot))
    W2 = W2 + 32
    Overlay.AppendSlotSize(math.max(W1, W2), math.max(H1, H2))
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

local function RenderBar(Slot, MinColor, MaxColor)
    local SlotW, SlotH  = Overlay.GetSlotSize()

    local Text      = Slot.Data[1]
    local Health    = Slot.Data[2]
    local MaxHealth = Slot.Data[3]
    local W2 = Overlay.GetTextSize(Overlay.KEY_TEXT_FONT, GetText(Slot))

    local Ratio = Health / MaxHealth

    local KeyX      = Overlay.GetKVKeyX()
    local ValueX    = Overlay.GetKVValueX()

    Overlay.SimpleText(Text, Overlay.KEY_TEXT_FONT, KeyX, 0, Overlay.COLOR_TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    Overlay.DrawKVDivider()
    local X, Y = ValueX, 0
    local W, H = math.min(W2, SlotW / 1.1), SlotH

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

    local InnerText = GetText(Slot)
    local BackTextColor = LerpColor(Health / MaxHealth, MinColor, MaxColor)
    BackTextColor:SetSaturation(0.3)
    BackTextColor:SetBrightness(1)
    Overlay.SimpleText(InnerText, "ACF_OverlayHealthTextBackground", X + (W / 2), Y + (H / 2), BackTextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    Overlay.SimpleText(InnerText, "ACF_OverlayHealthTextBackground", X + (W / 2), Y + (H / 2), BackTextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    Overlay.SimpleText(InnerText, "ACF_OverlayHealthTextBackground", X + (W / 2), Y + (H / 2), BackTextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    Overlay.SimpleText(InnerText, "ACF_OverlayHealthText", X + (W / 2), Y + (H / 2), Overlay.COLOR_TEXT_DARK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
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