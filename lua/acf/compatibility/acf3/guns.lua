local Classes = ACF.Classes

-- The weapon alias compat resolves a legacy item id ("40mmSL") to a short group id ("SL"); the V2
-- serializer needs the class FQN, so map the short id to it by scanning the weapon registry.
local function WeaponFQNFromID(ID)
	if Classes.GetSubtypeByName("ACF.Weapons.BaseWeapon", ID) then return ID end -- already an FQN

	for _, Class in ipairs(Classes.GetSubtypesAsList("ACF.Weapons.BaseWeapon")) do
		if Class.ID == ID then return Classes.GetTypeName(Class) end
	end
end

-- This was for the autoregisterv2 conversion: migrate legacy flat gun dupe data
-- (top-level Weapon/Caliber/BreechIndex) into the nested ACF_UserData field set.
ACF.Entities.RegisterCompatPatch("acf_gun", 2026062601, function(Data)
	if Data.ACF_UserData then return end

	local Weapon  = Data.Weapon
	local Caliber = Data.Caliber

	-- Resolve pre-scalable weapon aliases (old short item ids/names) into a class FQN.
	if not Classes.GetSubtypeByName("ACF.Weapons.BaseWeapon", Weapon) then
		local Compat    = ACF.Compatibility.Weapons
		local AliasData = Compat and Compat.CheckGroupItem and Compat.CheckGroupItem(Weapon)

		if AliasData then
			Caliber = AliasData.Caliber or Caliber
			Weapon  = AliasData.ID -- short group id, e.g. "C" / "SL"
		end

		Weapon = WeaponFQNFromID(Weapon) or "ACF.Guns.Cannon"
	end

	Data.ACF_UserData = {
		Weapon      = {Type = Weapon, Data = {Caliber = Caliber}},
		Caliber     = Caliber,
		BreechIndex = Data.BreechIndex,
	}
end)
