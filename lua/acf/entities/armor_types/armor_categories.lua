local Classes = ACF.Classes

Classes.DefineClass("ACF.ArmorCategories.BaseArmorCategory", function() end)

-- Name       : display name for the category node
-- Description: short blurb shown before each contained type's own description
-- Types      : FQNs (under ACF.ArmorTypes) of the armor types grouped under this category

Classes.DefineClass("ACF.ArmorCategories.Base", "ACF.ArmorCategories.BaseArmorCategory", function(CLASS)
    CLASS.Name        = "Base"
    CLASS.Description = "Conventional, well rounded armor plating."
    CLASS.Types       = { "ACF.ArmorTypes.Default", "ACF.ArmorTypes.RHA", "ACF.ArmorTypes.Aluminum", "ACF.ArmorTypes.Wing" }
end)

Classes.DefineClass("ACF.ArmorCategories.KEAffinity", "ACF.ArmorCategories.BaseArmorCategory", function(CLASS)
    CLASS.Name        = "KE Affinity"
    CLASS.Description = "Favors protection against kinetic (e.g. AP) threats."
    CLASS.Types       = { "ACF.ArmorTypes.HHRHA", "ACF.ArmorTypes.DU", "ACF.ArmorTypes.SiliconCarbide" }
end)

Classes.DefineClass("ACF.ArmorCategories.CEAffinity", "ACF.ArmorCategories.BaseArmorCategory", function(CLASS)
    CLASS.Name        = "CE Affinity"
    CLASS.Description = "Favors protection against chemical energy (e.g. HEAT) threats."
    CLASS.Types       = { "ACF.ArmorTypes.Textolite", "ACF.ArmorTypes.NERA" }
end)

Classes.DefineClass("ACF.ArmorCategories.Reactive", "ACF.ArmorCategories.BaseArmorCategory", function(CLASS)
    CLASS.Name        = "Explosive Reactive"
    CLASS.Description = "Strong but single use and explodes on impact."
    CLASS.Types       = { "ACF.ArmorTypes.LightERA", "ACF.ArmorTypes.HeavyERA" }
end)

Classes.DefineClass("ACF.ArmorCategories.Special", "ACF.ArmorCategories.BaseArmorCategory", function(CLASS)
    CLASS.Name        = "Special"
    CLASS.Description = "Specialized armor types with unique properties."
    CLASS.Types       = { "ACF.ArmorTypes.ReinforcedConcrete", "ACF.ArmorTypes.Aramid" }
end)

Classes.DefineClass("ACF.ArmorCategories.Other", "ACF.ArmorCategories.BaseArmorCategory", function(CLASS)
    CLASS.Name        = "Other"
    CLASS.Description = "Not great for armor"
    CLASS.Types       = { "ACF.ArmorTypes.Flesh", "ACF.ArmorTypes.Wood", "ACF.ArmorTypes.Rubber" }
end)
