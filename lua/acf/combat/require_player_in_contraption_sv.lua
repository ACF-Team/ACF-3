local ACF       = ACF
local Utilities = ACF.Utilities
local Clock     = Utilities.Clock

local NO_CONTRAPTION          = 0
local NO_PLAYER               = -1
local ALL_CREW_KILLED         = -2
local OK                      = 1

local RESTRICTIONS = {
    [NO_CONTRAPTION]     = "lethal_no_contraption",
    [NO_PLAYER]          = "lethal_no_player",
    [ALL_CREW_KILLED]    = "lethal_crew_killed",
}

-- The seats to sit in, or the dead crew, marked for the owner by the targets renderer
local function GetTargets(State, Contraption)
    local Targets = {}

    if State == NO_PLAYER then
        for _, Set in pairs(Contraption.entsbyclass) do
            for Ent in pairs(Set) do
                if IsValid(Ent) and Ent:IsVehicle() then Targets[#Targets + 1] = Ent end
            end
        end

        return { Targets = Targets, Label = "Seat" }
    end

    if State == ALL_CREW_KILLED then
        for Crew in pairs(Contraption.entsbyclass.acf_crew or {}) do
            if IsValid(Crew) then Targets[#Targets + 1] = Crew end
        end

        return { Targets = Targets, Label = "Dead crew" }
    end
end

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

    if Contraption.ACF_AllCrewKilled then return ALL_CREW_KILLED, Contraption end
    for _, _ in ACF.PlayersInContraptionIterator(Contraption) do return OK end
    return NO_PLAYER, Contraption
end

-- Purpose: Hook into all lethals pre-fire, check valid player contraption state
hook.Add("ACF_PreFireWeapon", "ACF_CheckPlayerContraptionLethals", function(Ent)
    if not ACF.LethalEntityPlayerChecks then return end

    local ValidPlayerContraptionState, Contraption = PlayerContraptionCheck(Ent)
    if ValidPlayerContraptionState ~= OK then
        ACF.Legality.Report(Ent, RESTRICTIONS[ValidPlayerContraptionState], GetTargets(ValidPlayerContraptionState, Contraption))
        return false
    end
end)