local Classes = ACF.Classes

Classes.DefineClass("ACF.Missiles.BaseMissile", "ACF.Weapons.BaseWeapon", function()
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
end)