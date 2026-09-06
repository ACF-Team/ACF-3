local Classes = ACF.Classes

-- The weapon alias compat resolves a legacy item id ("40mmSL") to a short group id ("SL"); the V2
-- serializer needs the class FQN, so map the short id to it by scanning the weapon registry.
local function WeaponFQNFromID(ID)
	if Classes.GetSubtypeByName("ACF.Weapons.BaseWeapon", ID) then return ID end -- already an FQN

	for _, Class in ipairs(Classes.GetSubtypesAsList("ACF.Weapons.BaseWeapon")) do
		if Class.ID == ID then return Classes.GetTypeName(Class) end
	end
end

---------------------------------------------------------------------------------------------------------------------
--  Pre-Scalable Weapons Compatibility
--      All previously registered weapons for ACF-3
--
--      Breaking change introduced: October 18th, 2021
--      https://github.com/ACF-Team/ACF-3/commit/5182807ddc29f10f4cc35542ba6eb587e1869c59
---------------------------------------------------------------------------------------------------------------------
do
	local OldWeapons = {}
	local OldWeaponGroups = {}
	local function Weapons_RegisterOldGunItem(ClassName, GroupName, Data)
		Data = Data or {}
		local Caliber, Group = ClassName:match("^([%d%.]+)mm(.+)$")
		Data.Caliber = tonumber(Caliber)
		Data.ID      = GroupName or Group

		OldWeapons[ClassName] = Data
	end

	local function Weapons_RegisterGroupChange(NewClass, OldClass)
		OldWeaponGroups[OldClass] = NewClass
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

	ACF.Entities.RegisterCompatPatch("acf_gun", 2021101801, function(Data)
		-- changes pre-scalable -> scalable
		local AliasData = OldWeapons[Data.Weapon or Data.Id or "C"]
		if AliasData then
			Data.Caliber = AliasData.Caliber or Caliber
			Data.Weapon  = AliasData.ID -- short group id, e.g. "C" / "SL"
			Data.Id = nil
		end

		-- changes smoothbore -> cannon primarily but would perform other group changes
		local GroupChangeData = OldWeaponGroups[Data.Weapon or Data.Id or "C"]
		if GroupChangeData then
			Data.Weapon  = GroupChangeData
		end
	end)
end

-- This was for the autoregisterv2 conversion: migrate legacy flat gun dupe data
-- (top-level Weapon/Caliber/BreechIndex) into the nested ACF_UserData field set.
ACF.Entities.RegisterCompatPatch("acf_gun", 2026062601, function(Data)
	if Data.ACF_UserData then return end

	local Weapon  = Data.Weapon or Data.Id or "C"
	local Caliber = Data.Caliber
	Weapon = WeaponFQNFromID(Weapon) or "ACF.Guns.Cannon"

	Data.ACF_UserData = {
		Weapon      = {Type = Weapon, Data = {Caliber = Caliber}},
		Caliber     = Caliber,
		BreechIndex = Data.BreechIndex,
	}
end)
