-- V1 -> V2 migration for acf_autoloader
ACF.Classes.Entities.RegisterCompatPatch("acf_autoloader", 2026060901, function(Data)
	local EntityMods = Data.EntityMods
	if not EntityMods then return end

	local ACF_UserData = Data.ACF_UserData
	if not ACF_UserData then return end

	if EntityMods.ACFGun and ACF_UserData.Gun == nil then
		ACF_UserData.Gun = EntityMods.ACFGun[1]
	end

	if EntityMods.ACFAmmoCrates and ACF_UserData.AmmoCrates == nil then
		ACF_UserData.AmmoCrates = table.Copy(EntityMods.ACFAmmoCrates)
	end
end)
