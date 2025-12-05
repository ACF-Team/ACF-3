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
    -- TODO: Why is the shared file not providing this?!?!?!?
    Overlay.MAX_ELEMENTS               = 128
    Overlay.MAX_ELEMENT_BITS           = 7

    Overlay.MAX_ELEMENT_DATA           = 64
    Overlay.MAX_ELEMENT_DATA_BITS      = 6

    Overlay.C2S_OVERLAY_START          = 0
    Overlay.C2S_OVERLAY_END            = 1
    Overlay.S2C_OVERLAY_DELTA_UPDATE   = 2

    local OVERLAY_MSG_TYPE_BITS      = 2
    local OVERLAY_MSG_STRINGTABLEIDX = "ACF_RequestOverlay"
    Overlay.Receivers = Overlay.Receivers or {}
    local Receivers = Overlay.Receivers

    function Overlay.NetStart(MessageType, Unreliable)
        net.Start(OVERLAY_MSG_STRINGTABLEIDX, Unreliable)
        net.WriteUInt(MessageType, OVERLAY_MSG_TYPE_BITS)
    end

    function Overlay.NetReceive(Type, Func)
        Receivers[Type] = Func
    end

    net.Receive(OVERLAY_MSG_STRINGTABLEIDX, function(...)
        local Type = net.ReadUInt(OVERLAY_MSG_TYPE_BITS)
        local Recv = Receivers[Type]
        if Recv then
            Recv(...)
        end
    end)

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

-- Fonts
do
    -- "On Linux, using the embedded font name tends to be unreliable. I recommend using the font's (case-sensitive) file name, 
    --  like 'Roboto-Regular.ttf', instead. You can use system.IsLinux to help determine which name to use."
    --      - https://wiki.facepunch.com/gmod/Finding_the_Font_Name
    local Fonts = {
        {"Segment16", "16segments-basic.ttf"},
        {"Prototype", "prototype.ttf"},
        {"Conduit ITC Light", "conduit.ttf"},
    }

    local function GetFontForOS(I) return not system.IsWindows() and Fonts[I][2] or Fonts[I][1] end
    local Prototype = GetFontForOS(2)
    local Conduit = GetFontForOS(3)

    surface.CreateFont("ACF_OverlayHeaderBackground", {
        font = Conduit,
        size = 40,
        weight = 900,
        blursize = 6,
        scanlines = 4,
        antialias = true,
        extended = true
    })
    surface.CreateFont("ACF_OverlayHeader", {
        font = Conduit,
        size = 40,
        weight = 900,
        blursize = 0,
        scanlines = 2,
        antialias = true,
        extended = true
    })
    surface.CreateFont("ACF_OverlayText", {
        font = Conduit,
        size = 20,
        weight = 500,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        extended = true
    })
    surface.CreateFont("ACF_OverlayKeyText", {
        font = Conduit,
        size = 20,
        weight = 900,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        extended = true
    })
    surface.CreateFont("ACF_OverlayHealthText", {
        font = Prototype,
        size = 19,
        weight = 500,
        blursize = 0,
        scanlines = 2,
        antialias = true,
        extended = true
    })
    surface.CreateFont("ACF_OverlayHealthTextBackground", {
        font = Prototype,
        size = 19,
        weight = 500,
        blursize = 2,
        scanlines = 2,
        antialias = true,
        extended = true
    })
end


