local Overlay = ACF.Overlay
local ELEMENT = {}

local function GetVectorStringFromSlot(Slot)
    local X, Y, Z
    if Slot.NumData == 2 then
        X, Y, Z = Slot.Data[2]:Unpack()
    else
        X, Y, Z = Slot.Data[2], Slot.Data[3], Slot.Data[4]
    end

    return ("%.1f x %.1f x %.1f"):format(X, Y, Z)
end

function ELEMENT.Render(_, Slot)
    Overlay.KeyValueRenderMode = 1
    Overlay.BasicKeyValueRender(Slot, nil, GetVectorStringFromSlot(Slot))
end

function ELEMENT.PostRender(_, Slot)
    Overlay.KeyValueRenderMode = 1
    Overlay.BasicKeyValuePostRender(Slot, nil, GetVectorStringFromSlot(Slot))
end

Overlay.DefineElementType("Size", ELEMENT)