local Overlay = ACF.Overlay
local ELEMENT = {}

function ELEMENT.Render(_, Slot)
    -- Our horizontal positions here are dependent on the final size of everything.
    -- So those will be adjusted in PostRender, and we'll allocate our size here.
    local Unit = Slot.NumData >= 3 and Slot.Data[3] or ""
    local W1, H1 = Overlay.GetTextSize(Overlay.KEY_TEXT_FONT, Slot.Data[1] or "Key")
    local W2, H2 = Overlay.GetTextSize(Overlay.VALUE_TEXT_FONT, tostring(Slot.Data[2]) .. Unit)

    local W = math.max(W1, W2) + 8
    local H = math.max(H1, H2)

    -- Allocate our slots size
    Overlay.AppendSlotSize(W, H)
    -- For key-values; push Key's size.
    Overlay.PushWidths(W1, W2)
end

function ELEMENT.PostRender(_, Slot)
    local Unit = Slot.NumData >= 3 and Slot.Data[3] or ""
    Overlay.SimpleText(Slot.Data[1], Overlay.KEY_TEXT_FONT, Overlay.GetKVKeyX(), 0, Overlay.COLOR_TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    Overlay.DrawKVDivider()
    Overlay.SimpleText(tostring(Slot.Data[2]) .. Unit, Overlay.VALUE_TEXT_FONT, Overlay.GetKVValueX(), 0, Overlay.COLOR_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

Overlay.DefineElementType("Number", ELEMENT)