local Overlay = ACF.Overlay
local ELEMENT = {}

function ELEMENT.Render(_, Slot)
    Overlay.BasicLabel(Slot, 1, Overlay.COLOR_WARNING_TEXT)
end

Overlay.DefineElementType("Warning", ELEMENT)