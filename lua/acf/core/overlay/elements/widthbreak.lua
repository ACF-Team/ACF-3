local Overlay = ACF.Overlay
local ELEMENT = {}

function ELEMENT.Render(_, _)
    Overlay.BreakWidths()
end

Overlay.DefineElementType("WidthBreak", ELEMENT)