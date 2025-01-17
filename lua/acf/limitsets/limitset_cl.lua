ACF.LimitSets = ACF.LimitSets or {}

local acf_has_limitset_notice_been_shown = CreateConVar("__acf_has_limitset_notice_been_shown", 0, FCVAR_REPLICATED + FCVAR_UNREGISTERED, "Internal limitset flag", 0, 1)

surface.CreateFont("ACF_LimitsetsNotice_Font1", {
    font = "Tahoma",
    size = 16,
    antialias = true,
    weight = 900
})

surface.CreateFont("ACF_LimitsetsNotice_Font2", {
    font = "Tahoma",
    size = 42,
    antialias = true,
    weight = 900
})

surface.CreateFont("ACF_LimitsetsNotice_Font3", {
    font = "Tahoma",
    size = 24,
    antialias = true,
    italic = true,
    weight = 200
})

surface.CreateFont("ACF_LimitsetsNotice_Font4", {
    font = "Tahoma",
    size = 16,
    antialias = true,
    weight = 600
})

surface.CreateFont("ACF_LimitsetsNotice_Font5", {
    font = "Tahoma",
    size = 13,
    antialias = true,
    weight = 600
})


local function ShowLimitsetNotice(Bypass)
    if acf_has_limitset_notice_been_shown:GetBool() and not Bypass then return end
    if not ACF.CanSetServerData(LocalPlayer()) then return end

    if IsValid(ACF.LimitSets.NoticePanel) then ACF.LimitSets.NoticePanel:Remove() end

    local Frame = vgui.Create("DFrame")
    ACF.LimitSets.NoticePanel = Frame

    Frame:SetSize(640, 720)
    Frame:Center()
    Frame:MakePopup()
    Frame:SetSizable(true)
    Frame:SetTitle("ACF - Limitsets Notice")

    local Back = Frame:Add("DScrollPanel")
    Back:SetSize(0, 320)
    Back:DockMargin(8, 8, 8, 8)
    Back:Dock(TOP)
    Back:SetPaintBackground(true)

    local Contents = Back:Add "DLabel"
    Contents:SetFont("ACF_LimitsetsNotice_Font1")
    local CurrentLimitset = ACF.GetServerData("SelectedLimitset")
    Contents:SetText("We are introducing a new system into ACF, called 'Limitsets'.\n\nThese are a collection of server-side settings overrides that will automatically update as the addon develops.\n\nWe created this system to provide a curated list of server settings for both sandbox and combat playstyles.\n\nThe current limitset has been set to \"" .. CurrentLimitset .. "\".\n\nPlease choose a limitset that looks appropriate for your server.\nIf neither will work for you, select \"Custom\" to opt-out of the system. Settings will not automatically update.\n\nWe highly recommend Combat unless you're a more creative-building oriented server. Combat implements the most checks & balances, which makes PvP fair and reduces the need for human moderation during combat.\n\nYou can open this menu at any time with the concommand 'acf_select_limitset'.")
    Contents:SetWrap(true)
    Contents:Dock(TOP)
    Contents:SetContentAlignment(7)
    Contents:SetColor(Color(0, 0, 0))
    Contents:DockMargin(8, 8, 8, 8)
    function Contents:PerformLayout()
        Contents:SizeToContentsY()
    end

    local SelectLimitsetPanel  = Frame:Add("DListView")
    SelectLimitsetPanel:Dock(TOP)
    SelectLimitsetPanel:SetSize(0, 100)
    SelectLimitsetPanel:DockMargin(8, 4, 8, 4)
    SelectLimitsetPanel:AddColumn("Limitset Name")

    local InformationSheets = Frame:Add("DPropertySheet")
    InformationSheets:Dock(FILL)
    InformationSheets:DockMargin(8, 6, 8, 8)

    local ShowSelectedLimitsetPanel = InformationSheets:AddSheet("Limitset Information", vgui.Create("DPanel"), "icon16/information.png", false, true).Panel
    ShowSelectedLimitsetPanel:Dock(FILL)
    ShowSelectedLimitsetPanel:DockMargin(4, -4, 4, 4)

    local ShowSelectedLimitsetSettings = InformationSheets:AddSheet("Changed Settings", vgui.Create("DPanel"), "icon16/cog_edit.png", false, true).Panel
    ShowSelectedLimitsetSettings:Dock(FILL)
    ShowSelectedLimitsetSettings:DockMargin(4, -4, 4, 4)

    local SetTo   = Frame:Add("DButton")
    SetTo:Dock(BOTTOM)
    SetTo:DockMargin(8, 0, 8, 0)
    SetTo:SetFont("ACF_LimitsetsNotice_Font4")

    local Right = Material("icon16/arrow_right.png", "mips smooth")

    function SelectLimitsetPanel:OnRowSelected(_, Row)
        SetTo:SetText(Row.LimitSet and ("Choose the " .. Row.LimitSet.Name .. " limitset") or "Choose no limitset")

        ShowSelectedLimitsetPanel:Clear()
        ShowSelectedLimitsetSettings:Clear()

        local Title = ShowSelectedLimitsetPanel:Add("DLabel")
        Title:Dock(TOP)
        Title:DockMargin(8, 8, 8, 8)
        Title:SetColor(color_black)
        Title:SetSize(0, 38)
        Title:SetContentAlignment(1)
        Title:SetFont("ACF_LimitsetsNotice_Font2")
        Title:SetText(Row.LimitSet and Row.LimitSet.Name or "None")

        if Row.LimitSet and Row.LimitSet.Author then
            local Author = ShowSelectedLimitsetPanel:Add("DLabel")
            Author:SetColor(color_black)
            Author:DockMargin(16, -42, 8, 16)
            Author:SetSize(0, 24)
            Author:SetContentAlignment(9)
            Author:Dock(TOP)
            Author:SetFont("ACF_LimitsetsNotice_Font3")
            Author:SetText("by " .. Row.LimitSet.Author)
        end

        local Desc = ShowSelectedLimitsetPanel:Add("DLabel")
        Desc:SetColor(color_black)
        Desc:DockMargin(24, 2, 24, 2)
        Desc:SetSize(0, 24)
        Desc:SetContentAlignment(7)
        Desc:SetFont("ACF_LimitsetsNotice_Font4")
        Desc:SetText(Row.LimitSet and (Row.LimitSet.Description or "No description provided.") or "Don't select a limitset. This will keep your settings intact.")
        Desc:SetWrap(true)
        Desc:Dock(FILL)

        local SettingsChanged  = ShowSelectedLimitsetSettings:Add("DListView")
        SettingsChanged:Dock(FILL)
        SettingsChanged:DockMargin(8, 4, 8, 4)
        if Row.LimitSet and next(Row.LimitSet.ServerData) then
            SettingsChanged:AddColumn("Setting Name")
            SettingsChanged:AddColumn("Current Value")
            SettingsChanged:AddColumn("Will Be Changed To")

            for Key, Value in SortedPairs(Row.LimitSet.ServerData, true) do
                local Old = ACF.GetServerData(Key)
                local Changed = Old ~= Value
                local Line = SettingsChanged:AddLine(Key, Old, Value)
                for _, v in ipairs(Line.Columns) do
                    v:SetFont("ACF_LimitsetsNotice_Font5")
                end
                local oldPaint = Line.Paint

                function Line:Paint(w, h)
                    oldPaint(self, w, h)
                    if Changed then
                        surface.SetMaterial(Right)
                        surface.SetDrawColor(255, 255, 255, 225)
                        surface.DrawTexturedRectRotated(((w / 3) * 2) - 24, h / 2, 24, 24, 0)
                    end
                end
            end
        else
            function SettingsChanged:Paint(w, h)
                draw.SimpleText("No settings will be changed.", "ACF_LimitsetsNotice_Font2", w / 2, h / 2, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end

    for _, Name in ipairs(ACF.LimitSets.GetAll()) do
        local LimitSet = ACF.LimitSets.Get(Name)
        local Line = SelectLimitsetPanel:AddLine(LimitSet.Name)
        Line.LimitSet = LimitSet

        if Name == "Combat" then
            SelectLimitsetPanel:SelectItem(Line)
        end

    end
    SelectLimitsetPanel:AddLine("Custom")

    function SetTo:DoClick()
        local _, Selected = SelectLimitsetPanel:GetSelectedLine()
        ACF.SetServerData("SelectedLimitset", Selected.LimitSet and Selected.LimitSet.Name or "none", true)
        Frame:Close()
    end
end

hook.Add("StartCommand", "ACF_Limitsets_Postent", function()
    ShowLimitsetNotice()
    hook.Remove("StartCommand", "ACF_Limitsets_Postent")
end)

concommand.Add("acf_select_limitset", function()
    ShowLimitsetNotice(true)
end)