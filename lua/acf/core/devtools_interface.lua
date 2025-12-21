local ACF = ACF
ACF.EventViewer = ACF.EventViewer or {}

function ACF.EventViewer.Enabled() return false end

hook.Add("Initialize", "ACF_SetupStubForDevTools", function()
    table.Empty(ACF.EventViewer)

    if not ACF_DevTools then
        -- NOTHING should run event viewer code unless this is enabled
        function ACF.EventViewer.Enabled() return false end
        -- ^^^ respect this 100%
        -- I don't want to maintain a bunch of stubs here.
    else
        setmetatable(ACF.EventViewer, {__index = ACF_DevTools.EventViewer})
    end
end)