local ACF = ACF

local function CreateMenu(Menu)
    Menu:AddTitle("Scan a Player [WIP!]")
    Menu:AddLabel([[Select a player below, then hit the Scan Player button. You will enter a spectator perspective mode that allows you to visualize the components of a contraption. 
        
Rotate the camera with your mouse, and use WASD Space/Control to move your location relative to the target. 
Use the scroll wheel to increase/decrease your movement speed.
Advanced controls are given to you on the top-right of your screen.

This was designed to help the community hold each other accountable, and can help with catching some often used exploits and cheating methods. It is still a work in progress, and there are a lot of features missing. Please report any issues on the GitHub repository.]])

    local playerList = Menu:AddPanel("DListView")
    playerList:Dock(TOP)
    playerList:SetSize(0, 300)
    playerList:SetMultiSelect(false)

    playerList:AddColumn("Player Name")
    local function PopulatePlayerList()
        print("PopulatePlayerList called")
        local _, selected = playerList:GetSelectedLine()
        if IsValid(selected) and IsValid(selected.player) then
            selected = selected.player
        end

        playerList:Clear()

        for _, v in ipairs(player.GetAll()) do
            local line = playerList:AddLine(v:Nick())
            line.player = v
            if line.player == selected then
                playerList:SelectItem(line)
            end
        end
    end
    PopulatePlayerList()

    net.Receive("ACF.Scanning.PlayerListChanged", function()
        timer.Simple(1, function()
            PopulatePlayerList()
        end)
    end)

    local btn = Menu:AddButton("Scan Player")
    local btn2 = Menu:AddButton("Refresh Players")
    btn:Dock(TOP)
    function btn:DoClickInternal()
        local _, selected = playerList:GetSelectedLine()
        if not IsValid(selected) then
            Derma_Message("No player selected.", "Scanner Failure", "Go back")
            return
        end

        ACF.Scanning.BeginScanning(selected.player)
    end
    function btn2:DoClickInternal()
        PopulatePlayerList()
    end
end

ACF.AddMenuItem(401, "Scanner", "Scan a Player...", "transmit", CreateMenu)
