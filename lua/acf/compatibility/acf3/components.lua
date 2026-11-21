ACF.Entities.RegisterCompatPatch("acf_autoloader", 2026060901, function(Data)
    ACF.Entities.MoveLinkModToUserData(Data, "ACFGun", "Gun", true)
    ACF.Entities.MoveLinkModToUserData(Data, "ACFAmmoCrates", "AmmoCrates")
end)

-- No compat patch is needed for acf_groundloader.
-- No compat patch is needed for acf_waterjet.