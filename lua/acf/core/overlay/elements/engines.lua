local Overlay = ACF.Overlay

local function GetNum(Slot) return math.Round(Slot.Data[2] * (GetConVar("acf_menu_multiplytorquemult"):GetBool() and (ACF.GetServerData("TorqueMult") or 1) or 1)) end

do
    local ELEMENT = {}
    local function GetText(Num) return ("%s kW / %s hp"):format(Num, math.Round(Num * ACF.KwToHp)) end
    function ELEMENT.Render(_, Slot)
        Overlay.KeyValueRenderMode = 1
        Overlay.BasicKeyValueRender(_, Slot.Data[1], GetText(GetNum(Slot)))
    end

    function ELEMENT.PostRender(_, Slot)
        Overlay.KeyValueRenderMode = 1
        Overlay.BasicKeyValuePostRender(Slot, Slot.Data[1], GetText(GetNum(Slot)))
    end

    Overlay.DefineElementType("EnginePower", ELEMENT)
end
local Overlay = ACF.Overlay
do
    local ELEMENT = {}
    local function GetText(Num) return ("%s Nm / %s ft-lb"):format(Num, math.Round(Num * ACF.NmToFtLb)) end
    function ELEMENT.Render(_, Slot)
        Overlay.KeyValueRenderMode = 1
        Overlay.BasicKeyValueRender(_, Slot.Data[1], GetText(GetNum(Slot)))
    end

    function ELEMENT.PostRender(_, Slot)
        Overlay.KeyValueRenderMode = 1
        Overlay.BasicKeyValuePostRender(Slot, Slot.Data[1], GetText(GetNum(Slot)))
    end

    Overlay.DefineElementType("EngineTorque", ELEMENT)
end