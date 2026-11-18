ACF.Entities.RegisterCompatPatch("acf_baseplate", 2026060901, function(Data)
    local ACF_UserData = Data.ACF_UserData
    if not ACF_UserData then return end

    -- Patch pre-new class system
    if type(ACF_UserData.BaseplateType) == "string" then
        local OldBaseplateTypeString = ACF_UserData.BaseplateType
        local Type = ACF.Classes.GetTypeByName("ACF.Baseplates." .. OldBaseplateTypeString)
        if not Type then
            Type = ACF.Classes.GetTypeByName("ACF.Baseplates.GroundVehicle")
        end

        local BpData = {}
        ACF_UserData.BaseplateType = {
            Type = ACF.Classes.GetTypeName(Type),
            Data = BpData
        }

        if OldBaseplateTypeString == "Aircraft" then
            BpData.GForceTicks = ACF_UserData.GForceTicks
            ACF_UserData.GForceTicks = nil
        end

        if OldBaseplateTypeString == "Recreational" then
            BpData.ExplodeOnCollisions = ACF_UserData.ExplodeOnCollisions
            ACF_UserData.ExplodeOnCollisions = nil
        end
    end
end)

ACF.Entities.RegisterCompatPatch("acf_baseplate", 2026111801, function(Data)
    local EntityMods = Data.EntityMods
    if not istable(EntityMods) or EntityMods.LuaSeatID == nil then return end

    local ACF_UserData = istable(Data.ACF_UserData) and Data.ACF_UserData or {}
    Data.ACF_UserData = ACF_UserData

    -- Seat was always saved as -1 back then
    ACF_UserData.Seat = nil
    ACF_UserData.AlreadyHasSeat = true

    ACF.Entities.MoveLinkModToUserData(Data, "LuaSeatID", "Seat", true)
end)