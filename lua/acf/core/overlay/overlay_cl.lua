-- The ACF overlay system. Contact March if something breaks horribly.

local Overlay = ACF.Overlay or {}
ACF.Overlay = Overlay

local EntityStates = Overlay.EntityStates or {}
Overlay.EntityStates = EntityStates

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

function Overlay.UpdateOverlay(Entity, State, Full)
    EntityStates[Entity] = State -- This object is likely the same - the state shouldn't be recreated every time
    -- this is called, but just in case, we set the table index anyway here

    for Player, EntityStates in pairs(PerPlayerStates) do
        local PlayerState = EntityStates[Player]

        -- Is the entity being tracked by the player?
        if PlayerState and IsValid(Player) then
            -- Delta encode PlayerState to match State.
            Overlay.NetStart(Overlay.S2C_OVERLAY_DELTA_UPDATE)
            net.WriteBool(Full)
            net.WriteUInt(Entity:EntIndex(), MAX_EDICT_BITS)
            -- Delta encode PlayerState to match State, with the net library writer, and write the state changes to PlayerState itself.
            Overlay.DeltaEncodeState(PlayerState, State, net, true, Full)
            net.Send(Player)
        end
    end
end

-- Server update decoding
do
    local AwaitingQueue = {}
    hook.Add("NetworkEntityCreated", "ACF_Overlay_AwaitingNetworking", function(Ent)
        local Idx      = Ent:EntIndex()
        local Enqueued = AwaitingQueue[Idx]
        if not Enqueued then return end

        -- Don't use the result if its way out of date.
        local Now = CurTime()
        if (Now - Enqueued.Time) > 2 then AwaitingQueue[Idx] = nil return end

        Ent.ACF_OverlayState = Enqueued.State
        AwaitingQueue[Idx] = nil
    end)

    Overlay.NetReceive(Overlay.S2C_OVERLAY_DELTA_UPDATE, function()
        local Full  = net.ReadBool()
        local EntID = net.ReadUInt(MAX_EDICT_BITS)
        local Ent   = Entity(EntID)
        if IsValid(Ent) then
            -- The entity is fully valid, decode
            local OverlayState = Ent.ACF_OverlayState
            if not OverlayState then
                OverlayState = ACF.Overlay.State()
                Ent.ACF_OverlayState = OverlayState
            end

            Overlay.DeltaDecodeState(OverlayState, net)
        elseif Full then
            -- Because this is a full update, we can decode now, and cache for later.
            local State = ACF.Overlay.State()
            local StateQueue = {
                Time  = CurTime(),
                State = State
            }
            AwaitingQueue[EntID] = StateQueue
            Overlay.DeltaDecodeState(State, net)
        end
        -- Nothing can be done, just drop it
        -- Delta encoded requires a baseline, after all...
    end)
end

