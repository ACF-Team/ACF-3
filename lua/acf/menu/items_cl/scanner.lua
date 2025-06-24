local ACF = ACF

local function CreateMenu(Menu)
    Menu:AddTitle("#acf.menu.scanner.menu_title")

    local MenuDesc = ""

    for I = 1, 5 do
        MenuDesc = MenuDesc .. language.GetPhrase("acf.menu.scanner.menu_desc" .. I)
    end

    Menu:AddLabel(MenuDesc)

    local playerContainer = Menu:AddPanel("DPanel")
    playerContainer:Dock(TOP)
    playerContainer:SetSize(0, 300)

    local playerList = playerContainer:Add("DScrollPanel")
    playerList:Dock(TOP)
    playerList:SetSize(0, 300)

    local highlight = Color(162, 206, 255, 194)
    local function PopulatePlayerList()
        playerList:Clear()

        for _, v in player.Iterator() do
            local line = playerList:Add("DButton")
            line.player = v
            line:Dock(TOP)
            line:SetText("")
            line:SetTall(32)

            local avatar = line:Add("AvatarImage")
            avatar:SetSize(24, 24)
            avatar:SetPos(4, 4)
            avatar:SetMouseInputEnabled(false)
            avatar:SetPlayer(v, 32)

            function line:Paint(w, h)
                local ply = self.player
                if not IsValid(ply) then return end
                local name = ply:Nick()

                if self:IsHovered() then
                    highlight:SetSaturation(Lerp((math.sin(SysTime() * 7) + 1) / 2, 0.2, 0.4))
                    draw.RoundedBox(2, 0, 0, w, h, highlight)
                end

                draw.SimpleText(name, "ACF_Label", 32, h / 2, color_black, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            function line:DoClickInternal()
                if not IsValid(line.player) then
                    return
                end

                ACF.Scanning.BeginScanning(line.player)
            end
        end
    end
    PopulatePlayerList()

    net.Receive("ACF.Scanning.PlayerListChanged", function()
        timer.Simple(1, function()
            PopulatePlayerList()
        end)
    end)

    local btn2 = Menu:AddButton("#acf.menu.scanner.refresh_players")
    btn2:Dock(TOP)
    function btn2:DoClickInternal()
        PopulatePlayerList()
    end
end

ACF.AddMenuItem(401, "#acf.menu.scanner", "#acf.menu.scanner.menu_name", "transmit", CreateMenu)