local LimitSets = {
    Registered = {},
    __PostInitLimitSet = false
}
ACF.LimitSets = LimitSets

function LimitSets.Create(Name)
    local Object = {
        ServerData = {}
    }

    LimitSets.Registered[Name] = Object

    Object.Name = Name

    function Object:WithAuthor(Author) self.Author = Author end
    function Object:WithDescription(Description) self.Description = Description end

    function Object:SetServerData(Key, Value)
        self.ServerData[Key] = Value
    end

    if LimitSets.__PostInitLimitSet then
        timer.Simple(0, function()
            LimitSets.Execute(Name)
        end)
    end

    return Object
end

function LimitSets.Execute(Name)
    if not isstring(Name) then return false, "Argument #1 (Name) must be a string." end

    local LimitSet = LimitSets.Registered[Name]
    if not LimitSet then return false, "No limitset with the name '" .. Name .. "'." end

    ACF.Utilities.Messages.PrintLog("Info", "Loading the limitset '" .. Name .. "' by " .. (LimitSet.Author or "<no author>") .. "...")

    for Key, Value in pairs(LimitSet.ServerData) do
        ACF.SetServerData(Key, Value)
    end
end

hook.Add("ACF_OnLoadAddon", "ACF_LimitSets_Setup", function()
    local SelectedLimitsetName = ACF.SelectedLimitset or "Combat"
    local SelectedLimitset     = ACF.LimitSets.Registered[SelectedLimitsetName]

    if SelectedLimitset then
        LimitSets.Execute(SelectedLimitsetName)
    else
        ACF.Utilities.Messages.PrintLog("Info", "No limitset loaded.")
    end

    ACF.LimitSets.__PostInitLimitSet = true
end)