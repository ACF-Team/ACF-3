-- The goal is for this file to basically be a master file for any backwards compatibiliy class definitions that we need
-- to define. I wouldn't mind these being split up either, as long as they aren't in the main class definition files...
-- This also separates aliasing from the class system, which in the future will be replaced. - March

-- A gripe I had with a lot of the backwards compatibility stuff is that it was very implicit in the class system beyond
-- just being intertwined. So all public facing functionality is done with the ACF.Compatibility namespace, with sub-namespaces
-- for specific things. The system under the hood uses the ACF aliasing library.

-- TODO: Evaluate how we can use verifydata hooks to move even more of this stuff later... I don't like how much slop you
-- have to define in entity code to achieve backwards compatibility, it makes those files very unpleasant to read. If we
-- are to keep backwards compatibility/allow conversion between other addons, we should do so as a separate layer, rather
-- than making a mess of those files by merging it all together

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
        Aliases.Register("PreScalableWeapons_ItemChanges", ClassName, Data)
    end

    local function Weapons_RegisterGroupChange(NewClass, OldClass)
        Aliases.Register("PreScalableWeapons_GroupChanges", OldClass, NewClass)
    end

    -- Exposed functions
    Compatibility.Weapons = {}

    function Compatibility.Weapons.CheckGroupItem(GroupItem)
        return Aliases.Get("PreScalableWeapons_ItemChanges", GroupItem)
    end

    function Compatibility.Weapons.CheckGroup(Group)
        return Aliases.Get("PreScalableWeapons_GroupChanges", Group)
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

