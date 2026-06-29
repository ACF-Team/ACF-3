local ACF = ACF
local Utilities = ACF.Utilities
local Clock     = Utilities.Clock

ACF.CrewlessLethalQueryTimes = ACF.CrewlessLethalQueryTimes or {}
local CrewlessLethalQueryTimes = ACF.CrewlessLethalQueryTimes

local function CrewlessLethalCheck(Entity)
    if not ACF.LethalEntityPlayerChecks then return true end

    local Now  = Clock.CurTime
    local Then = CrewlessLethalQueryTimes[Entity]
    if (Now - (Then or 0)) <= math.Rand(0.5, 1.5) then
        -- We don't need to do anything then
        return true
    end

    local PreviouslyTracked = CrewlessLethalQueryTimes[Entity] ~= nil
    CrewlessLethalQueryTimes[Entity] = Now
    if not PreviouslyTracked then
        Entity:CallOnRemove("ACF_CleanUpPlayerCrewlessLethalCheck", function(Ent)
            CrewlessLethalQueryTimes[Ent] = nil
        end)
    end

    local Contraption = Entity:CFW_GetContraption()
    local Crews = Contraption and Contraption.entsbyclass.acf_crew
    if not Crews or next(Crews) == nil then return false end

    return true
end

hook.Add("ACF_PreFireWeapon", "ACF_PreventCrewlessLethals", function(Ent)
    local Result = CrewlessLethalCheck(Ent)
    if not Result then
        ACF.DisableEntity(Ent, "Player Error", string.format("%s %s.", Ent.PluralName or Ent:GetClass(), "Lethal weapons cannot be used on crewless contraptions"), 5)
        return false
    end
end)