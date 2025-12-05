local Overlay = ACF.Overlay
local ELEMENT = {}

function ELEMENT.Render(_, Slot)
   -- Our horizontal positions here are dependent on the final size of everything.
    -- So those will be adjusted in PostRender, and we'll allocate our size here.

    local Text = Slot.NumData <= 2 and "Health" or Slot.Data[1]
    local W, H = Overlay.GetTextSize(Overlay.KEY_TEXT_FONT, Text)
    -- Allocate our slots size
    -- We want at least 160 pixels for a health bar
    Overlay.AppendSlotSize(W, H)
    -- For key-values; push Key's size.
    Overlay.PushWidths(W, 160)
end

local HEALTH_BAD = Color(255, 40, 30)
local HEALTH_GOOD = Color(30, 255, 50)
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

function ELEMENT.PostRender(_, Slot)
    local _, SlotH  = Overlay.GetSlotSize()

    local Text      = Slot.NumData <= 2 and "Health"     or Slot.Data[1]
    local Health    = Slot.NumData <= 2 and Slot.Data[1] or Slot.Data[2]
    local MaxHealth = Slot.NumData <= 2 and Slot.Data[2] or Slot.Data[3]

    local Ratio = Health / MaxHealth

    local KeyX      = Overlay.GetKVKeyX()
    local ValueX    = Overlay.GetKVValueX()

    Overlay.SimpleText(Text, Overlay.KEY_TEXT_FONT, KeyX, 0, Overlay.COLOR_TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    Overlay.DrawKVDivider()
    local X, Y = ValueX, 1
    local W, H = 114, SlotH - 2

    local BarColor = LerpColor(Ratio, HEALTH_BAD, HEALTH_GOOD)
    Overlay.DrawRect(X, Y, W * Ratio, H, BarColor)
    Overlay.SetMaterial(FakeScanlines)
    local BarScanlinesColor = BarColor:Copy()
    BarScanlinesColor:SetBrightness(0.8)
    local Now = RealTime() % 1
    Overlay.DrawTexturedRectUV(X, Y, W * Ratio, H, 0, Now, 0, Now + 8, BarScanlinesColor)
    Overlay.NoTexture()

    local BackColor = LerpColor(Ratio, HEALTH_BAD, HEALTH_GOOD)
    BackColor:SetBrightness(0.3)
    Overlay.DrawOutlinedRect(X, Y, W * Ratio, H, BackColor, 2)

    local InnerText = ("%d/%d (%.1f%%)"):format(Health, MaxHealth, Ratio * 100)
    local BackTextColor = LerpColor(Health / MaxHealth, HEALTH_BAD, HEALTH_GOOD)
    BackTextColor:SetSaturation(0.6)
    Overlay.SimpleText(InnerText, "ACF_OverlayHealthTextBackground", X + (W / 2), Y + (H / 2), BackTextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    Overlay.SimpleText(InnerText, "ACF_OverlayHealthText", X + (W / 2), Y + (H / 2), Overlay.COLOR_TEXT_DARK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end


Overlay.DefineElementType("Health", ELEMENT)