local OldRegistered = ACF.LimitSets and ACF.LimitSets.Registered or nil

local LimitSets = {
    Registered = OldRegistered or {},
    __PostInitLimitSet = false
}
ACF.LimitSets = LimitSets

if SERVER then
    LimitSets.acf_has_limitset_notice_been_shown = CreateConVar("__acf_has_limitset_notice_been_shown", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_UNREGISTERED, "Internal limitset flag", 0, 1)
end

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

    -- This allows hot-reloading
    if Name == ACF.ServerData.SelectedLimitset and LimitSets.__PostInitLimitSet then
        timer.Simple(0, function()
            LimitSets.Execute(Name)
        end)
    end

    return Object
end

function LimitSets.Get(Name)
    return LimitSets.Registered[Name]
end

function LimitSets.GetAll()
    return table.GetKeys(LimitSets.Registered)
end

function LimitSets.Execute(Name)
    if CLIENT then return end
    if Name == "none" then

        return true, "OK"
    end
    if not isstring(Name) then return false, "Argument #1 (Name) must be a string." end

    local LimitSet = LimitSets.Registered[Name]
    if not LimitSet then return false, "No limitset with the name '" .. Name .. "'." end

    ACF.Utilities.Messages.PrintLog("Info", "Loading the limitset '" .. Name .. "' by " .. (LimitSet.Author or "<no author>") .. "...")

    for Key, Value in pairs(LimitSet.ServerData) do
        ACF.SetServerData(Key, Value)
    end

    return true, "OK"
end

local function UpdateLimitSet()
    local SelectedLimitsetName = ACF.ServerData.SelectedLimitset or "none"
    local SelectedLimitset     = ACF.LimitSets.Registered[SelectedLimitsetName]

    if SelectedLimitset then
        LimitSets.Execute(SelectedLimitsetName)
    else
        ACF.Utilities.Messages.PrintLog("Info", "No limitset loaded.")
    end

    ACF.LimitSets.__PostInitLimitSet = true
end

hook.Add("ACF_OnLoadPersistedData", "ACF_LimitSets_Setup", function()
    if CLIENT then return end

    UpdateLimitSet()

    hook.Add("ACF_OnUploadServerData", "ACF_LimitSets_WatchForKey", function(_, Key, _)
        if Key ~= "SelectedLimitset" then return end
        UpdateLimitSet()

        LimitSets.acf_has_limitset_notice_been_shown:SetBool(true)
    end)
end)