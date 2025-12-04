-- The ACF overlay system. Contact March if something breaks horribly.

local Overlay = ACF.Overlay or {}
ACF.Overlay = Overlay

-- Helper for creating weakly-keyed LUT's
local WeakKeyMT = {__mode = 'k'}
local function WeaklyKeyedLUT() return setmetatable({}, WeakKeyMT) end

-- Serverside per-entity overlay state.
Overlay.EntityStates = Overlay.EntityStates or WeaklyKeyedLUT()
local EntityStates = Overlay.EntityStates

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
    -- Allocate a fully zeroed out state
    Overlay.GetPerPlayerPerEntityState(Player, Entity)
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
function Overlay.UpdateOverlay(Entity, State)
    EntityStates[Entity] = State -- This object is likely the same - the state shouldn't be recreated every time
    -- this is called, but just in case, we set the table index anyway here

    for Player, EntityStates in pairs(PerPlayerStates) do
        local PlayerState = EntityStates[Player]

        -- Is the entity being tracked by the player?
        if PlayerState and IsValid(Player) then
            -- Delta encode PlayerState to match State.
            Overlay.NetStart(Overlay.S2C_OVERLAY_DELTA_UPDATE)
            -- Delta encode PlayerState to match State, with the net library writer, and write the state changes to PlayerState itself.
            Overlay.DeltaEncodeState(PlayerState, State, net, true)
            net.Send(Player)
        end
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