local Overlay = ACF.Overlay
local ELEMENT = {}

function ELEMENT.Render(_, Slot)
    Overlay.BasicKeyValueRender(Slot)
end

function ELEMENT.PostRender(_, Slot)
    Overlay.BasicKeyValuePostRender(Slot)
end

Overlay.DefineElementType("KeyValue", ELEMENT)