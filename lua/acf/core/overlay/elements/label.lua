local Overlay = ACF.Overlay
local ELEMENT = {}

function ELEMENT.Render(_, Slot)
    Overlay.BasicLabel(Slot)
end

Overlay.DefineElementType("Label", ELEMENT)