local Overlay = ACF.Overlay
local ELEMENT = {}

function ELEMENT.Render(_, Slot)
    local HeaderColor = Overlay.COLOR_TEXT:Copy()
    HeaderColor:SetBrightness(Lerp(1 - math.ease.InCirc(math.random()), 0.92, 1))
    local HeaderColorA = HeaderColor:Copy()
    HeaderColorA.a = 100
    Overlay.SimpleText(Slot.Data[1], Overlay.HEADER_BACK_FONT, 0, 0, HeaderColorA, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    Overlay.SimpleText(Slot.Data[1], Overlay.HEADER_FONT, 0, 0, HeaderColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

Overlay.DefineElementType("Header", ELEMENT)