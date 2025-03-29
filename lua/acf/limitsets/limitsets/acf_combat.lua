local Combat = ACF.LimitSets.Create("Combat")
    Combat:WithAuthor("ACF Team")
    Combat:WithDescription("The default mode for ACF combat, with curated combat settings by the developers. Recommended for PvP servers.\n\nCombat is easier for server moderation, as it implements the most checks & balances within ACF, and also makes ACF PvP a much more fair experience.\n\nWe recommend that all servers try Combat and/or base their settings off of it. If your server is more creative-building oriented, and Combat doesn't work for you, you can try Sandbox instead.")
    Combat:SetServerData("LegalChecks",              true)
    Combat:SetServerData("NameAndShame",             true)
    Combat:SetServerData("VehicleLegalChecks",       true)
    -- Combat:SetServerData("LinkDistance",             250)
    -- Combat:SetServerData("MobilityLinkDistance",     350)
    Combat:SetServerData("RequireFuel", true)
    Combat:SetServerData("GunsCanFire", true)
    Combat:SetServerData("RacksCanFire", true)
    Combat:SetServerData("HEPush", true)
    Combat:SetServerData("KEPush", true)
    Combat:SetServerData("RecoilPush", true)
    Combat:SetServerData("AllowProcArmor", false)