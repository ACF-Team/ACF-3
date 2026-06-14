-- V1 -> V2 migration for acf_baseplate
ACF.Classes.Entities.RegisterCompatPatch("acf_baseplate", 2026060901, function(Data)
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