---------------------------------------------------------------------------------------------------------------------
--  Pre-Scalable Gearboxes Compatibility
--      All previously registered gearboxes for ACF-3
--
--      Breaking change introduced: December 17th, 2024, finalized February 15th, 2025
--      https://github.com/ACF-Team/ACF-3/commit/0dfbe3cb5c16d88fa444823d96b6eb2815151cbf
--      https://github.com/ACF-Team/ACF-3/pull/443
---------------------------------------------------------------------------------------------------------------------
do
    local function Gearboxes_RegisterItemAlias(GroupID, ID, Alias, Overrides)
        local Data = {
            GroupID   = GroupID,
            ID        = ID,
            Overrides = Overrides
        }
        Aliases.Register("PreScalableGearboxes_ItemChanges", Alias, Data)
    end

    local function Gearboxes_RegisterGroupChange(NewClass, OldClass)
        Aliases.Register("PreScalableGearboxes_GroupChanges", OldClass, NewClass)
    end

    -- Exposed functions
    Compatibility.Gearboxes = {}

    function Compatibility.Gearboxes.CheckGroupItem(GroupItem)
        return Aliases.Get("PreScalableGearboxes_ItemChanges", GroupItem)
    end

    function Compatibility.Gearboxes.CheckGroup(GroupItem)
        return Aliases.Get("PreScalableGearboxes_GroupChanges", GroupItem)
    end

    -- Automatic gearboxes
    do -- Pre-Scalable 3/5/7-Speed Gearboxes
        local OldGearValues = {3, 5, 7}

        for _, Gear in ipairs(OldGearValues) do
            local OldCategory = tostring(Gear .. "-Auto")
            local OldGear = tostring(Gear .. "Gear")

            Gearboxes_RegisterGroupChange("Auto", OldCategory)

            -- Inline Gearboxes
            Gearboxes_RegisterItemAlias(OldCategory, "Auto-L", OldGear .. "-A-L-S", {
                MaxGear = Gear,
                Scale = ScaleS,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias(OldCategory, "Auto-L", OldGear .. "-A-L-M", {
                MaxGear = Gear,
                Scale = ScaleM,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias(OldCategory, "Auto-L", OldGear .. "-A-L-L", {
                MaxGear = Gear,
                Scale = ScaleL,
                InvertGearRatios = true,
            })

            -- Inline Dual Clutch Gearboxes
            Gearboxes_RegisterItemAlias(OldCategory, "Auto-L", OldGear .. "-A-LD-S", {
                MaxGear = Gear,
                Scale = ScaleS,
                DualClutch = true,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias(OldCategory, "Auto-L", OldGear .. "-A-LD-M", {
                MaxGear = Gear,
                Scale = ScaleM,
                DualClutch = true,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias(OldCategory, "Auto-L", OldGear .. "-A-LD-L", {
                MaxGear = Gear,
                Scale = ScaleL,
                DualClutch = true,
                InvertGearRatios = true,
            })

            -- Transaxial Gearboxes
            Gearboxes_RegisterItemAlias(OldCategory, "Auto-T", OldGear .. "-A-T-S", {
                MaxGear = Gear,
                Scale = ScaleS,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias(OldCategory, "Auto-T", OldGear .. "-A-T-M", {
                MaxGear = Gear,
                Scale = ScaleM,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias(OldCategory, "Auto-T", OldGear .. "-A-T-L", {
                MaxGear = Gear,
                Scale = ScaleL,
                InvertGearRatios = true,
            })

            -- Transaxial Dual Clutch Gearboxes
            Gearboxes_RegisterItemAlias(OldCategory, "Auto-T", OldGear .. "-A-TD-S", {
                MaxGear = Gear,
                Scale = ScaleS,
                DualClutch = true,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias(OldCategory, "Auto-T", OldGear .. "-A-TD-M", {
                MaxGear = Gear,
                Scale = ScaleM,
                DualClutch = true,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias(OldCategory, "Auto-T", OldGear .. "-A-TD-L", {
                MaxGear = Gear,
                Scale = ScaleL,
                DualClutch = true,
                InvertGearRatios = true,
            })

            -- Straight-through Gearboxes
            Gearboxes_RegisterItemAlias(OldCategory, "Auto-ST", OldGear .. "-A-ST-S", {
                MaxGear = Gear,
                Scale = ScaleS,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias(OldCategory, "Auto-ST", OldGear .. "-A-ST-M", {
                MaxGear = Gear,
                Scale = ScaleM,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias(OldCategory, "Auto-ST", OldGear .. "-A-ST-L", {
                MaxGear = Gear,
                Scale = StScaleL,
                InvertGearRatios = true,
            })
        end
    end



    -- Clutch gearboxes
    do -- Pre-Scalable Straight-through Gearboxes
        Gearboxes_RegisterItemAlias("Clutch", "Clutch-S", "Clutch-S-T", {
            Scale = ScaleT,
            InvertGearRatios = true,
        })

        Gearboxes_RegisterItemAlias("Clutch", "Clutch-S", "Clutch-S-S", {
            Scale = ScaleS,
            InvertGearRatios = true,
        })

        Gearboxes_RegisterItemAlias("Clutch", "Clutch-S", "Clutch-S-M", {
            Scale = ScaleM,
            InvertGearRatios = true,
        })

        Gearboxes_RegisterItemAlias("Clutch", "Clutch-S", "Clutch-S-L", {
            Scale = ScaleL,
            InvertGearRatios = true,
        })
    end



    -- CVT gearboxes
    do
        do -- Inline Gearboxes
            Gearboxes_RegisterItemAlias("CVT", "CVT-L", "CVT-L-S", {
                Scale = ScaleS,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias("CVT", "CVT-L", "CVT-L-M", {
                Scale = ScaleM,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias("CVT", "CVT-L", "CVT-L-L", {
                Scale = ScaleL,
                InvertGearRatios = true,
            })
        end

        do -- Inline Dual Clutch Gearboxes
            Gearboxes_RegisterItemAlias("CVT", "CVT-L", "CVT-LD-S", {
                Scale = ScaleS,
                DualClutch = true,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias("CVT", "CVT-L", "CVT-LD-M", {
                Scale = ScaleM,
                DualClutch = true,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias("CVT", "CVT-L", "CVT-LD-L", {
                Scale = ScaleL,
                DualClutch = true,
                InvertGearRatios = true,
            })
        end

        do -- Transaxial Gearboxes
            Gearboxes_RegisterItemAlias("CVT", "CVT-T", "CVT-T-S", {
                Scale = ScaleS,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias("CVT", "CVT-T", "CVT-T-M", {
                Scale = ScaleM,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias("CVT", "CVT-T", "CVT-T-L", {
                Scale = ScaleL,
                InvertGearRatios = true,
            })
        end


        do -- Transaxial Dual Clutch Gearboxes
            Gearboxes_RegisterItemAlias("CVT", "CVT-T", "CVT-TD-S", {
                Scale = ScaleS,
                DualClutch = true,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias("CVT", "CVT-T", "CVT-TD-M", {
                Scale = ScaleM,
                DualClutch = true,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias("CVT", "CVT-T", "CVT-TD-L", {
                Scale = ScaleL,
                DualClutch = true,
                InvertGearRatios = true,
            })
        end

        do -- Straight-through Gearboxes
            Gearboxes_RegisterItemAlias("CVT", "CVT-ST", "CVT-ST-S", {
                Scale = ScaleS,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias("CVT", "CVT-ST", "CVT-ST-M", {
                Scale = ScaleM,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias("CVT", "CVT-ST", "CVT-ST-L", {
                Scale = StScaleL,
                InvertGearRatios = true,
            })
        end
    end



    -- Differential gearboxes
    do -- Pre-Scalable Inline/Transaxial Gearboxes
        local OldGearboxTypes = {"L", "T"}

        for _, GearboxType in ipairs(OldGearboxTypes) do
            local OldCategory = "1Gear-" .. GearboxType

            -- Regular Gearboxes
            Gearboxes_RegisterItemAlias("Differential", OldCategory, OldCategory .. "-S", {
                Scale = ScaleS,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias("Differential", OldCategory, OldCategory .. "-M", {
                Scale = ScaleM,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias("Differential", OldCategory, OldCategory .. "-L", {
                Scale = ScaleL,
                InvertGearRatios = true,
            })

            -- Dual Clutch Gearboxes
            Gearboxes_RegisterItemAlias("Differential", OldCategory, OldCategory .. "D-S", {
                Scale = ScaleS,
                DualClutch = true,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias("Differential", OldCategory, OldCategory .. "D-M", {
                Scale = ScaleM,
                DualClutch = true,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias("Differential", OldCategory, OldCategory .. "D-L", {
                Scale = ScaleL,
                DualClutch = true,
                InvertGearRatios = true,
            })

            -- ACF Extras Gearboxes
            Gearboxes_RegisterItemAlias("Differential", OldCategory, OldCategory .. "-T", {
                Scale = ScaleT,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias("Differential", OldCategory, OldCategory .. "D-T", {
                Scale = ScaleT,
                DualClutch = true,
                InvertGearRatios = true,
            })
        end
    end



    -- Double Differential gearboxes
    do
        Gearboxes_RegisterItemAlias("DoubleDiff", "DoubleDiff-T", "DoubleDiff-T-S", {
            Scale = ScaleS,
            InvertGearRatios = true,
        })

        Gearboxes_RegisterItemAlias("DoubleDiff", "DoubleDiff-T", "DoubleDiff-T-M", {
            Scale = ScaleM,
            InvertGearRatios = true,
        })

        Gearboxes_RegisterItemAlias("DoubleDiff", "DoubleDiff-T", "DoubleDiff-T-L", {
            Scale = ScaleL,
            InvertGearRatios = true,
        })
    end



    -- Manual gearboxes
    do
        do -- Pre-Scalable 4/6/8-Speed Manual Gearboxes + ACE 9-Speed Manual Gearboxes
            local OldGearValues = {4, 6, 8, 9}

            for _, Gear in ipairs(OldGearValues) do
                local OldCategory = tostring(Gear .. "-Speed")
                local OldGear = tostring(Gear .. "Gear")

                Gearboxes_RegisterGroupChange("Manual", OldCategory)

                -- Inline Gearboxes
                Gearboxes_RegisterItemAlias(OldCategory, "Manual-L", OldGear .. "-L-S", {
                    MaxGear = Gear,
                    Scale = ScaleS,
                    InvertGearRatios = true,
                })

                Gearboxes_RegisterItemAlias(OldCategory, "Manual-L", OldGear .. "-L-M", {
                    MaxGear = Gear,
                    Scale = ScaleM,
                    InvertGearRatios = true,
                })

                Gearboxes_RegisterItemAlias(OldCategory, "Manual-L", OldGear .. "-L-L", {
                    MaxGear = Gear,
                    Scale = ScaleL,
                    InvertGearRatios = true,
                })

                -- Inline Dual Clutch Gearboxes
                Gearboxes_RegisterItemAlias(OldCategory, "Manual-L", OldGear .. "-LD-S", {
                    MaxGear = Gear,
                    Scale = ScaleS,
                    DualClutch = true,
                    InvertGearRatios = true,
                })

                Gearboxes_RegisterItemAlias(OldCategory, "Manual-L", OldGear .. "-LD-M", {
                    MaxGear = Gear,
                    Scale = ScaleM,
                    DualClutch = true,
                    InvertGearRatios = true,
                })

                Gearboxes_RegisterItemAlias(OldCategory, "Manual-L", OldGear .. "-LD-L", {
                    MaxGear = Gear,
                    Scale = ScaleL,
                    DualClutch = true,
                    InvertGearRatios = true,
                })

                -- Transaxial Gearboxes
                Gearboxes_RegisterItemAlias(OldCategory, "Manual-T", OldGear .. "-T-S", {
                    MaxGear = Gear,
                    Scale = ScaleS,
                    InvertGearRatios = true,
                })

                Gearboxes_RegisterItemAlias(OldCategory, "Manual-T", OldGear .. "-T-M", {
                    MaxGear = Gear,
                    Scale = ScaleM,
                    InvertGearRatios = true,
                })

                Gearboxes_RegisterItemAlias(OldCategory, "Manual-T", OldGear .. "-T-L", {
                    MaxGear = Gear,
                    Scale = ScaleL,
                    InvertGearRatios = true,
                })

                -- Transaxial Dual Clutch Gearboxes
                Gearboxes_RegisterItemAlias(OldCategory, "Manual-T", OldGear .. "-TD-S", {
                    MaxGear = Gear,
                    Scale = ScaleS,
                    DualClutch = true,
                    InvertGearRatios = true,
                })

                Gearboxes_RegisterItemAlias(OldCategory, "Manual-T", OldGear .. "-TD-M", {
                    MaxGear = Gear,
                    Scale = ScaleM,
                    DualClutch = true,
                    InvertGearRatios = true,
                })

                Gearboxes_RegisterItemAlias(OldCategory, "Manual-T", OldGear .. "-TD-L", {
                    MaxGear = Gear,
                    Scale = ScaleL,
                    DualClutch = true,
                    InvertGearRatios = true,
                })

                -- Straight-through Gearboxes
                Gearboxes_RegisterItemAlias(OldCategory, "Manual-ST", OldGear .. "-ST-S", {
                    MaxGear = Gear,
                    Scale = ScaleS,
                    InvertGearRatios = true,
                })

                Gearboxes_RegisterItemAlias(OldCategory, "Manual-ST", OldGear .. "-ST-M", {
                    MaxGear = Gear,
                    Scale = ScaleM,
                    InvertGearRatios = true,
                })

                Gearboxes_RegisterItemAlias(OldCategory, "Manual-ST", OldGear .. "-ST-L", {
                    MaxGear = Gear,
                    Scale = StScaleL,
                    InvertGearRatios = true,
                })
            end
        end

        do -- ACF Extras Manual Gearboxes (4/6-Speed)
            local OldGearValues = {4, 6}

            for _, Gear in ipairs(OldGearValues) do
                local OldCategory = tostring(Gear .. "-Speed-Inline")
                local OldGear = tostring(Gear .. "Gear")

                Gearboxes_RegisterGroupChange("Manual", OldCategory)

                -- Inline Gearboxes
                Gearboxes_RegisterItemAlias(OldCategory, "Manual-L", OldGear .. "-L-T", {
                    MaxGear = Gear,
                    Scale = ScaleT,
                    InvertGearRatios = true,
                })

                Gearboxes_RegisterItemAlias(OldCategory, "Manual-L", OldGear .. "-LD-T", {
                    MaxGear = Gear,
                    Scale = ScaleT,
                    DualClutch = true,
                    InvertGearRatios = true,
                })

                -- Transaxial Gearboxes
                Gearboxes_RegisterItemAlias(OldCategory, "Manual-T", OldGear .. "-T-T", {
                    MaxGear = Gear,
                    Scale = ScaleT,
                    InvertGearRatios = true,
                })

                Gearboxes_RegisterItemAlias(OldCategory, "Manual-T", OldGear .. "-TD-T", {
                    MaxGear = Gear,
                    Scale = ScaleT,
                    DualClutch = true,
                    InvertGearRatios = true,
                })

                -- Straight-through Gearboxes
                Gearboxes_RegisterItemAlias(OldCategory, "Manual-ST", OldGear .. "-ST-T", {
                    MaxGear = Gear,
                    Scale = ScaleT,
                    InvertGearRatios = true,
                })
            end
        end
    end


    -- Transfer case gearboxes
    do -- Pre-Scalable Inline/Transaxial Gearboxes
        local OldGearboxTypes = {"L", "T"}

        for _, GearboxType in ipairs(OldGearboxTypes) do
            local OldCategory = "2Gear-" .. GearboxType

            -- Regular Gearboxes
            Gearboxes_RegisterItemAlias("Transfer", OldCategory, OldCategory .. "-S", {
                Scale = ScaleS,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias("Transfer", OldCategory, OldCategory .. "-M", {
                Scale = ScaleM,
                InvertGearRatios = true,
            })

            Gearboxes_RegisterItemAlias("Transfer", OldCategory, OldCategory .. "-L", {
                Scale = ScaleL,
                InvertGearRatios = true,
            })

            -- ACF Extras Gearboxes
            Gearboxes_RegisterItemAlias("Transfer", OldCategory, OldCategory .. "-T", {
                Scale = ScaleT,
                InvertGearRatios = true,
            })
        end
    end
end