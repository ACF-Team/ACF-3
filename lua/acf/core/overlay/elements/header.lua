local Overlay = ACF.Overlay
local ELEMENT = {}

local Fonts = {
    {"ACF_OverlayHeaderBackground", "ACF_OverlayHeader"},
    {"ACF_OverlaySubHeaderBackground", "ACF_OverlaySubHeader"},
}

--- Draws centered header text, HeaderNum 2 is a sub header. Returns the render call index, width and height
function Overlay.DrawHeaderText(Text, HeaderNum)
    local Back = Fonts[HeaderNum] and Fonts[HeaderNum][1] or Fonts[1][1]
    local Fore = Fonts[HeaderNum] and Fonts[HeaderNum][2] or Fonts[1][2]

    local HeaderColor = Overlay.COLOR_TEXT:Copy()
    HeaderColor:SetBrightness(Lerp(1 - math.ease.InCirc(math.random()), 0.92, 1))
    local HeaderColorA = HeaderColor:Copy()
    HeaderColorA.a = 100
    Overlay.SimpleText(Text, Back, 0, 0, HeaderColorA, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    return Overlay.SimpleText(Text, Fore, 0, 0, HeaderColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

function ELEMENT.Render(_, Slot)
    Overlay.DrawHeaderText(Slot.Data[1], Slot.NumData >= 2 and Slot.Data[2] or 1)
end

Overlay.DefineElementType("Header", ELEMENT)