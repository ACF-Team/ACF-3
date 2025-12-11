-- The ACF overlay system. Contact March if something breaks horribly.

local Overlay = ACF.Overlay or {}
ACF.Overlay = Overlay

-- Sending C2S messages
do
    function Overlay.StartOverlay(Entity, ClearPrevious)
        Entity.ACF_OverlayState = nil -- Reset for full update
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
local RegisterFonts
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
    -- local Prototype = GetFontForOS(2)
    local Conduit = GetFontForOS(3)

    function RegisterFonts(Scale)
        -- Designed for a 1080p monitor, this scales it down.
        Scale = Scale * (ScrH() / 1080)
        surface.CreateFont("ACF_OverlayHeaderBackground", {
            font = Conduit,
            size = 40 * Scale,
            weight = 900,
            blursize = 6,
            scanlines = 4,
            antialias = true,
            extended = true
        })
        surface.CreateFont("ACF_OverlayHeader", {
            font = Conduit,
            size = 40 * Scale,
            weight = 900,
            blursize = 0,
            scanlines = 2,
            antialias = true,
            extended = true
        })

        surface.CreateFont("ACF_OverlaySubHeaderBackground", {
            font = Conduit,
            size = 32 * Scale,
            weight = 500,
            blursize = 6,
            scanlines = 4,
            antialias = true,
            extended = true
        })
        surface.CreateFont("ACF_OverlaySubHeader", {
            font = Conduit,
            size = 32 * Scale,
            weight = 500,
            blursize = 0,
            scanlines = 2,
            antialias = true,
            extended = true
        })

        surface.CreateFont("ACF_OverlayText", {
            font = Conduit,
            size = 20 * Scale,
            weight = 500,
            blursize = 0,
            scanlines = 0,
            antialias = true,
            extended = true
        })
        surface.CreateFont("ACF_OverlayBoldText", {
            font = Conduit,
            size = 20 * Scale,
            weight = 900,
            blursize = 0,
            scanlines = 0,
            antialias = true,
            extended = true
        })
        surface.CreateFont("ACF_OverlayKeyText", {
            font = Conduit,
            size = 20 * Scale,
            weight = 900,
            blursize = 0,
            scanlines = 0,
            antialias = true,
            extended = true
        })
        surface.CreateFont("ACF_OverlayHealthText", {
            font = Conduit,
            size = 19 * Scale,
            weight = 900,
            blursize = 0,
            scanlines = 0,
            antialias = true,
            extended = true
        })
        surface.CreateFont("ACF_OverlaySubText", {
            font = Conduit,
            size = 15 * Scale,
            weight = 500,
            blursize = 0,
            scanlines = 0,
            antialias = true,
            extended = true
        })
        surface.CreateFont("ACF_OverlaySubKeyText", {
            font = Conduit,
            size = 15 * Scale,
            weight = 900,
            blursize = 0,
            scanlines = 0,
            antialias = true,
            extended = true
        })
    end
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
    local DoScaleAnimation  = true
    local DoAlphaAnimation  = true

    local OVERALL_RECT_PADDING        = 16
    local HORIZONTAL_EXTERIOR_PADDING = 92
    local PER_SLOT_VERTICAL_PADDING   = 8

    Overlay.OVERALL_RECT_PADDING = OVERALL_RECT_PADDING
    Overlay.HORIZONTAL_EXTERIOR_PADDING = HORIZONTAL_EXTERIOR_PADDING
    Overlay.PER_SLOT_VERTICAL_PADDING = PER_SLOT_VERTICAL_PADDING

    function Overlay.GetFadeInTime() return FadeInTime end
    function Overlay.GetFadeOutTime() return FadeOutTime end
    function Overlay.GetFadeTime() return FadeTime end

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
        Overlay.KeyValueRenderMode = 1
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
    function Overlay.DrawKVDivider(XPlus, FONT)
        Overlay.SimpleText(":", FONT or Overlay.MAIN_FONT, Overlay.GetKVDividerX() + (XPlus or 0), 0, Overlay.COLOR_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
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

    local function DrawTexturedRectRotated(X, Y, W, H, Rotation, Color)
        surface.SetDrawColor(Color)
        surface.DrawTexturedRectRotated(X, Y, W, H, Rotation)
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

    function Overlay.DrawTexturedRectRotated(X, Y, W, H, Rotation, Color)
        Overlay.AppendSlotSize(W, H)
        return Overlay.CacheRenderCall(DrawTexturedRectRotated, X, Y + TotalY, W, H, Rotation, Color)
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

    function Overlay.PushCustomClipPlane(Normal, Distance)
        return Overlay.CacheRenderCall(render.PushCustomClipPlane, Normal, Distance)
    end

    function Overlay.PopCustomClipPlane()
        return Overlay.CacheRenderCall(render.PopCustomClipPlane)
    end

    local COLOR_DROP_SHADOW
    local COLOR_PRIMARY_BACKGROUND
    local COLOR_TEXT
    local COLOR_TEXT_DARK
    local COLOR_PRIMARY_COLOR
    local COLOR_BORDER_LIGHT_COLOR
    local COLOR_SECONDARY_COLOR
    local COLOR_TERTIARY_COLOR
    local COLOR_SUCCESS_TEXT
    local COLOR_WARNING_TEXT = Color(0, 0, 0)
    local COLOR_ERROR_TEXT = Color(0, 0, 0)

    -- These are copied into warning/error text
    local COLOR_WARNING_TEXT_DEFAULT
    local COLOR_ERROR_TEXT_DEFAULT

    -- User convars
    local registered = {}
    local function RegisterCvar(name, default, desc)
        local str = default
        if IsColor(default) then
            str = ("%s %s %s %s"):format(default.r, default.g, default.b, default.a)
        else
            str = tostring(str)
        end
        registered[#registered + 1] = "acf_overlay_" .. string.lower(name)
        return CreateClientConVar("acf_overlay_" .. string.lower(name), str, true, false, "ACF Overlay; " .. desc .. ".")
    end

    local COLOR_DROP_SHADOW_CVAR        = RegisterCvar("COLOR_DROP_SHADOW",        Color(2, 9, 14, 227),     "the drop shadow color")
    local COLOR_PRIMARY_BACKGROUND_CVAR = RegisterCvar("COLOR_PRIMARY_BACKGROUND", Color(11, 32, 46, 204),    "the primary background color")
    local COLOR_TEXT_CVAR               = RegisterCvar("COLOR_TEXT",               Color(236, 252, 255, 245), "the primary text color")
    local COLOR_TEXT_DARK_CVAR          = RegisterCvar("COLOR_TEXT_DARK",          Color(32, 38, 39, 245),    "the dark text color")
    local COLOR_PRIMARY_COLOR_CVAR      = RegisterCvar("COLOR_PRIMARY_COLOR",      Color(150, 200, 210, 245), "the primary color")
    local COLOR_BORDER_LIGHT_COLOR_CVAR = RegisterCvar("COLOR_BORDER_LIGHT_COLOR", Color(150, 200, 210, 245), "the light border color")
    local COLOR_SECONDARY_COLOR_CVAR    = RegisterCvar("COLOR_SECONDARY_COLOR",    Color(60, 90, 105, 245),   "the secondary color")
    local COLOR_TERTIARY_COLOR_CVAR     = RegisterCvar("COLOR_TERTIARY_COLOR",     Color(84, 116, 131, 245),  "the tertiary color")
    local COLOR_SUCCESS_TEXT_CVAR       = RegisterCvar("COLOR_SUCCESS_TEXT",       Color(166, 255, 170),      "the success text color")
    local COLOR_WARNING_TEXT_CVAR       = RegisterCvar("COLOR_WARNING_TEXT",       Color(255, 220, 50),      "the warning text color")
    local COLOR_ERROR_TEXT_CVAR         = RegisterCvar("COLOR_ERROR_TEXT",         Color(255, 50, 50),      "the error text color")

    local SCALE_CVAR                    = RegisterCvar("SCALE",                    "1",      "scale multiplier")
    local SCALE_ANIM_CVAR               = RegisterCvar("DO_SCALE_ANIMATION",       "1",      "controls if scale is multiplied on fadein/fadeout")
    local ALPHA_ANIM_CVAR               = RegisterCvar("DO_ALPHA_ANIMATION",       "1",     "controls if alpha is multiplied on fadein/fadeout")

    local function SetupStyle()
        COLOR_DROP_SHADOW            = string.ToColor(COLOR_DROP_SHADOW_CVAR:GetString())
        COLOR_PRIMARY_BACKGROUND     = string.ToColor(COLOR_PRIMARY_BACKGROUND_CVAR:GetString())
        COLOR_TEXT                   = string.ToColor(COLOR_TEXT_CVAR:GetString())
        COLOR_TEXT_DARK              = string.ToColor(COLOR_TEXT_DARK_CVAR:GetString())
        COLOR_PRIMARY_COLOR          = string.ToColor(COLOR_PRIMARY_COLOR_CVAR:GetString())
        COLOR_BORDER_LIGHT_COLOR     = string.ToColor(COLOR_BORDER_LIGHT_COLOR_CVAR:GetString())
        COLOR_SECONDARY_COLOR        = string.ToColor(COLOR_SECONDARY_COLOR_CVAR:GetString())
        COLOR_TERTIARY_COLOR         = string.ToColor(COLOR_TERTIARY_COLOR_CVAR:GetString())
        COLOR_SUCCESS_TEXT           = string.ToColor(COLOR_SUCCESS_TEXT_CVAR:GetString())
        COLOR_WARNING_TEXT_DEFAULT   = string.ToColor(COLOR_WARNING_TEXT_CVAR:GetString())
        COLOR_ERROR_TEXT_DEFAULT     = string.ToColor(COLOR_ERROR_TEXT_CVAR:GetString())

        Overlay.HEADER_BACK_FONT     = "ACF_OverlayHeaderBackground"
        Overlay.HEADER_FONT          = "ACF_OverlayHeader"
        Overlay.SUBHEADER_BACK_FONT  = "ACF_OverlaySubHeaderBackground"
        Overlay.SUBHEADER_FONT       = "ACF_OverlaySubHeader"
        Overlay.BOLD_TEXT_FONT       = "ACF_OverlayBoldText"
        Overlay.KEY_TEXT_FONT        = "ACF_OverlayKeyText"
        Overlay.VALUE_TEXT_FONT      = "ACF_OverlayText"
        Overlay.SUBKEY_TEXT_FONT     = "ACF_OverlaySubKeyText"
        Overlay.SUBVALUE_TEXT_FONT   = "ACF_OverlaySubText"
        Overlay.MAIN_FONT            = "ACF_OverlayText"
        Overlay.PROGRESS_BAR_TEXT    = "ACF_OverlayHealthText"

        Overlay.COLOR_PRIMARY_BACKGROUND = COLOR_PRIMARY_BACKGROUND
        Overlay.COLOR_TEXT = COLOR_TEXT
        Overlay.COLOR_TEXT_DARK = COLOR_TEXT_DARK
        Overlay.COLOR_PRIMARY_COLOR = COLOR_PRIMARY_COLOR
        Overlay.COLOR_BORDER_LIGHT_COLOR = COLOR_BORDER_LIGHT_COLOR
        Overlay.COLOR_SECONDARY_COLOR = COLOR_SECONDARY_COLOR
        Overlay.COLOR_SUCCESS_TEXT = COLOR_SUCCESS_TEXT
        Overlay.COLOR_WARNING_TEXT = COLOR_WARNING_TEXT
        Overlay.COLOR_ERROR_TEXT = COLOR_ERROR_TEXT
        Overlay.COLOR_WARNING_TEXT_DEFAULT = COLOR_WARNING_TEXT_DEFAULT
        Overlay.COLOR_ERROR_TEXT_DEFAULT = COLOR_ERROR_TEXT_DEFAULT

        DoScaleAnimation = SCALE_ANIM_CVAR:GetBool()
        DoAlphaAnimation = ALPHA_ANIM_CVAR:GetBool()

        RegisterFonts(SCALE_CVAR:GetFloat())
    end
    SetupStyle()
    for _, v in ipairs(registered) do
        cvars.AddChangeCallback(v, SetupStyle)
    end


    local Overlays = Overlay.ActiveOverlays or {}
    Overlay.ActiveOverlays = Overlays

    -- Hack...
    local LookAtTarget = ACF.RenderContext and ACF.RenderContext.LookAt or NULL

    local OverlayMatrix = Matrix()
    local OverlayScale  = Vector(0, 0, 0)
    local OverlayOffset = Vector(0, 0, 0)
    function Overlay.GetOverlayOffset() return OverlayOffset end

    local ShouldDraw
    local ShouldAdjustOverlayForToolHelp
    local HideInfoBubble = ACF.HideInfoBubble

    function Overlay.DrawOverlay(State, Target, TargetX, TargetY, StartTime, StopTime, IsToolMode)
        Overlay.ResetRenderState()
        if DoScaleAnimation or DoAlphaAnimation then
            FadeInTime = math.Clamp((RealTime() - (StartTime or 0)) * 6, 0, 1)
            if StopTime then
                FadeOutTime = math.Clamp((RealTime() - (StopTime or 0)) * 9, 0, 1)
            else
                FadeOutTime = 0
            end
            FadeTime = FadeInTime - FadeOutTime
        else
            FadeInTime = 1
            FadeOutTime = StopTime ~= nil and 1 or 0
        end

        if FadeOutTime == 1 then
            -- Early exit
            return false
        end

        local Alpha = surface.GetAlphaMultiplier()
        if DoAlphaAnimation then
            surface.SetAlphaMultiplier(math.ease.InSine(FadeInTime) * math.ease.OutCirc(1 - FadeOutTime))
        end

        for Idx, ElementSlot in State:IterateElementSlots() do
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
        for Idx, ElementSlot in State:IterateElementSlots() do
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
        if DoScaleAnimation then
            XScale = 1 + (math.ease.InBack(FadeOutTime) * 0.3)
            YScale = math.ease.OutBack(math.ease.InCubic(FadeInTime)) - (math.ease.InBack(FadeOutTime))
        end

        -- Now that we know sizes, ensure we don't overflow past negative Y, and also add some buffer room
        -- so we don't overflow the text in the toolmenu
        local TempBoxY = TargetY - (TotalH / (2 / YScale))
        local MinimumY = 64
        if IsToolMode and ShouldAdjustOverlayForToolHelp:GetBool() then
            MinimumY = 216
        end
        if TempBoxY < MinimumY then
            -- How much?
            local Offset = MinimumY - TempBoxY
            TargetY = TargetY + Offset
        end


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
        surface.SetDrawColor(COLOR_BORDER_LIGHT_COLOR)
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
        local DROP_SHADOW_SIZE = 4
        surface.DrawRect(BoxX + BoxW, BoxY + DROP_SHADOW_SIZE, DROP_SHADOW_SIZE, BoxH)
        surface.DrawRect(BoxX + DROP_SHADOW_SIZE, BoxY + BoxH, BoxW - DROP_SHADOW_SIZE, DROP_SHADOW_SIZE)

        DisableClipping(Clipping)
        surface.SetAlphaMultiplier(Alpha)

        return true
    end

    hook.Add("HUDPaint", "ACF_OverlayRender", function()
        if HideInfoBubble() then return end
        if not next(Overlays) then return end
        if not ShouldDraw then
            ShouldDraw = GetConVar("cl_drawworldtooltips")
        end
        if not ShouldAdjustOverlayForToolHelp then
            ShouldAdjustOverlayForToolHelp = GetConVar("gmod_drawhelp")
        end
        if not ShouldDraw:GetBool() then return end

        local Ply = LocalPlayer()

        -- Update COLOR_ERROR_TEXT and COLOR_WARNING_TEXT
        COLOR_ERROR_TEXT:SetUnpacked(COLOR_ERROR_TEXT_DEFAULT:Unpack())
        COLOR_ERROR_TEXT:SetSaturation(Lerp((math.sin(RealTime() * 7) + 1) / 2, 0.4, 0.55))
        COLOR_WARNING_TEXT:SetUnpacked(COLOR_WARNING_TEXT_DEFAULT:Unpack())
        COLOR_WARNING_TEXT:SetSaturation(Lerp((math.sin(RealTime() * 7) + 1) / 2, 0.4, 0.55))

        local Weapon = Ply:GetActiveWeapon()
        local IsToolMode = IsValid(Weapon) and Weapon:GetClass() == "gmod_tool"

        for Target in pairs(Overlays) do
            if IsValid(Target) then
                local State = Target.ACF_OverlayState
                if not State then continue end

                TargetX, TargetY = ScrW() / 2, ScrH() / 2

                if not Overlay.DrawOverlay(State, Target, TargetX, TargetY, Target.ACF_OverlayStartTime, Target.ACF_OverlayStopTime, IsToolMode) then
                    Overlays[Target] = nil
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

function Overlay.BasicLabel(Slot, DataIndex, Color)
    local X, Y = 0, 0
    for _, Line in pairs(string.Explode("\n", Slot.Data[DataIndex or 1])) do
        if #Line == 0 then continue end
        local _, W, H = Overlay.SimpleText(Line, Overlay.BOLD_TEXT_FONT, 0, Y, Color or Overlay.COLOR_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        X = math.max(W, X)
        Y = Y + H
    end
    if X == 0 then Y = 0 end
    Overlay.AppendSlotSize(X, Y)
end

-- 1 is the primary mode. 2 is the secondary mode.
-- Sub keyvlues use 2 to move themselves in the value field.
Overlay.KeyValueRenderMode = 1

function Overlay.BasicKeyValueRender(Slot, Key, Value)
    -- Our horizontal positions here are dependent on the final size of everything.
    -- So those will be adjusted in PostRender, and we'll allocate our size here.

    local W1, H1, W2, H2
    if Overlay.KeyValueRenderMode == 1 then
        W1, H1 = Overlay.GetTextSize(Overlay.KEY_TEXT_FONT, Key or Slot.Data[1] or "Key")
        W2, H2 = Overlay.GetTextSize(Overlay.VALUE_TEXT_FONT, Value or Slot.Data[2] or "Value")
    else
        W1, H1 = Overlay.GetTextSize(Overlay.SUBKEY_TEXT_FONT, Key or Slot.Data[1] or "Key")
        W2, H2 = Overlay.GetTextSize(Overlay.SUBVALUE_TEXT_FONT, Value or Slot.Data[2] or "Value")
    end

    local W = math.max(W1 * 2, W2 * 2)
    local H = math.max(H1, H2)

    -- Allocate our slots size
    Overlay.AppendSlotSize(W, H)
    -- For key-values; push Key's size.
    Overlay.PushWidths(W1, W2)
end

function Overlay.BasicKeyValuePostRender(Slot, Key, Value)
    local KEY_FONT   = Overlay.KeyValueRenderMode == 1 and Overlay.KEY_TEXT_FONT or Overlay.SUBKEY_TEXT_FONT
    local VALUE_FONT = Overlay.KeyValueRenderMode == 1 and Overlay.VALUE_TEXT_FONT or Overlay.SUBVALUE_TEXT_FONT
    local X_OFFSET   = Overlay.KeyValueRenderMode == 1 and 0 or 8

    local X = Overlay.SimpleText(Key or Slot.Data[1] or "Key", KEY_FONT, Overlay.GetKVKeyX() + X_OFFSET, 0, Overlay.COLOR_TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    Overlay.DrawKVDivider(0, KEY_FONT)

    local X, Y = 0, 0
    for _, Line in pairs(string.Explode("\n", Value or Slot.Data[2] or "Value")) do
        if #Line == 0 then continue end
        local _, W, H = Overlay.SimpleText(Line, VALUE_FONT, Overlay.GetKVValueX(), Y + 1, Overlay.COLOR_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        X = math.max(W, X)
        Y = Y + H
    end

    return X
end