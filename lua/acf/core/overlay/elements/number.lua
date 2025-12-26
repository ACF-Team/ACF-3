local Overlay = ACF.Overlay
local ELEMENT = {}

function ELEMENT.Render(_, Slot)
    local Unit = Slot.NumData >= 3 and Slot.Data[3] or ""
    local Decimals = Slot.NumData >= 4 and Slot.Data[4] or 2
    Overlay.KeyValueRenderMode = 1
    Overlay.BasicKeyValueRender(Slot, nil, ACF.NiceNumber(Slot.Data[2], Decimals) .. Unit)
end

function ELEMENT.PostRender(_, Slot)
    local Unit = Slot.NumData >= 3 and Slot.Data[3] or ""
    local Decimals = Slot.NumData >= 4 and Slot.Data[4] or 2
    Overlay.KeyValueRenderMode = 1
    Overlay.BasicKeyValuePostRender(Slot, nil, ACF.NiceNumber(Slot.Data[2], Decimals) .. Unit)
end

Overlay.DefineElementType("Number", ELEMENT)