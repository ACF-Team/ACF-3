local Baddies	   = ACF.GlobalFilter
local BaddiesLess  = ACF.ArmorableGlobalFilterExceptions

-- Clientside ACF.Check. Not as through, but good enough for what's needed
function ACF.Check(Entity) -- IsValid but for ACF
    if not IsValid(Entity) then return false end

    local Class = Entity:GetClass()
    if Baddies[Class] and not BaddiesLess[Class] then return false end

    if Entity:IsWorld() or Entity:IsWeapon() or StringFind(Class, "func_") then
        Baddies[Class] = true

        return false
    end

    return true
end

-- Index entities which have been disabled
local ErroredEntities = {}
net.Receive("ACF_Error_Entity", function(_, _)
    local Entity = net.ReadEntity()
    if not IsValid(Entity) then return end
    ErroredEntities[Entity] = CurTime()
end)

-- Apply a holo around disabled entities, for 5 seconds
hook.Add("PreDrawHalos", "ACF_Error_Entity_Display", function()
    local CurTime = CurTime()
    for Entity, Time in pairs(ErroredEntities) do
        local Progress = (CurTime - Time) / 5
        if CurTime - Time > 5 then
            ErroredEntities[Entity] = nil
        elseif IsValid(Entity) then
            halo.Add( {Entity}, Color(255, 0, 0, (1-Progress) * 255), 5, 5, 2, true, true )
        end
    end
end)