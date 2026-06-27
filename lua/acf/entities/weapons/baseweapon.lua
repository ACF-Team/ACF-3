ACF.Classes.DefineClass("ACF.Weapons.BaseWeapon", function()
    -- Returns true if Other is a weapon of the same type as self.
    -- Subtypes (e.g. scalable guns) extend this with additional checks like caliber.
    -- Works on both class tables and instances since GetType is inherited.
    function CLASS:WeaponEquals(Other)
        if not Other then return false end

        local GetType = Other.GetType
        if not GetType then return false end

        return GetType(Other) == self:GetType()
    end
end)