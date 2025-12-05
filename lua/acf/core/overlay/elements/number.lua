local Overlay = ACF.Overlay
local ELEMENT = {}

function ELEMENT.Render(_, Slot)
    local Unit = Slot.NumData >= 3 and Slot.Data[3] or ""
    Overlay.BasicKeyValueRender(Slot, nil, tostring(Slot.Data[2]) .. Unit)
end

function ELEMENT.PostRender(_, Slot)
    local Unit = Slot.NumData >= 3 and Slot.Data[3] or ""
    Overlay.BasicKeyValuePostRender(Slot, nil, tostring(Slot.Data[2]) .. Unit)
end

Overlay.DefineElementType("Number", ELEMENT)