-- Rendering
do
    local TargetX, TargetY = 0, 0
    local TotalW, TotalH = 0, 0
    local TotalY         = 0
    local SlotW, SlotH = 0, 0
    local KeyWidth, ValueWidth = 0, 0
    local LastKeyBreakIdx = 0
    local SlotDataCache  = {}
    local RenderCalls    = {}
    local NumRenderCalls = 0
    local CurrentSlotIdx = 0
    local CanAccessOverlaySize = false
    local FadeInTime  = 0
    local FadeOutTime = 0
    local FadeTime    = 0

    local OVERALL_RECT_PADDING        = 16
    local HORIZONTAL_EXTERIOR_PADDING = 92
    local PER_SLOT_VERTICAL_PADDING   = 8

    Overlay.OVERALL_RECT_PADDING = OVERALL_RECT_PADDING
    Overlay.HORIZONTAL_EXTERIOR_PADDING = HORIZONTAL_EXTERIOR_PADDING
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
        ValueWidth = 0
        CurrentSlotIdx = 0
        LastKeyBreakIdx = 0
        NumRenderCalls = 0
    end

    function Overlay.PushSlotSizeToTotal(SlotIdx)
        local Cache = Overlay.GetSlotDataCache(SlotIdx)
        Cache.Y = TotalH
        Cache.W = SlotW
        Cache.H = SlotH
        Cache.KeyWidth = KeyWidth
        Cache.ValueWidth = ValueWidth

        TotalW = math.max(TotalW, SlotW)
        TotalH = TotalH + SlotH + PER_SLOT_VERTICAL_PADDING
        SlotW,  SlotH  = 0, 0
        TotalY = TotalH
    end

    function Overlay.AppendSlotSize(W, H)
        SlotW = math.max(SlotW, W)
        SlotH = math.max(SlotH, H)
    end

    -- This function keeps every slot that came before it (up to the last key break idx)
    -- up to date with the current key width. 
    function Overlay.PushWidths(KeyW, ValueW)
        KeyWidth   = math.max(KeyWidth, KeyW)
        ValueWidth = math.max(ValueWidth, ValueW)
        for I = CurrentSlotIdx - 1, math.max(LastKeyBreakIdx, 1), -1 do
            Overlay.GetSlotDataCache(I).KeyWidth = KeyWidth
            Overlay.GetSlotDataCache(I).ValueWidth = ValueWidth
        end
    end

    function Overlay.GetKeyValueWidth() return KeyWidth + ValueWidth + 64 end

    function Overlay.GetKVKeyX()
        return -16
    end
    function Overlay.GetKVValueX()
        return 16
    end
    function Overlay.GetKVDividerX()
        return 0
    end
    function Overlay.DrawKVDivider()
        Overlay.SimpleText(":", Overlay.MAIN_FONT, Overlay.GetKVDividerX(), 0, Overlay.COLOR_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    function Overlay.BreakWidths()
        KeyWidth = 0
        ValueWidth = 0
        LastKeyBreakIdx = CurrentSlotIdx
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
    function Overlay.GetValueWidth() return ValueWidth end

    function Overlay.GetOverlaySize()
        if not CanAccessOverlaySize then error("Can only call Overlay.GetOverlaySize in a post-render context.") end
        return TotalW, TotalH
    end

    function Overlay.GetSlotSize()
        return SlotW, SlotH
    end

    function Overlay.GetTargetPos()
        return TargetX, TargetY
    end

    function Overlay.SimpleText(Text, Font, X, Y, Color, XAlign, YAlign)
        local W, H = Overlay.GetTextSize(Font, Text)

        -- Adjust bounds for non-centered alignment...
        if XAlign ~= TEXT_ALIGN_CENTER then W = W * 2 end
        Overlay.AppendSlotSize(W, H)
        return Overlay.CacheRenderCall(draw.SimpleText, Text, Font, X, Y + TotalY, Color, XAlign, YAlign), W, H
    end

    local function DrawRect(X, Y, W, H, Color)
        surface.SetDrawColor(Color)
        surface.DrawRect(X, Y, W, H)
    end

    local function DrawTexturedRectUV(X, Y, W, H, SU, SV, EU, EV, Color)
        surface.SetDrawColor(Color)
        surface.DrawTexturedRectUV(X, Y, W, H, SU, SV, EU, EV)
    end

    local function DrawTexturedRect(X, Y, W, H, Color)
        surface.SetDrawColor(Color)
        surface.DrawTexturedRect(X, Y, W, H)
    end

    local function DrawOutlinedRect(X, Y, W, H, Color, Thickness)
        surface.SetDrawColor(Color)
        surface.DrawOutlinedRect(X, Y, W, H, Thickness or 1)
    end

    function Overlay.DrawRect(X, Y, W, H, Color)
        Overlay.AppendSlotSize(W, H)
        return Overlay.CacheRenderCall(DrawRect, X, Y + TotalY, W, H, Color)
    end

    function Overlay.DrawTexturedRect(X, Y, W, H, Color)
        Overlay.AppendSlotSize(W, H)
        return Overlay.CacheRenderCall(DrawTexturedRect, X, Y + TotalY, W, H, Color)
    end

    function Overlay.DrawTexturedRectUV(X, Y, W, H, SU, SV, EU, EV, Color)
        Overlay.AppendSlotSize(W, H)
        return Overlay.CacheRenderCall(DrawTexturedRectUV, X, Y + TotalY, W, H, SU, SV, EU, EV, Color)
    end

    function Overlay.DrawOutlinedRect(X, Y, W, H, Color, Thickness)
        Overlay.AppendSlotSize(W, H)
        return Overlay.CacheRenderCall(DrawOutlinedRect, X, Y + TotalY, W, H, Color, Thickness)
    end

    function Overlay.SetMaterial(Mat)
        return Overlay.CacheRenderCall(surface.SetMaterial, Mat)
    end

    function Overlay.NoTexture()
        return Overlay.CacheRenderCall(draw.NoTexture)
    end

    function Overlay.DrawOutlinedRect(X, Y, W, H, Color, Thickness)
        Overlay.AppendSlotSize(W, H)
        return Overlay.CacheRenderCall(DrawOutlinedRect, X, Y + TotalY, W, H, Color, Thickness)
    end

    local COLOR_DROP_SHADOW            = Color(2, 9, 14, 227)
    local COLOR_PRIMARY_BACKGROUND     = Color(14, 49, 70, 200)
    local COLOR_TEXT                   = Color(236, 252, 255, 245)
    local COLOR_TEXT_DARK              = Color(32, 38, 39, 245)
    local COLOR_PRIMARY_COLOR          = Color(150, 200, 210, 245)
    local COLOR_SECONDARY_COLOR        = Color(60, 90, 105, 245)
    local COLOR_TERTIARY_COLOR         = Color(84, 116, 131, 245)
    local COLOR_ERROR_TEXT             = Color(255, 255, 255)

    Overlay.COLOR_PRIMARY_BACKGROUND = COLOR_PRIMARY_BACKGROUND
    Overlay.COLOR_TEXT = COLOR_TEXT
    Overlay.COLOR_TEXT_DARK = COLOR_TEXT_DARK
    Overlay.COLOR_PRIMARY_COLOR = COLOR_PRIMARY_COLOR
    Overlay.COLOR_SECONDARY_COLOR = COLOR_SECONDARY_COLOR

    -- Todo
    Overlay.HEADER_BACK_FONT = "ACF_OverlayHeaderBackground"
    Overlay.HEADER_FONT = "ACF_OverlayHeader"
    Overlay.KEY_TEXT_FONT = "ACF_OverlayKeyText"
    Overlay.VALUE_TEXT_FONT = "ACF_OverlayText"
    Overlay.MAIN_FONT = "ACF_OverlayText"

    local Overlays = Overlay.ActiveOverlays or {}
    Overlay.ActiveOverlays = Overlays

    -- Hack...
    local LookAtTarget = ACF.RenderContext and ACF.RenderContext.LookAt or NULL

    local OverlayMatrix = Matrix()
    local OverlayScale  = Vector(0, 0, 0)
    local OverlayOffset = Vector(0, 0, 0)
    hook.Add("HUDPaint", "ACF_OverlayRender", function()
        -- Update COLOR_ERROR_TEXT
        COLOR_ERROR_TEXT:SetUnpacked(255, 50, 50)
        COLOR_ERROR_TEXT:SetSaturation(Lerp((math.sin(RealTime()) + 1) / 2, 0.2, 0.4))
        for Target in pairs(Overlays) do
            if not IsValid(Target) then
                Overlays[Target] = nil
            else
                local State = Target.ACF_OverlayState
                if not State then return end

                TargetX, TargetY = ScrW() / 2, ScrH() / 2

                Overlay.ResetRenderState()
                FadeInTime = math.Clamp((RealTime() - (Target.ACF_OverlayStartTime or 0)) * 6, 0, 1)
                if Target.ACF_OverlayStopTime then
                    FadeOutTime = math.Clamp((RealTime() - (Target.ACF_OverlayStopTime or 0)) * 9, 0, 1)
                else
                    FadeOutTime = 0
                end
                FadeTime = FadeInTime - FadeOutTime
                if FadeOutTime == 1 then
                    -- Early exit
                    Overlays[Target] = nil
                else
                    local Alpha = surface.GetAlphaMultiplier()
                    surface.SetAlphaMultiplier(math.ease.InSine(FadeInTime))

                    for Idx, ElementSlot in State:GetElementSlots() do
                        CurrentSlotIdx = Idx
                        local TypeIdx  = ElementSlot.Type
                        local Type     = Overlay.GetElementType(TypeIdx)
                        if Type.Render then
                            Type.Render(Target, ElementSlot)
                        end
                        Overlay.PushSlotSizeToTotal(Idx)
                    end

                    local Clipping = DisableClipping(true)
                    TotalW = TotalW + OVERALL_RECT_PADDING + HORIZONTAL_EXTERIOR_PADDING
                    -- The subtraction of PER_SLOT_VERTICAL_PADDING here is to offset the last slots vertical padding.
                    TotalH = (TotalH + OVERALL_RECT_PADDING) - PER_SLOT_VERTICAL_PADDING
                    TotalH = math.max(TotalH, 0)

                    -- Disable the barrier
                    CanAccessOverlaySize = true
                    -- Now that we have TotalW/TotalH, give elements a shot to resize and place things according to our current bounds.
                    for Idx, ElementSlot in State:GetElementSlots() do
                        CurrentSlotIdx = Idx
                        -- Reload slot state for post-render.
                        local SlotCache = Overlay.GetSlotDataCache(Idx)
                        TotalY     = SlotCache.Y
                        SlotW      = SlotCache.W
                        SlotH      = SlotCache.H
                        KeyWidth   = SlotCache.KeyWidth
                        ValueWidth = SlotCache.ValueWidth
                        -- Post render
                        local TypeIdx  = ElementSlot.Type
                        local Type     = Overlay.GetElementType(TypeIdx)
                        if Type.PostRender then
                            Type.PostRender(Target, ElementSlot)
                        end
                    end
                    TotalY = TotalH
                    CanAccessOverlaySize = false

                    -- Move TargetX, TargetY to be on the left side
                    TargetX = TargetX - (TotalW / 2) - 32
                    TargetY = TargetY - (TotalH / 2) - 32

                    -- Set up scaling
                    OverlayMatrix:Identity()
                    local XScale = 1
                    local YScale = 1

                    -- Cool animations for scaling
                    XScale = 1 + (math.ease.InBack(FadeOutTime) * 0.3)
                    YScale = math.ease.OutBack(math.ease.InCubic(FadeInTime)) - (math.ease.InBack(FadeOutTime))

                    OverlayScale:SetUnpacked(XScale, YScale, 1)
                    OverlayOffset:SetUnpacked(math.Round(TargetX), math.Round((TargetY - (TotalH / (2 / YScale))) + PER_SLOT_VERTICAL_PADDING), 0)
                    OverlayMatrix:Translate(OverlayOffset)
                    OverlayMatrix:Scale(OverlayScale)

                    -- Draw background
                    surface.SetDrawColor(COLOR_PRIMARY_BACKGROUND)
                    local BoxX, BoxY, BoxW, BoxH = TargetX - (TotalW / (2 / XScale)), TargetY - (TotalH / (2 / YScale)), TotalW * XScale, TotalH * YScale
                    surface.DrawRect(BoxX, BoxY, BoxW, BoxH)

                    cam.PushModelMatrix(OverlayMatrix)
                    -- Draw all cached calls.
                    for I = 1, NumRenderCalls do
                        local Cache = RenderCalls[I]
                        Cache.Method(unpack(Cache.Data, 1, Cache.ArgC))
                    end
                    cam.PopModelMatrix()

                    local BORDER_SIZE = 2
                    surface.SetDrawColor(COLOR_PRIMARY_COLOR)
                    surface.DrawRect(BoxX, BoxY, BoxW, BORDER_SIZE)
                    surface.DrawRect(BoxX, BoxY, BORDER_SIZE, BoxH)
                    surface.SetDrawColor(COLOR_TERTIARY_COLOR)
                    surface.DrawRect(BoxX + BORDER_SIZE, BoxY + BoxH - BORDER_SIZE, BoxW - BORDER_SIZE, BORDER_SIZE)
                    surface.DrawRect(BoxX + BoxW - BORDER_SIZE, BoxY + BORDER_SIZE, BORDER_SIZE, BoxH - BORDER_SIZE)

                    -- This kinda sucks... todo
                    surface.DrawRect(BoxX + BORDER_SIZE - 1, BoxY + BoxH - 1, BoxW - BORDER_SIZE, 1)
                    surface.DrawRect(BoxX + BoxW - 1, BoxY + BORDER_SIZE - 1, 1, BoxH - BORDER_SIZE)

                    -- Draw a drop shadow
                    surface.SetDrawColor(COLOR_DROP_SHADOW)
                    local DROP_SHADOW_SIZE = 2
                    surface.DrawRect(BoxX + BoxW, BoxY, DROP_SHADOW_SIZE, BoxH + DROP_SHADOW_SIZE)
                    surface.DrawRect(BoxX, BoxY + BoxH, BoxW, DROP_SHADOW_SIZE)

                    DisableClipping(Clipping)
                    surface.SetAlphaMultiplier(Alpha)
                end
            end
        end
    end)

    hook.Add("ACF_RenderContext_LookAtChanged", "ACF_Overlay_DetermineLookat", function(_, New)
        if IsValid(New) then
            Overlays[New] = true
            New.ACF_OverlayStartTime = RealTime()
            New.ACF_OverlayStopTime  = nil
            Overlay.StartOverlay(New, true)
        else
            Overlay.EndOverlay(true)
        end
        if LookAtTarget ~= New then
            if IsValid(LookAtTarget) then
                LookAtTarget.ACF_OverlayStopTime = RealTime()
            end
            LookAtTarget = New
        end
    end)
end