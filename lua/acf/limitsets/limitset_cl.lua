ACF.LimitSets = ACF.LimitSets or {}

local acf_has_limitset_notice_been_shown = CreateConVar("__acf_has_limitset_notice_been_shown", 0, FCVAR_REPLICATED + FCVAR_UNREGISTERED, "Internal limitset flag", 0, 1)

surface.CreateFont("ACF_LimitsetsNotice_Font1", {
    font = "Tahoma",
    size = 16,
    antialias = true,
    weight = 600
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

surface.CreateFont("ACF_LimitsetsNotice_Font6", {
    font = "Tahoma",
    size = 26,
    antialias = true,
    weight = 600
})

local function ShowLimitsetNotice(Bypass)
    if acf_has_limitset_notice_been_shown:GetBool() and not Bypass then return end
    if not ACF.CanSetServerData(LocalPlayer()) then return end

    if IsValid(ACF.LimitSets.NoticePanel) then ACF.LimitSets.NoticePanel:Remove() end

    local Frame = vgui.Create("DFrame")
    Frame:SetIcon("icon16/cog_edit.png")
    ACF.LimitSets.NoticePanel = Frame

    Frame:SetSize(640, ScrH() * .85)
    Frame:Center()
    Frame:MakePopup()
    Frame:SetSizable(true)
    Frame:SetTitle("ACF - Limitsets Notice & Selector")

    local Back = Frame:Add("DScrollPanel")
    Back:SetSize(0, 400)
    Back:DockMargin(8, 8, 8, 8)
    Back:Dock(TOP)
    Back:SetPaintBackground(true)

    local Warn = Back:Add "DLabel"
    Warn:SetFont("ACF_LimitsetsNotice_Font2")
    Warn:Dock(TOP)
    Warn:SetContentAlignment(5)
    Warn:SetText("Important - Please Read!")
    Warn:SetSize(0, 72)
    Warn:SetColor(color_black)

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

    local ShowSelectedLimitsetPanel = InformationSheets:AddSheet("Limitset Information", vgui.Create("DScrollPanel"), "icon16/information.png", false, true).Panel
    ShowSelectedLimitsetPanel:Dock(FILL)
    ShowSelectedLimitsetPanel:SetPaintBackground(true)
    ShowSelectedLimitsetPanel:DockMargin(4, -4, 4, 4)

    local ShowSelectedLimitsetSettings = InformationSheets:AddSheet("Changed Settings", vgui.Create("DPanel"), "icon16/cog_edit.png", false, true).Panel
    ShowSelectedLimitsetSettings:Dock(FILL)
    ShowSelectedLimitsetSettings:DockMargin(4, -4, 4, 4)

    local SetTo   = Frame:Add("DButton")
    SetTo:Dock(BOTTOM)
    SetTo:SetSize(0, 64)
    SetTo:DockMargin(8, 0, 8, 8)
    SetTo:SetFont("ACF_LimitsetsNotice_Font6")

    local Right = Material("icon16/arrow_right.png", "mips smooth")

    SetTo.PaintColor = Color(129, 179, 255)
    function SetTo:Paint(w, h)
        self.PaintColor.a = ((math.sin(CurTime() * 6) + 1) / 2) * 150
        DButton.Paint(self, w, h)
        local Skin = self:GetSkin()
        if not self.m_bBackground then return end

        if self.Depressed or self:IsSelected() or self:GetToggle() then
            return Skin.tex.Button_Down(0, 0, w, h, self.PaintColor)
        end

        if self:GetDisabled() then
            return Skin.tex.Button_Dead(0, 0, w, h, self.PaintColor)
        end

        if self.Hovered then
            return Skin.tex.Button_Hovered( 0, 0, w, h, self.PaintColor)
        end

        Skin.tex.Button(0, 0, w, h, self.PaintColor)
    end

    local CurDesc
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
        CurDesc = Desc
        Desc:SetColor(color_black)
        Desc:DockMargin(24, 2, 24, 2)
        Desc:SetContentAlignment(7)
        Desc:SetFont("ACF_LimitsetsNotice_Font4")
        Desc:SetText(Row.LimitSet and (Row.LimitSet.Description or "No description provided.") or "Don't select a limitset. This will keep your current server settings intact.\n\nIf you'd like to use a limitset at the base for your server, but then tweak limits/restrictions and have them persist, select a limitset from the list, choose it, then go back to this menu and choose \"Custom\".\n\nThis will override the settings that the limitset defined, but allow you to change values afterward and have them persist.")
        Desc:SetWrap(true)
        Desc:Dock(TOP)

        local SettingsChanged  = ShowSelectedLimitsetSettings:Add("DListView")
        SettingsChanged:Dock(FILL)
        SettingsChanged:DockMargin(8, 4, 8, 4)
        if Row.LimitSet and next(Row.LimitSet.ServerData) then
            SettingsChanged:AddColumn("Setting Name")
            SettingsChanged:AddColumn("Current Value")
            SettingsChanged:AddColumn("Will Be Changed To")

            for Key, Value in SortedPairs(Row.LimitSet.ServerData, true) do
                local Old     = ACF.GetServerData(Key)
                local Changed = Old ~= Value

                local Phrase  = language.GetPhrase(("acf.globals.%s"):format(Key:lower()))
                local Line    = SettingsChanged:AddLine(Phrase, Old, Value)
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

    local OldFrameLayout = Frame.PerformLayout
    function Frame:PerformLayout(w, h)
        OldFrameLayout(self, w, h)
        Back:SetSize(0, h * .43)
        SelectLimitsetPanel:SetSize(0, h * .11)
        if IsValid(CurDesc) then
            CurDesc:SizeToContentsY()
        end
    end
end

hook.Add("StartCommand", "ACF_Limitsets_Postent", function()
    ShowLimitsetNotice()
    hook.Remove("StartCommand", "ACF_Limitsets_Postent")
end)

concommand.Add("acf_select_limitset", function()
    ShowLimitsetNotice(true)
end)