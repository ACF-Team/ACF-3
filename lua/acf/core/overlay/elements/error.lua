local Overlay = ACF.Overlay
local ELEMENT = {}

function ELEMENT.Render(_, Slot)
    Overlay.BasicLabel(Slot, 1, Overlay.COLOR_ERROR_TEXT)
end

Overlay.DefineElementType("Error", ELEMENT)