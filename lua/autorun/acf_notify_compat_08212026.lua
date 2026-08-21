if SERVER then return end

local COOKIE_NAME = "acf_compatibilitywarning_08212026_dontshowagainuntilmerge"

local function ShowACFWarning()
    if cookie.GetString(COOKIE_NAME, "false") == "true" then return end

    local frame = vgui.Create("DFrame")
    frame:SetTitle("ACF - Compatibility Warning")
    frame:SetSize(ScrW() / 3, ScrH() / 3)
    frame:Center()
    frame:MakePopup()
    frame:SetSizable(false)

    local label = vgui.Create("DLabel", frame)
    label:SetPos(15, 35)
    label:SetSize(490, 100)
    label:SetFont("Trebuchet18")
    label:Dock(FILL)
    label:DockMargin(32, 32, 32, 32)
    label:SetWrap(true)
    label:SetContentAlignment(5)
    label:SetText([[This server is on the dev branch, which recently had vast internal changes. 
Your builds on this branch, if saved to a dupe, will not work on master until dev is merged into master. 
Please don't work on anything that you immediately want to use on the master version of the addon.

If you run into issues, please report them on the GitHub (https://github.com/ACF-Team/ACF-3), providing reproduction steps (if possible), symptoms of the problem, and stack tracebacks (if available)]])

    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetText("Close")
    closeBtn:SetSize(100, 25)
    closeBtn:DockMargin(4, 4, 4, 4)
    closeBtn:Dock(BOTTOM)

    local checkbox = vgui.Create("DCheckBoxLabel", frame)
    checkbox:SetText("Don't show this again, and provide an in game notification when dev has been merged into master")
    checkbox:SizeToContents()
    checkbox:Dock(BOTTOM)
    checkbox:DockMargin(4, 4, 4, 4)

    closeBtn.DoClick = function()
        if checkbox:GetChecked() then
            cookie.Set(COOKIE_NAME, "true")
        end
        frame:Close()
    end
end

hook.Add("InitPostEntity", "ACF_ShowDevBranchWarning", function()
    ShowACFWarning()
end)