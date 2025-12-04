-- The ACF overlay system. Contact March if something breaks horribly.

local Overlay = ACF.Overlay or {}
ACF.Overlay = Overlay

-- Sending C2S messages
do
    function Overlay.StartOverlay(Entity, ClearPrevious)
        Overlay.NetStart(Overlay.C2S_OVERLAY_START)
        net.WriteBool(ClearPrevious == true)
        net.WriteEntity(Entity)
        net.SendToServer()
    end

    function Overlay.EndOverlay(Entity)
        Overlay.NetStart(Overlay.C2S_OVERLAY_END)
        if Entity == true then
            net.WriteBool(true)
        else
            net.WriteBool(false)
            net.WriteEntity(Entity)
        end
        net.SendToServer()
    end
end

-- Server update decoding
do
    Overlay.NetReceive(Overlay.S2C_OVERLAY_FULL_UPDATE, function()

    end)

    Overlay.NetReceive(Overlay.S2C_OVERLAY_DELTA_UPDATE, function()

    end)
end

-- Rendering
do
    hook.Add("HUDPaint", "ACF_OverlayRender", function()

    end)

    hook.Add("ACF_RenderContext_LookAtChanged", "ACF_Overlay_DetermineLookat", function(_, New)
        Overlay.StartOverlay(New, true)
    end)
end