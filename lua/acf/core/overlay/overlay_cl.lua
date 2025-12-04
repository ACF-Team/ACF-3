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
    hook.Add("HUDPaint", "ACF_OverlayRender", function()
        if not IsValid(Target) then return end

        local State = Target.ACF_OverlayState
        if not State then return end
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