-- Rendering
do
    local Target = ACF.RenderContext.LookAt

    local TargetX, TargetY = 0, 0
    local TotalW, TotalH = 0, 0
    local TotalY         = 0
    local SlotW, SlotH = 0, 0
    local KeyWidth = 0
    local SlotDataCache  = {}
    local RenderCalls    = {}
    local NumRenderCalls = 0
    local CanAccessOverlaySize = false

    local OVERALL_RECT_PADDING      = 16
    local PER_SLOT_VERTICAL_PADDING = 8

    Overlay.OVERALL_RECT_PADDING = OVERALL_RECT_PADDING
    Overlay.PER_SLOT_VERTICAL_PADDING = PER_SLOT_VERTICAL_PADDING

    function Overlay.GetSlotDataCache(Idx)
        local Cache = SlotDataCache[Idx]
        if not Cache then
            Cache = {}
            SlotDataCache[Idx] = Cache
        end

        return Cache
    end

    function Overlay.ResetRenderState()
        TotalW, TotalH = 0, 0
        SlotW,  SlotH  = 0, 0
        TotalY = 0
        KeyWidth = 0
        NumRenderCalls = 0
    end

    function Overlay.PushSlotSizeToTotal(SlotIdx)
        local Cache = Overlay.GetSlotDataCache(SlotIdx)
        Cache.Y = TotalH
        Cache.W = SlotW
        Cache.H = SlotH
        Cache.KeyWidth = KeyWidth

        TotalW = math.max(TotalW, SlotW)
        TotalH = TotalH + SlotH + PER_SLOT_VERTICAL_PADDING
        SlotW,  SlotH  = 0, 0
        TotalY = TotalH
    end

    function Overlay.AppendSlotSize(W, H)
        SlotW = math.max(SlotW, W)
        SlotH = SlotH + H
    end

    function Overlay.PushKeyWidth(W)
        KeyWidth = math.max(KeyWidth, W)
    end

    function Overlay.BreakKeyWidth()
        KeyWidth = 0
    end

    function Overlay.GetCached(Idx)
        return RenderCalls[Idx]
    end

    function Overlay.CacheRenderCall(Method, ...)
        local Idx = NumRenderCalls + 1
        local CallStore = RenderCalls[Idx]
        if CallStore == nil then
            CallStore = {Data = {}, ArgC = 0}
            RenderCalls[Idx] = CallStore
        end

        CallStore.Method = Method
        local Count = select('#', ...)
        CallStore.ArgC = Count
        for I = 1, Count do
            CallStore.Data[I] = select(I, ...)
        end
        NumRenderCalls = Idx
        return Idx
    end

    function Overlay.GetTextSize(Font, Text)
        surface.SetFont(Font)
        local W, H = surface.GetTextSize(Text)
        return W, H
    end

    function Overlay.GetKeyWidth() return KeyWidth end

    function Overlay.GetOverlaySize()
        if not CanAccessOverlaySize then error("Can only call Overlay.GetOverlaySize in a post-render context.") end
        return TotalW, TotalH
    end

    function Overlay.GetTargetPos()
        return TargetX, TargetY
    end

    function Overlay.SimpleText(Text, Font, X, Y, Color, XAlign, YAlign)
        local W, H = Overlay.GetTextSize(Font, Text)

        -- Adjust bounds for non-centered alignment...
        if XAlign ~= TEXT_ALIGN_CENTER then W = W * 2 end
        Overlay.AppendSlotSize(W, H)
        return Overlay.CacheRenderCall(draw.SimpleText, Text, Font, X, Y + TotalY, Color, XAlign, YAlign)
    end

    local COLOR_PRIMARY_BACKGROUND     = Color(14, 49, 70, 200)
    local COLOR_TEXT                   = Color(236, 252, 255, 245)
    local COLOR_PRIMARY_COLOR          = Color(150, 200, 210, 245)
    local COLOR_SECONDARY_COLOR        = Color(60, 90, 105, 245)

    Overlay.COLOR_PRIMARY_BACKGROUND = COLOR_PRIMARY_BACKGROUND
    Overlay.COLOR_TEXT = COLOR_TEXT
    Overlay.COLOR_PRIMARY_COLOR = COLOR_PRIMARY_COLOR
    Overlay.COLOR_SECONDARY_COLOR = COLOR_SECONDARY_COLOR

    -- Todo
    Overlay.HEADER_FONT = "DermaLarge"
    Overlay.MAIN_FONT   = "DermaDefault"

    local OverlayMatrix = Matrix()
    local OverlayOffset = Vector(0, 0, 0)
    hook.Add("HUDPaint", "ACF_OverlayRender", function()
        if not IsValid(Target) then return end

        local State = Target.ACF_OverlayState
        if not State then return end

        local Pos = Target:GetPos():ToScreen()
        TargetX, TargetY = Pos.x, Pos.y

        Overlay.ResetRenderState()
        for Idx, ElementSlot in State:GetElementSlots() do
            local TypeIdx  = ElementSlot.Type
            local Type     = Overlay.GetElementType(TypeIdx)
            if Type.Render then
                Type.Render(Target, ElementSlot)
            end
            Overlay.PushSlotSizeToTotal(Idx)
        end

        local Clipping = DisableClipping(true)
        TotalW = TotalW + OVERALL_RECT_PADDING
        -- The subtraction of PER_SLOT_VERTICAL_PADDING here is to offset the last slots vertical padding.
        TotalH = (TotalH + OVERALL_RECT_PADDING) - PER_SLOT_VERTICAL_PADDING
        TotalH = math.max(TotalH, 0)

        -- Disable the barrier
        CanAccessOverlaySize = true
        -- Now that we have TotalW/TotalH, give elements a shot to resize and place things according to our current bounds.
        for Idx, ElementSlot in State:GetElementSlots() do
            local SlotCache = Overlay.GetSlotDataCache(Idx)
            TotalY = SlotCache.Y
            local TypeIdx  = ElementSlot.Type
            local Type     = Overlay.GetElementType(TypeIdx)
            if Type.PostRender then
                Type.PostRender(Target, ElementSlot)
            end
        end
        TotalY = TotalH
        CanAccessOverlaySize = false

        -- Draw background
        surface.SetDrawColor(COLOR_PRIMARY_BACKGROUND)
        surface.DrawRect(TargetX - (TotalW / 2), TargetY - (TotalH / 2), TotalW, TotalH)

        OverlayMatrix:Identity()
        OverlayOffset:SetUnpacked(TargetX, (TargetY - (TotalH / 2)) + PER_SLOT_VERTICAL_PADDING, 0)
        OverlayMatrix:Translate(OverlayOffset)
        cam.PushModelMatrix(OverlayMatrix)
        -- Draw all cached calls.
        for I = 1, NumRenderCalls do
            local Cache = RenderCalls[I]
            Cache.Method(unpack(Cache.Data, 1, Cache.ArgC))
        end
        cam.PopModelMatrix()
        DisableClipping(Clipping)
    end)

    hook.Add("ACF_RenderContext_LookAtChanged", "ACF_Overlay_DetermineLookat", function(_, New)
        if IsValid(New) then
            Overlay.StartOverlay(New, true)
        else
            Overlay.EndOverlay(true)
        end
        Target = New
    end)
end