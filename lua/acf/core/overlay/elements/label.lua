local Overlay = ACF.Overlay
local ELEMENT = {}

function ELEMENT.Render(_, Slot)
    local X, Y = 0, 0
    for _, Line in pairs(string.Explode("\n", Slot.Data[1])) do
        if #Line == 0 then continue end
        local _, W, H = Overlay.SimpleText(Line, Overlay.MAIN_FONT, 0, Y, Overlay.COLOR_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        X = math.max(W, X)
        Y = Y + H
    end
    if X == 0 then Y = 0 end
    print(X, Y)
    Overlay.AppendSlotSize(X, Y)
end

Overlay.DefineElementType("Label", ELEMENT)