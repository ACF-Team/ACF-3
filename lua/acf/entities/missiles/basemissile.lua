local Classes = ACF.Classes

Classes.DefineClass("ACF.Missiles.BaseMissile", "ACF.Weapons.BaseWeapon", function()
    local BASE = BASE
    CLASS.IsScalable 	= false

    MENU_FIELD("ACF.Missiles.Guidance", "Guidance",     {OnlyAllowSubtypes = true, InstantiateTypeForDefault = "ACF.Missiles.Guidance.Dumb"})
    MENU_FIELD("ACF.Missiles.Fuze",     "Fuze",         {OnlyAllowSubtypes = true, InstantiateTypeForDefault = "ACF.Missiles.Fuze.Contact"})

    function CLASS.__inherited(NewClass)
        if not NewClass.Entity then
            NewClass.Entity = "acf_rack"
        end

        if NewClass.LimitConVar then
            Classes.AddSboxLimit(Data.LimitConVar)
        end
    end

    function CLASS:WeaponEquals(Other)
        if not BASE.WeaponEquals(Other) then return false end
        -- We may need these later?
        -- Racks are kind abnormal compared to guns so i think this will be checked differently
        -- if not self.Guidance:GuidanceEquals(Other.Guidance) then return false end
        -- if not self.Fuze:FuzeEquals(Other.Guidance) then return false end
        return true;
    end
end)
