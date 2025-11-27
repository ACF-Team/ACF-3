local ApplyTo = {
    ["acf_gun"] = true,
    ["acf_rack"] = true,
    ["acf_piledriver"] = true,
}

local ResetTime
local function ResetContraptionTimes(Contraption)
    for Class in pairs(ApplyTo) do
        local Ents = Contraption:EntitiesByClass(Class)
        for Ent in pairs(Ents) do
            ResetTime(Ent)
        end
    end
end

-- CFW hooks to initialize state and handle splitting
hook.Add("cfw.contraption.created", "ACF_CFW_TrackPlayersInContraptions", function(Contraption)
    Contraption.ACF_TrackPlayers = {}
end)

local PlayersCopy = {}
hook.Add("cfw.contraption.split", "ACF_CFW_TrackPlayersInContraptions", function(ParentContraption, ChildContraption)
    ParentContraption.ACF_TrackPlayers = ParentContraption.ACF_TrackPlayers or {}
    ChildContraption.ACF_TrackPlayers  = ChildContraption.ACF_TrackPlayers or {}

    -- For each player in the parent contraption, reassign it if need be
    for k in pairs(PlayersCopy) do PlayersCopy[k] = nil end
    for k, v in pairs(ParentContraption.ACF_TrackPlayers) do PlayersCopy[k] = v end

    for Player in pairs(PlayersCopy) do
        if IsValid(Player) then
            local Vehicle = Player:GetVehicle()
            if IsValid(Vehicle) then
                local NewContraption = Vehicle:GetContraption()
                if NewContraption ~= nil then
                    ParentContraption.ACF_TrackPlayers[Player] = nil
                    NewContraption.ACF_TrackPlayers[Player] = true
                    -- ^^ may actually do a no op because NewContraption could be ParentContraption after all
                else -- The vehicle is no longer a part of any contraption
                    ParentContraption.ACF_TrackPlayers[Player] = nil
                end
            else -- The players vehicle is no longer even valid, so discard the player
                ParentContraption.ACF_TrackPlayers[Player] = nil
            end
        else -- The player isn't valid?
            ParentContraption.ACF_TrackPlayers[Player] = nil
        end
    end

    -- Reset the parent and child contraption states
    ResetContraptionTimes(ParentContraption)
    ResetContraptionTimes(ChildContraption)
--[[
    print("Parent: ")
    print("    Table Address : " .. tostring(ParentContraption))
    print("    Player Count  : " .. table.Count(ParentContraption.ACF_TrackPlayers))
    print("Child: ")
    print("    Table Address : " .. tostring(ChildContraption))
    print("    Player Count  : " .. table.Count(ChildContraption.ACF_TrackPlayers))
]]
end)

-- Engine hooks to track players entering vehicles

hook.Add("PlayerEnteredVehicle", "ACF_CFW_TrackPlayersInContraptions", function(Player, Vehicle)
    local Contraption = Vehicle:GetContraption()
    if not Contraption then return end

    Contraption.ACF_TrackPlayers[Player] = true
    ResetContraptionTimes(Contraption)
end)

hook.Add("PlayerLeaveVehicle", "ACF_CFW_TrackPlayersInContraptions", function(Player, Vehicle)
    local Contraption = Vehicle:GetContraption()
    if not Contraption then return end

    Contraption.ACF_TrackPlayers[Player] = nil
    ResetContraptionTimes(Contraption)
end)

-- The infrastructure we need to track players while not calling things too frequently 
-- This local function is a little experiment, not even sure if we need this
local function NextValid(Table, PrevKey)
    while true do
        local Key, Value = next(Table, PrevKey)
        if Key == nil then return end

        if Value and IsValid(Key) then
            return Key
        end

        PrevKey = Key
    end
end

function ACF.PlayersInContraptionIterator(Contraption)
    return NextValid, Contraption.ACF_TrackPlayers, nil
end

local QueryTimes = {}

function ResetTime(Entity)
    if not IsValid(Entity) then return end

    QueryTimes[Entity] = nil
    Entity:RemoveCallOnRemove("ACF_CleanUpPlayerContraptionCheck")
end
--[[
local Clock = ACF.Utilities.Clock

local NO_CONTRAPTION          = 0
local NO_PLAYER               = -1
local NO_PLAYER_IN_RANGE      = -1
local OK                      = 1

local ERROR_MESSAGES = {
    [NO_CONTRAPTION]     = "must be part of a contraption",
    [NO_PLAYER]          = "require that a player is inside of the current contraption",
    [NO_PLAYER_IN_RANGE] = "cannot fire without a nearby seated player in the same contraption"
}

local function PlayerContraptionCheck(Entity)
    local Now  = Clock.CurTime
    local Then = QueryTimes[Entity]
    if (Now - (Then or 0)) <= math.Rand(0.5, 1.5) then
        -- We don't need to do anything then
        return OK
    end

    -- Update
    local PreviouslyTracked = QueryTimes[Entity] ~= nil
    QueryTimes[Entity] = Now
    if not PreviouslyTracked then
        Entity:CallOnRemove("ACF_CleanUpPlayerContraptionCheck", function(Ent)
            QueryTimes[Ent] = nil
        end)
    end

    -- No contraption means the lethal entity cannot work
    local Contraption = Entity:GetContraption()
    if not Contraption then return NO_CONTRAPTION end

    local Position = Entity:GetPos()
    local AtLeastOnePlayer = false
    for Player in ACF.PlayersInContraptionIterator(Contraption) do
        AtLeastOnePlayer = true
        local Distance = Player:GetPos():Distance(Position)
        if Distance <= 384 then
            return OK
        end
    end

    return AtLeastOnePlayer and NO_PLAYER_IN_RANGE or NO_PLAYER
end

-- Purpose: Hook into all lethals pre-fire, check valid player contraption state
hook.Add("ACF_PreFireWeapon", "ACF_CheckPlayerContraptionLethals", function(Ent)
    if not ACF.LethalEntityPlayerChecks then return end

    local ValidPlayerContraptionState = PlayerContraptionCheck(Ent)
    if ValidPlayerContraptionState ~= OK then
        ACF.DisableEntity(Ent, "Player Error", string.format("%s %s.", Ent.PluralName or Ent:GetClass(), ERROR_MESSAGES[ValidPlayerContraptionState]), 5)
        return false
    end
end)
]]