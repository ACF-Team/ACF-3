return function(PANEL)
    -- Similar to ControlPresets derma panel, but for ACF.
    -- Reference: https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/sandbox/gamemode/spawnmenu/controls/control_presets.lua
    function PANEL:AddPresetsBar(PresetScope, TargetRealm)
        local Panel = self:Add("DPanel")
        Panel:Dock(TOP)
        Panel:SetTall(20)
        Panel:DockMargin(0, 0, 0, 10)

        local Dropdown = vgui.Create("DComboBox", Panel)
        Dropdown:Dock(FILL)
        Dropdown:SetTooltip("Select a preset to apply")
        Dropdown.OnSelect = function(_, _, value, _)
            ACF.ApplyPreset(value, PresetScope)
        end

        function Dropdown:RefreshChoices(text)
            ACF.LoadPresetsForScope(PresetScope)
            Dropdown:Clear()
            for Name, _ in pairs(ACF.PresetsByScopeAndName[PresetScope] or {}) do
                Dropdown:AddChoice(Name)
            end
            if text then Dropdown:ChooseOption(text) end
        end

        local RemoveButton = vgui.Create("DImageButton", Panel)
        RemoveButton:Dock(RIGHT)
        RemoveButton:SetTooltip("Remove preset")
        RemoveButton:SetImage("icon16/delete.png")
        RemoveButton:SetStretchToFit(false)
        RemoveButton:SetSize(20, 20)
        RemoveButton:DockMargin(0, 0, 0, 0)

        RemoveButton.DoClick = function()
            local PresetName = Dropdown:GetValue()
            Derma_Query(
                "Are you sure you want to remove [" .. PresetName .. "]?", "Removing:",
                "Yes",
                function()
                    ACF.RemovePreset(PresetName, PresetScope)
                    Dropdown:RefreshChoices()
                end,
                "No",
                function() end
            )
        end

        local SaveButton = vgui.Create("DImageButton", Panel)
        SaveButton:Dock(RIGHT)
        SaveButton:SetTooltip("Save preset")
        SaveButton:SetImage("icon16/add.png")
        SaveButton:SetStretchToFit(false)
        SaveButton:SetSize(20, 20)
        SaveButton:DockMargin(2, 0, 0, 0)

        SaveButton.DoClick = function()
            Derma_StringRequest("#preset.saveas_title", "#preset.saveas_desc", "", function( text )
                if (not text or text:Trim() == "") then presets.BadNameAlert() return end
                if ACF.PresetsByScopeAndName[PresetScope] and ACF.PresetsByScopeAndName[PresetScope][text] then
                    Derma_Query(
                        "Are you sure you want to replace [" .. text .. "]?", "Saving:",
                        "Yes",
                        function() end,
                        "No",
                        function() end
                    )
                end

                ACF.AddPreset(text, PresetScope, PresetScope, nil, TargetRealm)
                ACF.SavePreset(text, PresetScope)
                Dropdown:RefreshChoices(text)
            end)
        end

        Dropdown:RefreshChoices()

        return Panel
    end
end