local Overlay = ACF.Overlay
local ELEMENT = {}

function ELEMENT.Render(_, _)
    Overlay.AppendSlotSize(0, 16)
end

Overlay.DefineElementType("Divider", ELEMENT)