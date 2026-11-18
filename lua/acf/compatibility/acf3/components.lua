ACF.Entities.RegisterCompatPatch("acf_autoloader", 2026060901, function(Data)
    local EntityMods = Data.EntityMods
    if not istable(EntityMods) then return end

    local ACF_UserData = Data.ACF_UserData
    if not istable(ACF_UserData) then return end

    if istable(EntityMods.ACFGun) and ACF_UserData.Gun == nil then
        ACF_UserData.Gun = EntityMods.ACFGun[1]
    end

    if istable(EntityMods.ACFAmmoCrates) and ACF_UserData.AmmoCrates == nil then
        ACF_UserData.AmmoCrates = table.Copy(EntityMods.ACFAmmoCrates)
    end
end)

-- No compat patch is needed for acf_groundloader.
-- No compat patch is needed for acf_waterjet.