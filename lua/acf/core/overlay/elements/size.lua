local Overlay = ACF.Overlay
local ELEMENT = {}

local function GetVectorStringFromSlot(Slot)
    local X, Y, Z
    if Slot.NumData == 2 then
        X, Y, Z = Slot.Data[2]:Unpack()
    else
        X, Y, Z = Slot.Data[2], Slot.Data[3], Slot.Data[4]
    end

    return ("%.1f x %.1f x %.1f"):format(X, Y, Z)
end

function ELEMENT.Render(_, Slot)
    -- Our horizontal positions here are dependent on the final size of everything.
    -- So those will be adjusted in PostRender, and we'll allocate our size here.

    local W1, H1 = Overlay.GetTextSize(Overlay.KEY_TEXT_FONT, Slot[1] or "Key")
    local W2, H2 = Overlay.GetTextSize(Overlay.VALUE_TEXT_FONT, GetVectorStringFromSlot(Slot))

    local W = math.max(W1, W2) + 8
    local H = math.max(H1, H2)

    -- Allocate our slots size
    Overlay.AppendSlotSize(W, H)
    -- For key-values; push Key's size.
    Overlay.PushKeyWidth(W1)
end

function ELEMENT.PostRender(_, Slot)
    Overlay.SimpleText(Slot.Data[1], Overlay.KEY_TEXT_FONT, Overlay.GetKVKeyX(), 0, Overlay.COLOR_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    Overlay.DrawKVDivider()
    Overlay.SimpleText(GetVectorStringFromSlot(Slot), Overlay.VALUE_TEXT_FONT, Overlay.GetKVValueX(), 0, Overlay.COLOR_TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
end

Overlay.DefineElementType("Size", ELEMENT)