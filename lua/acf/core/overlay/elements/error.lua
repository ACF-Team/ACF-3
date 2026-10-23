local Overlay = ACF.Overlay
local ELEMENT = {}

function ELEMENT.Render(_, Slot)
    local W, H = Overlay.BasicLabel(Slot, 1, Overlay.COLOR_ERROR_TEXT)
    if Overlay.RenderHelp then Overlay.RenderHelp(Slot, W, H) end
end

Overlay.DefineElementType("Error", ELEMENT)