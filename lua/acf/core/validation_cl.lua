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