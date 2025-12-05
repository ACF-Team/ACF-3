local Overlay = ACF.Overlay
local ELEMENT = {}

function ELEMENT.Render(_, Slot)
    Overlay.SimpleText(Slot.Data[1], Overlay.MAIN_FONT, 0, 0, Overlay.COLOR_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

Overlay.DefineElementType("Number", ELEMENT)