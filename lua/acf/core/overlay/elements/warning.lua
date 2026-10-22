local Overlay = ACF.Overlay
local ELEMENT = {}

function ELEMENT.Render(_, Slot)
    local W, H = Overlay.BasicLabel(Slot, 1, Overlay.COLOR_WARNING_TEXT)
    if Overlay.RenderHelp then Overlay.RenderHelp(Slot, W, H) end
end

Overlay.DefineElementType("Warning", ELEMENT)