local ACF = ACF

local SpawnMenuOpen = false
local CtxMenuOpen   = false
hook.Add("OnContextMenuOpen", "ACF_TrackThisWhyIsntThisAThingICanJustCall", function()
    CtxMenuOpen = true
end)

hook.Add("OnContextMenuClose", "ACF_TrackThisWhyIsntThisAThingICanJustCall", function()
    CtxMenuOpen = false
end)

hook.Add("OnSpawnMenuOpen", "ACF_TrackThisWhyIsntThisAThingICanJustCall", function()
    SpawnMenuOpen = true
end)

hook.Add("OnSpawnMenuClose", "ACF_TrackThisWhyIsntThisAThingICanJustCall", function()
    SpawnMenuOpen = false
end)

ACF.AddClientSettings(501, "Overlay", function(Base)
    local Expanded      = false


    local State = ACF.Overlay.State()
    State:Begin()
        State:AddHeader("ACF Example Overlay")
        State:AddDivider()
        State:AddHeader("Text Elements", 2)
        State:AddLabel("Label element")
        State:AddSuccess("Success element")
        State:AddWarning("Warning element")
        State:AddError("Error element")
        State:AddKeyValue("KeyValue element",       "The quick brown fox")
        State:AddSubKeyValue("SubKeyValue element", "jumped over the lazy dog")
        State:AddHeader("Numeric Elements", 2)
        State:AddNumber("Number element", 100)
        State:AddNumber("Number element (w/ label)", 32, "kg")
        State:AddHealth("Health element", 80, 100)
        State:AddProgressBar("ProgressBar element", 50, 100)
        State:AddSize("Size element", 1, 1, 2)
        State:AddCoordinates("Coordinates element", 6039.13, -501.582, -11079.23)
        State:AddHeader("Specialized Elements", 2)
        State:AddGearRatio("GearRatio element", 0.2, "", false)

    State:End()

    hook.Add("PostRenderVGUI", Base, function()
        local Parent = Base:GetParent()
        local OK = Parent:GetExpanded() and (CtxMenuOpen or SpawnMenuOpen)
        if OK then
            if not Expanded then
                Expanded = true
                Base.ACF_OverlayStopTime  = nil
                Base.ACF_OverlayStartTime = RealTime()
            end
        else
            if Expanded then
                Expanded = false
                Base.ACF_OverlayStopTime = RealTime()
            end
        end
        local X, Y = Parent:LocalToScreen(0, 0)
        ACF.Overlay.DrawOverlay(State, NULL, X, Y, Base.ACF_OverlayStartTime, Base.ACF_OverlayStopTime, false)
    end)
end)