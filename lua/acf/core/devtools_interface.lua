local ACF = ACF
ACF.EventViewer = ACF.EventViewer or {}
ACF.EntityKeyValues = ACF.EntityKeyValues or {}

function ACF.EventViewer.Enabled() return false end
function ACF.EntityKeyValues.Enabled() return false end

hook.Add("Initialize", "ACF_SetupStubForDevTools", function()
    table.Empty(ACF.EventViewer)
    table.Empty(ACF.EntityKeyValues)

    if not ACF_DevTools then
        -- NOTHING should run event viewer code unless this is enabled
        function ACF.EventViewer.Enabled() return false end
        function ACF.EntityKeyValues.Enabled() return false end
        -- ^^^ respect this 100%
        -- I don't want to maintain a bunch of stubs here.
    else
        -- This may become a real function sometime in the underlying implementation.
        -- For now, this is just an easier way to handle this.
        -- I would rename it to Available to be more clear, but I don't want to have to
        -- do like, .Available() and .Enabled() in the future...
        function ACF.EntityKeyValues.Enabled() return true end

        setmetatable(ACF.EventViewer, {__index = ACF_DevTools.EventViewer})
        setmetatable(ACF.EntityKeyValues, {__index = ACF_DevTools.EntityKeyValues})
    end
end)