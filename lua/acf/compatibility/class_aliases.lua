---------------------------------------------------------------------------------------------------------------------
--  General Description of What This Is For
--      (extra comments if you want)
--
--      Breaking change introduced: Month Dth, YYYY
--      Further references if applicable
---------------------------------------------------------------------------------------------------------------------
-- Please leave the abovecomment for groups of aliases, and try to order them in order of oldest -> newest.

local Aliases       = ACF.Aliases
local Compatibility = ACF.Compatibility

---------------------------------------------------------------------------------------------------------------------
--  Pre-Scalable Weapons Compatibility
--      All previously registered weapons for ACF-3
--
--      Breaking change introduced: October 18th, 2021
--      https://github.com/ACF-Team/ACF-3/commit/5182807ddc29f10f4cc35542ba6eb587e1869c59
---------------------------------------------------------------------------------------------------------------------
do
    local function Weapons_RegisterOldGunItem(ClassName, GroupName, Data)
        Data = Data or {}
        local Caliber, Group = str:match("^(%d+)mm(.+)$")
        Data.Caliber = tonumber(Caliber)
        Data.Group   = GroupName or Group
        Aliases.Register("PreScalableWeapons_ClassToCaliberGroup", ClassName, Data)
    end

    local function Weapons_RegisterGroupChange(NewClass, OldClass)
        Aliases.Register("PreScalableWeapons_OldGroupToNewGroup", OldClass, NewClass)
    end

    -- Exposed functions
    Compatibility.Weapons = {}
    function ACF.Compatibility.Weapons.CheckGroupItem(GroupItem)
        return Aliases.Get("PreScalableWeapons_ClassToCaliberGroup", GroupItem)
    end

    function ACF.Compatibility.Weapons.CheckGroup(Group)
        return Aliases.Get("PreScalableWeapons_OldGroupToNewGroup", Group)
    end

    -- Autocannons
    Weapons_RegisterOldGunItem("20mmAC")
    Weapons_RegisterOldGunItem("30mmAC")
    Weapons_RegisterOldGunItem("40mmAC")
    Weapons_RegisterOldGunItem("50mmAC")

    -- Cannons
    Weapons_RegisterOldGunItem("37mmC")
    Weapons_RegisterOldGunItem("50mmC")
    Weapons_RegisterOldGunItem("75mmC")
    Weapons_RegisterOldGunItem("100mmC")
    Weapons_RegisterOldGunItem("120mmC")
    Weapons_RegisterOldGunItem("140mmC")

    -- Grenade launchers
    Weapons_RegisterOldGunItem("40mmGL")
    Weapons_RegisterOldGunItem("40mmCL", "GL")

    -- Howitzers
    Weapons_RegisterOldGunItem("75mmHW")
    Weapons_RegisterOldGunItem("122mmHW")
    Weapons_RegisterOldGunItem("155mmHW")
    Weapons_RegisterOldGunItem("203mmHW")

    -- Light autocannons
    Weapons_RegisterOldGunItem("20mmHMG", "LAC")
    Weapons_RegisterOldGunItem("30mmHMG", "LAC")
    Weapons_RegisterOldGunItem("40mmHMG", "LAC")

    -- Machineguns
    Weapons_RegisterOldGunItem("7.62mmMG")
    Weapons_RegisterOldGunItem("12.7mmMG")
    Weapons_RegisterOldGunItem("13mmMG")
    Weapons_RegisterOldGunItem("14.5mmMG")
    Weapons_RegisterOldGunItem("20mmMG")

    -- Mortars
    Weapons_RegisterOldGunItem("60mmM", "MO")
    Weapons_RegisterOldGunItem("80mmM", "MO")
    Weapons_RegisterOldGunItem("120mmM", "MO")
    Weapons_RegisterOldGunItem("150mmM", "MO")
    Weapons_RegisterOldGunItem("200mmM", "MO")

    -- Rotary autocannons
    Weapons_RegisterOldGunItem("14.5mmRAC")
    Weapons_RegisterOldGunItem("20mmRAC")
    Weapons_RegisterOldGunItem("30mmRAC")
    Weapons_RegisterOldGunItem("20mmHRAC", "RAC")
    Weapons_RegisterOldGunItem("30mmHRAC", "RAC")

    -- Semi-autocannons
    Weapons_RegisterOldGunItem("25mmSA")
    Weapons_RegisterOldGunItem("37mmSA")
    Weapons_RegisterOldGunItem("45mmSA")
    Weapons_RegisterOldGunItem("57mmSA")
    Weapons_RegisterOldGunItem("76mmSA")

    -- Short cannons
    Weapons_RegisterOldGunItem("37mmSC")
    Weapons_RegisterOldGunItem("50mmSC")
    Weapons_RegisterOldGunItem("75mmSC")
    Weapons_RegisterOldGunItem("100mmSC")
    Weapons_RegisterOldGunItem("120mmSC")
    Weapons_RegisterOldGunItem("140mmSC")

    -- Smoke launchers
    Weapons_RegisterOldGunItem("40mmSL")

    -- Smoothbore cannons
    Weapons_RegisterGroupChange("C", "SB")
    Weapons_RegisterOldGunItem("105mmSB", "C")
    Weapons_RegisterOldGunItem("120mmSB", "C")
    Weapons_RegisterOldGunItem("140mmSB", "C")
end