if SERVER then return end

local COOKIE_NAME = "acf_compatibilitywarning_08212026_dontshowagainuntilmerge"

local function ShowACFWarning()
    if cookie.GetString(COOKIE_NAME, "false") == "true" then return end

    local frame = vgui.Create("DFrame")
    frame:SetTitle("ACF - Compatibility Warning")
    frame:SetSize(ScrW() / 4, ScrH() / 4)
    frame:Center()
    frame:MakePopup()
    frame:SetSizable(false)

    local label = vgui.Create("DLabel", frame)
    label:SetPos(15, 35)
    label:SetSize(490, 100)
    label:SetWrap(true)
    label:SetContentAlignment(7)
    label:SetText([[This server is on the dev branch, which recently had vast internal changes. 
    Your builds on this branch, if saved to a dupe, will not work on master until dev is merged into master. 
    Please don't work on anything that you immediately want to use on the master version of the addon.

    If you run into issues, please report them on the GitHub (https://github.com/ACF-Team/ACF-3), providing reproduction steps (if possible), symptoms of the problem, and stack tracebacks (if available)]])

    local checkbox = vgui.Create("DCheckBoxLabel", frame)
    checkbox:SetText("Don't show this again, and provide an in game notification when dev has been merged into master")
    checkbox:SizeToContents()
    checkbox:SetPos(frame:GetWide() - checkbox:GetWide() - 15, 140)

    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetText("Close")
    closeBtn:SetSize(100, 25)
    closeBtn:SetPos((frame:GetWide() / 2) - 50, 170)

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