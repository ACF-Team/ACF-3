local Overlay = ACF.Overlay
local ELEMENT = {}

function ELEMENT.Render(_, Slot)
   -- Our horizontal positions here are dependent on the final size of everything.
    -- So those will be adjusted in PostRender, and we'll allocate our size here.

    local Text = Slot.NumData <= 2 and "Health" or Slot.Data[1]
    local W, H = Overlay.GetTextSize(Overlay.MAIN_FONT, Text)
    -- Allocate our slots size
    -- We want at least 160 pixels for a health bar
    local HW = math.min(160, W)
    Overlay.AppendSlotSize(HW, H)
    -- For key-values; push Key's size.
    Overlay.PushKeyWidth(W)
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
    return ColorCache:Copy()
end

function ELEMENT.PostRender(_, Slot)
    local _, SlotH  = Overlay.GetSlotSize()

    local Text      = Slot.NumData <= 2 and "Health"     or Slot.Data[1]
    local Health    = Slot.NumData <= 2 and Slot.Data[1] or Slot.Data[2]
    local MaxHealth = Slot.NumData <= 2 and Slot.Data[2] or Slot.Data[3]

    local Ratio = Health / MaxHealth

    Overlay.SimpleText(Text, Overlay.MAIN_FONT, Overlay.GetKVKeyX(), 0, Overlay.COLOR_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    Overlay.DrawKVDivider()
    local X, Y =  Overlay.GetKVDividerX(), 4
    local W, H = ((Overlay.GetKVValueX() - Overlay.GetKVKeyX()) - (Overlay.HORIZONTAL_EXTERIOR_PADDING / 2)) * Ratio, SlotH - 4
    -- Overlay.DrawOutlinedRect()
    Overlay.DrawRect(X, Y, W, H, LerpColor(Health / MaxHealth, HEALTH_BAD, HEALTH_GOOD))
end


Overlay.DefineElementType("Health", ELEMENT)