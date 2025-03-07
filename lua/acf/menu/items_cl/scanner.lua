local ACF = ACF

local function CreateMenu(Menu)
    Menu:AddTitle("#acf.menu.scanner.menu_title")

    local MenuDesc = ""

    for I = 1, 5 do
        MenuDesc = MenuDesc .. language.GetPhrase("acf.menu.scanner.menu_desc" .. I)
    end

    Menu:AddLabel(MenuDesc)

    local playerList = Menu:AddPanel("DListView")
    playerList:Dock(TOP)
    playerList:SetSize(0, 300)
    playerList:SetMultiSelect(false)

    playerList:AddColumn("#acf.menu.scanner.player_name")
    local function PopulatePlayerList()
        local _, selected = playerList:GetSelectedLine()
        if IsValid(selected) and IsValid(selected.player) then
            selected = selected.player
        end

        playerList:Clear()

        for _, v in player.Iterator() do
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

    local btn = Menu:AddButton("#acf.menu.scanner.scan_player")
    local btn2 = Menu:AddButton("#acf.menu.scanner.refresh_players")
    btn:Dock(TOP)
    function btn:DoClickInternal()
        local _, selected = playerList:GetSelectedLine()
        if not IsValid(selected) then
            Derma_Message("#acf.menu.scanner.no_player_selected", "#acf.menu.scanner.scanner_failure", "#acf.menu.scanner.go_back")
            return
        end

        ACF.Scanning.BeginScanning(selected.player)
    end
    function btn2:DoClickInternal()
        PopulatePlayerList()
    end
end

ACF.AddMenuItem(401, "#acf.menu.scanner", "#acf.menu.scanner.menu_name", "transmit", CreateMenu)
