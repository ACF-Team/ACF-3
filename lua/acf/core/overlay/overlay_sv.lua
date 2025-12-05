-- The ACF overlay system. Contact March if something breaks horribly.

local Overlay = ACF.Overlay or {}
ACF.Overlay = Overlay

-- Helper for creating weakly-keyed LUT's
local WeakKeyMT = {__mode = 'k'}
local function WeaklyKeyedLUT() return setmetatable({}, WeakKeyMT) end

-- Serverside per-player-per-entity delta state.
-- When StartOverlay is called, this triggers a full update, ie. their state for that entity is wiped and set to zero-delta,
-- and a full update packet is written to the player. EndOverlay also does the same thing but fully clears it.
Overlay.PerPlayerStates = Overlay.PerPlayerStates or WeaklyKeyedLUT()
local PerPlayerStates = Overlay.PerPlayerStates

-- Get per-player entity states.
function Overlay.GetPerPlayerEntityStates(Player)
    local PlayerEntityStates = PerPlayerStates[Player]
    if not PlayerEntityStates then
        PlayerEntityStates = WeaklyKeyedLUT()
        PerPlayerStates[Player] = PlayerEntityStates
    end

    return PlayerEntityStates
end

-- Get a per-player, per-entity state.
function Overlay.GetPerPlayerPerEntityState(Player, Entity)
    local PlayerEntityStates = Overlay.GetPerPlayerEntityStates(Player)
    local EntityState = PlayerEntityStates[Entity]
    if not EntityState then
        -- Allocate a new state. 
        EntityState = Overlay.State()
        PlayerEntityStates[Entity] = EntityState
    end

    return EntityState
end

function Overlay.DestroyPerPlayerPerEntityState(Player, Entity)
    local PlayerEntityStates = Overlay.GetPerPlayerEntityStates(Player)
    PlayerEntityStates[Entity] = nil
end

-- Start a player viewing an overlay on a particular entity.
function Overlay.StartOverlay(Player, Entity)
    if not IsValid(Entity) then return end
    if not Entity.ACF_UpdateOverlayState then return end
    -- Allocate a fully zeroed out state
    local PlayerState = Overlay.GetPerPlayerPerEntityState(Player, Entity)

    local OverlayState = Entity.GetOverlayState
    if OverlayState then
        OverlayState = OverlayState(Entity)
    end

    ACF.Overlay.UpdateOverlayForPlayer(Entity, Player, OverlayState, PlayerState, true)
end

-- End a player viewing an overlay on a particular entity.
-- If Entity is true, then this will destroy all overlays for that player.
function Overlay.EndOverlay(Player, Entity)
    if Entity == true then
        local PlayerEntityStates = Overlay.GetPerPlayerEntityStates(Player)
        table.Empty(PlayerEntityStates)
        return
    end

    if not IsValid(Entity) then return end

    -- Destroy state
    Overlay.DestroyPerPlayerPerEntityState(Player, Entity)
end

-- Entities call this function serverside to update their overlay elements.
function Overlay.UpdateOverlayForPlayer(Entity, Player, EntityState, PlayerState, Full)
    -- Is the entity being tracked by the player?
    if PlayerState and IsValid(Player) then
        -- Delta encode PlayerState to match EntityState.
        Overlay.NetStart(Overlay.S2C_OVERLAY_DELTA_UPDATE)
        net.WriteBool(Full)
        net.WriteUInt(Entity:EntIndex(), MAX_EDICT_BITS)
        -- Delta encode PlayerState to match EntityState, with the net library writer, and write the state changes to PlayerState itself.
        Overlay.DeltaEncodeState(PlayerState, EntityState, net, true, Full)
        net.Send(Player)
    end
end

function Overlay.UpdateOverlay(Entity, State, Full)
    for Player, EntityStates in pairs(PerPlayerStates) do
        Overlay.UpdateOverlayForPlayer(Entity, Player, State, EntityStates[Entity], Full)
    end
end

Overlay.NetReceive(Overlay.C2S_OVERLAY_START, function(_, Player)
    local StopPrevious = net.ReadBool()
    if StopPrevious then
        Overlay.EndOverlay(Player, true)
    end

    local Entity = net.ReadEntity()
    Overlay.StartOverlay(Player, Entity)
end)

Overlay.NetReceive(Overlay.C2S_OVERLAY_END, function(_, Player)
    local StopAll = net.ReadBool()
    if StopAll then
        Overlay.EndOverlay(Player, true)
    else
        local Entity = net.ReadEntity()
        Overlay.EndOverlay(Player, Entity)
    end
end)