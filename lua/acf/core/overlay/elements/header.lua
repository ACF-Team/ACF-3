local Overlay = ACF.Overlay
local ELEMENT = {}

local Fonts = {
    {"ACF_OverlayHeaderBackground", "ACF_OverlayHeader"},
    {"ACF_OverlaySubHeaderBackground", "ACF_OverlaySubHeader"},
}

function ELEMENT.Render(_, Slot)
    local HeaderNum = Slot.NumData >= 2 and Slot.Data[2] or 1

    local Back = Fonts[HeaderNum] and Fonts[HeaderNum][1] or Fonts[1][1]
    local Fore = Fonts[HeaderNum] and Fonts[HeaderNum][2] or Fonts[1][2]

    local HeaderColor = Overlay.COLOR_TEXT:Copy()
    HeaderColor:SetBrightness(Lerp(1 - math.ease.InCirc(math.random()), 0.92, 1))
    local HeaderColorA = HeaderColor:Copy()
    HeaderColorA.a = 100
    Overlay.SimpleText(Slot.Data[1], Back, 0, 0, HeaderColorA, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    Overlay.SimpleText(Slot.Data[1], Fore, 0, 0, HeaderColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

Overlay.DefineElementType("Header", ELEMENT)