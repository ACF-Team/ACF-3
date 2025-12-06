local Overlay = ACF.Overlay
local ELEMENT = {}

local function GetVectorStringPiecesFromSlot(Slot)
    local X, Y, Z
    if Slot.NumData == 2 then
        X, Y, Z = Slot.Data[2]:Unpack()
    else
        X, Y, Z = Slot.Data[2], Slot.Data[3], Slot.Data[4]
    end

    return ("x: %.2f   "):format(X), ("y: %.2f   "):format(Y), ("z: %.2f"):format(Z)
end

function ELEMENT.Render(_, Slot)
    -- Our horizontal positions here are dependent on the final size of everything.
    -- So those will be adjusted in PostRender, and we'll allocate our size here.

    local X, Y, Z = GetVectorStringPiecesFromSlot(Slot)

    local XW, XH = Overlay.GetTextSize(Overlay.VALUE_TEXT_FONT, X)
    local YW, YH = Overlay.GetTextSize(Overlay.VALUE_TEXT_FONT, Y)
    local ZW, ZH = Overlay.GetTextSize(Overlay.VALUE_TEXT_FONT, Z)

    local W1, H1 = Overlay.GetTextSize(Overlay.KEY_TEXT_FONT, Slot.Data[1] or "Key")

    local W = math.max(W1 * 2, (XW + YW + ZW) * 2)
    local H = math.max(H1, XH, YH, ZH)

    -- Allocate our slots size
    Overlay.AppendSlotSize(W, H)
    -- For key-values; push Key's size.
    Overlay.PushWidths(W1, XW + YW + ZW)
end

local X_COLOR = Color(255, 186, 186)
local Y_COLOR = Color(186, 255, 186)
local Z_COLOR = Color(186, 186, 255)

function ELEMENT.PostRender(_, Slot)
    local X, Y, Z = GetVectorStringPiecesFromSlot(Slot)

    local XW = Overlay.GetTextSize(Overlay.VALUE_TEXT_FONT, X)
    local YW = Overlay.GetTextSize(Overlay.VALUE_TEXT_FONT, Y)

    Overlay.SimpleText(Slot.Data[1], Overlay.KEY_TEXT_FONT, Overlay.GetKVKeyX(), 0, Overlay.COLOR_TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    Overlay.DrawKVDivider()
    Overlay.SimpleText(X, Overlay.VALUE_TEXT_FONT, Overlay.GetKVValueX(), 0, X_COLOR, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    Overlay.SimpleText(Y, Overlay.VALUE_TEXT_FONT, Overlay.GetKVValueX() + XW, 0, Y_COLOR, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    Overlay.SimpleText(Z, Overlay.VALUE_TEXT_FONT, Overlay.GetKVValueX() + XW + YW, 0, Z_COLOR, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

Overlay.DefineElementType("Coordinates", ELEMENT)