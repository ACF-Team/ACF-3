local Overlay = ACF.Overlay
local ELEMENT = {}

local COG = Material("icon16/cog.png", "mips smooth")

function ELEMENT.Render(_, Slot)
    local Text = Slot.NumData >= 3 and Slot.Data[3] or ""
    Overlay.KeyValueRenderMode = 1
    Overlay.BasicKeyValueRender(Slot, nil, ACF.NiceNumber(Slot.Data[2], Decimals) .. Text)
end

function ELEMENT.PostRender(_, Slot)
    local Text = Slot.NumData >= 3 and Slot.Data[3] or ""
    local KEY_FONT   = Overlay.KeyValueRenderMode == 1 and Overlay.KEY_TEXT_FONT or Overlay.SUBKEY_TEXT_FONT
    Overlay.KeyValueRenderMode = 1
    Overlay.BasicKeyValuePostRender(Slot, nil, ACF.NiceNumber(Slot.Data[2], Decimals) .. Text)

    local XOffset = Overlay.GetTextSize(KEY_FONT, Slot.Data[1]) + 16

    local Ratio   = Slot.Data[2]
    local Legacy  = Slot.NumData >= 4 and Slot.Data[4]
    -- local Reverse = Slot.NumData >= 5 and Slot.Data[5]
    local InTime = ((RealTime() % 60) * 360) / 5
    local OutTime
    if Legacy then
        OutTime = InTime * Ratio
    else
        OutTime = InTime / Ratio
    end

    Overlay.SetMaterial(COG)
    Overlay.DrawTexturedRectRotated(-XOffset - 16 - 16 + 2, 12 + 3, 15, 15, InTime, color_white)
    Overlay.DrawTexturedRectRotated(-XOffset - 16, 12 - 3, 15, 15, -OutTime, color_white)
end

Overlay.DefineElementType("GearRatio", ELEMENT)