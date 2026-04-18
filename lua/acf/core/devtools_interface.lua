-- Generic interface for ACF-3 Devtools
-- https://github.com/ACF-Team/ACF-3-DevTools
local AddonName = "ACF"
local Addon     = _G[AddonName]
Addon.EventViewer = Addon.EventViewer or {}
Addon.EntityKeyValues = Addon.EntityKeyValues or {}

function Addon.EventViewer.Enabled() return false end
function Addon.EntityKeyValues.Enabled() return false end

hook.Add("Initialize", AddonName .. "_SetupStubForDevTools", function()
    table.Empty(Addon.EventViewer)
    table.Empty(Addon.EntityKeyValues)

    if not ACF_DevTools then
        -- NOTHING should run event viewer code unless this is enabled
        function Addon.EventViewer.Enabled() return false end
        function Addon.EntityKeyValues.Enabled() return false end
        -- ^^^ respect this 100%
        -- I don't want to maintain a bunch of stubs here.
    else
        -- This may become a real function sometime in the underlying implementation.
        -- For now, this is just an easier way to handle this.
        -- I would rename it to Available to be more clear, but I don't want to have to
        -- do like, .Available() and .Enabled() in the future...
        function Addon.EntityKeyValues.Enabled() return true end

        setmetatable(Addon.EventViewer, {__index = ACF_DevTools.EventViewer})
        setmetatable(Addon.EntityKeyValues, {__index = ACF_DevTools.EntityKeyValues})
    end
end)