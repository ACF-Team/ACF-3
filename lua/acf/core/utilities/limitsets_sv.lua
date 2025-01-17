local LimitSets = {
    Registered = {}
}
ACF.LimitSets = LimitSets

function LimitSets.Create(Name)
    local Object = {
        ServerData = {}
    }

    LimitSets.Registered[Name] = Object

    function Object:SetServerData(Key, Value)
        self.ServerData[Key] = Value
    end

    return Object
end

function LimitSets.Execute(Name)
    ACF.Utilities.Messages.PrintLog("Info", "Loading the limitset '" .. Name .. "'...")

    if not isstring(Name) then return false, "Argument #1 (Name) must be a string." end

    local LimitSet = LimitSets.Registered[Name]
    if not LimitSet then return false, "No limitset with the name '" .. Name .. "'." end

    for Key, Value in pairs(LimitSet.ServerData) do
        ACF.SetServerData(Key, Value)
    end

    ACF.Utilities.Messages.PrintLog("Info", "Loaded limitset '" .. Name .. "'.")
end

hook.Add("ACF_OnLoadAddon", "ACF_LimitSets_Setup", function()
    local SelectedLimitsetName = ACF.SelectedLimitset or "Combat"
    local SelectedLimitset     = ACF.LimitSets.Registered[SelectedLimitsetName]

    if SelectedLimitset then
        LimitSets.Execute(SelectedLimitsetName)
    else
        ACF.Utilities.Messages.PrintLog("Info", "No limitset loaded.")
    end
end)