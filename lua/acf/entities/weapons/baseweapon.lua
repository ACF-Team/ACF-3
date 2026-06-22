ACF.Classes.DefineClass("ACF.Weapons.BaseWeapon", function()
    function CLASS:WeaponEquals(Other)
        if not Other then return false end

        local GetType = Other.GetType
        if not GetType then return false end

        local Type = GetType(Other)
        if Type ~= self:GetType() then return end
    end
end)