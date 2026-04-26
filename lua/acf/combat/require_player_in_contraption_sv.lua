local ACF       = ACF
local Utilities = ACF.Utilities
local Clock     = Utilities.Clock

local NO_CONTRAPTION          = 0
local NO_PLAYER               = -1
local ALL_CREW_KILLED         = -2
local OK                      = 1

local ERROR_MESSAGES = {
    [NO_CONTRAPTION]     = "must be part of a contraption",
    [NO_PLAYER]          = "require that a player is inside of the current contraption",
    [ALL_CREW_KILLED]    = "requires that the contraption's crew has not been killed off",
}

ACF.ContraptionQueryTimes = ACF.ContraptionQueryTimes or {}
local ContraptionQueryTimes = ACF.ContraptionQueryTimes

local function PlayerContraptionCheck(Entity)
    local Now  = Clock.CurTime
    local Then = ContraptionQueryTimes[Entity]
    if (Now - (Then or 0)) <= math.Rand(0.5, 1.5) then
        -- We don't need to do anything then
        return OK
    end

    -- Update
    local PreviouslyTracked = ContraptionQueryTimes[Entity] ~= nil
    ContraptionQueryTimes[Entity] = Now
    if not PreviouslyTracked then
        Entity:CallOnRemove("ACF_CleanUpPlayerContraptionCheck", function(Ent)
            ContraptionQueryTimes[Ent] = nil
        end)
    end

    -- No contraption means the lethal entity cannot work
    local Contraption = Entity:CFW_GetContraption()
    if not Contraption then return NO_CONTRAPTION end

    if Contraption.ACF_AllCrewKilled then return ALL_CREW_KILLED end
    for _, _ in ACF.PlayersInContraptionIterator(Contraption) do return OK end
    return NO_PLAYER
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