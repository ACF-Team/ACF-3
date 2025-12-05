local Overlay = ACF.Overlay
local ELEMENT = {}

function ELEMENT.Render(_, _)
    Overlay.BreakKeyWidth()
end

Overlay.DefineElementType("WidthBreak", ELEMENT)