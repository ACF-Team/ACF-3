local ACF         = ACF
local Classes     = ACF.Classes
local Piledrivers = Classes.Piledrivers

-- Backwards compatibility
function ENT.ACF_GetBackwardsCompatibilityDataKeys()
    return {
        "Id"
    }
end

function ENT.ACF_GetHookArguments(ClientData)
    return Piledrivers.Get(ClientData.Weapon)
end

function ENT.ACF_PreVerifyClientData(Data)
    if Data.Id then
        local OldClass = Classes.GetGroup(Piledrivers, Data.Id)

        if OldClass then
            Data.Weapon = OldClass.ID
            Data.Caliber = Piledriver.GetItem(OldClass.ID, Data.Id).Caliber
        end

        Data.Id = nil
    end
end

function ENT.ACF_OnVerifyClientData(ClientData)
    local Class = Piledrivers.Get(ClientData.Weapon)
    if Class.VerifyData then
        Class.VerifyData(ClientData, Class)
    end
end