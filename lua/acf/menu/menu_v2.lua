ACF.Tool = {}

ACF.Tool.ToolDirectory = {}

function ACF.Tool:AddToolMenu(name, icon, order)
    local obj = {}
    obj.Type = "Menu"
    ACF.Tool.ToolDirectory[name] = obj

    local parts = string.Split(name, '/')
    obj.Name   = parts[#parts]
    parts[#parts] = nil
    obj.Icon = icon
    obj.Category = table.concat(parts, "/")
    obj.Order    = order

    return obj
end

function ACF.Tool:AddToolCategory(name, icon, order)
    local obj = {}
    obj.Type = "Category"
    ACF.Tool.ToolDirectory[name] = obj

    local parts = string.Split(name, '/')
    obj.Name   = parts[#parts]
    parts[#parts] = nil
    obj.Icon = icon
    obj.Category = table.concat(parts, "/")
    obj.Order  = order

    return obj
end

-- Note; unlike the last time, these would get defined in their own files, not all in the same place

ACF.Tool:AddToolCategory("About the Addon", "icon16/information.png", 0)
ACF.Tool:AddToolCategory("Settings",        "icon16/wrench.png", 1000)
ACF.Tool:AddToolCategory("Entities",        "icon16/brick.png", 2000)
ACF.Tool:AddToolCategory("Fun Stuff",       "icon16/bricks.png", 3000)

ACF.Tool:AddToolMenu("About the Addon/Updates",     "icon16/newspaper.png", 100)
ACF.Tool:AddToolMenu("About the Addon/Online Wiki", "icon16/book_open.png", 1000)
ACF.Tool:AddToolMenu("About the Addon/Contact Us",  "icon16/feed.png", 2000)

ACF.Tool:AddToolMenu("Settings/Clientside Settings", "icon16/user.png", 0)
ACF.Tool:AddToolMenu("Settings/Serverside Settings", "icon16/server.png", 1000)

ACF.Tool:AddToolMenu("Entities/Baseplates", "icon16/shape_square.png", 0)
ACF.Tool:AddToolMenu("Entities/Weapons",    "icon16/gun.png", 1000)
ACF.Tool:AddToolMenu("Entities/Turrets",    "icon16/shape_align_center.png", 2000)
ACF.Tool:AddToolMenu("Entities/Engines",    "icon16/car.png", 3000)
ACF.Tool:AddToolMenu("Entities/Gearboxes",  "icon16/cog.png", 4000)
ACF.Tool:AddToolMenu("Entities/Sensors",    "icon16/transmit.png", 5000)
ACF.Tool:AddToolMenu("Entities/Components", "icon16/drive.png", 6000)

ACF.Tool:AddToolMenu("Fun Stuff/Piledrivers", "icon16/pencil.png", 0)
ACF.Tool:AddToolMenu("Fun Stuff/Armor",       "icon16/brick.png", 1000)

ACF.Tool:AddToolMenu("Scanner", "icon16/magnifier.png", 4000)

if CLIENT then
    surface.CreateFont("ACF.ToolMenu.Key", {
        font = "Tahoma",
        size = 13,
        weight = 900
    })

    surface.CreateFont("ACF.ToolMenu.LargeNode", {
        font = "Roboto",
        size = 17,
        weight = 900
    })

    surface.CreateFont("ACF.ToolMenu.SmallNode", {
        font = "Roboto",
        size = 14,
        weight = 900
    })
end
local function SetupMenu(Refreshed)
    local gmod_tool = weapons.GetStored "gmod_tool"
    if not gmod_tool then return end

    local acf_menu_v2 = gmod_tool.Tool.acf_menu_v2
    if not acf_menu_v2 then return end

    print("OK; found both")
    local TOOL = acf_menu_v2

    ACF.Tool.Instructions = {
        {{Type = "icon", Icon = "information"}, {Type = "text", Text = "Select an option from the spawnmenu."}}
    }
    ACF.Tool.IconCache = {}

    function ACF.Tool:GetInstance(ply)
        if CLIENT then ply = LocalPlayer() end

        local gmod_tool = ply:GetWeapon("gmod_tool")
        if not IsValid(gmod_tool) then return end

        local tool_object = gmod_tool:GetToolObject("acf_menu_v2")
        if not tool_object then return end

        return tool_object
    end

    local __in_gui = {
        lmb = "gui/lmb.png",
        rmb = "gui/rmb.png",
        key = "gui/key.png"
    }
    local __mousebuttons = {lmb = true, rmb = true}

    function ACF.Tool:CacheIcon(path)
        if not ACF.Tool.IconCache[path] then ACF.Tool.IconCache[path] = Material(path) end

        return ACF.Tool.IconCache[path]
    end

    if CLIENT then
        function TOOL:DrawHUD()
            local gradient = gmod_tool.Gradient
            local y = 160

            draw.TexturedQuad({texture = gradient, x = 0, y = y, w = ScrW() / 3, h = #ACF.Tool.Instructions * 26, color = Color(0, 0, 0, 230)})

            for i, v in ipairs(ACF.Tool.Instructions) do
                local yO = (y + ((i - 1) * 26)) + 2
                local xO = 64


                for _, renderPiece in ipairs(v) do
                    if renderPiece.Type == "icon" then
                        local icon = __in_gui[renderPiece.Icon] or ("icon16/" .. renderPiece.Icon .. ".png")

                        surface.SetMaterial(ACF.Tool:CacheIcon(icon))
                        surface.SetDrawColor(255, 255, 255)
                        surface.DrawTexturedRect(xO, yO, 16, 16)
                        xO = xO + 24
                    elseif renderPiece.Type == "input" then
                        for i2, key in ipairs(renderPiece.Combo) do
                            if i2 ~= 1 then
                                xO = xO + 8
                                draw.TextShadow({text = "+", font = "ACF.ToolMenu.Key", pos = {xO, yO}, xalign = TEXT_ALIGN_CENTER, yalign = TEXT_ALIGN_TOP, color = color_white}, 1, 50)
                                xO = xO + 8
                            end
                            if __mousebuttons[key] then
                                surface.SetMaterial(ACF.Tool:CacheIcon(__in_gui[key]))
                                surface.SetDrawColor(255, 255, 255)
                                surface.DrawTexturedRect(xO, yO, 16, 16)
                                xO = xO + 16
                            else
                                surface.SetFont("ACF.ToolMenu.Key")
                                local tsX, tsY = surface.GetTextSize(key)
                                tsX = tsX + 12
                                surface.SetMaterial(ACF.Tool:CacheIcon("gui/key.png"))
                                surface.SetDrawColor(255, 255, 255)
                                if tsX <= 16 then
                                    surface.DrawTexturedRect(xO, yO, 16, 16)
                                else
                                    -- need to stretch the key while keeping edges intact. There's probably a nicer way to do it, but this works
                                    surface.DrawTexturedRectUV(xO, yO, 8, 16, 0, 0, 0.5, 1)
                                    surface.DrawTexturedRectUV(xO + 8, yO, tsX - 16, 16, 0.5, 0, 0.5, 1)
                                    surface.DrawTexturedRectUV(xO + (tsX - 8), yO, 8, 16, 0.5, 0, 1, 1)

                                    draw.TextShadow({text = key, font = "ACF.ToolMenu.Key", pos = {xO + (tsX / 2), yO + (tsY / 2)}, xalign = TEXT_ALIGN_CENTER, yalign = TEXT_ALIGN_CENTER, color = Color(45, 45, 45)}, 1, 50)
                                end
                                xO = xO + tsX
                            end
                        end
                        xO = xO + 8
                    elseif renderPiece.Type == "text" then
                        local tX, _ = draw.TextShadow({text = language.GetPhrase(renderPiece.Text), font = "GModToolHelp", pos = {xO, yO}, color = color_white}, 1)
                        xO = xO + tX
                    end
                end
            end
        end

        function ACF.Tool:LoadSpawnMenu(Panel)
            local Menu = ACF.SpawnMenuV2

            if not IsValid(Menu) then
                Menu = vgui.Create("ACF_Panel")
                Menu.Panel = Panel

                Panel:AddItem(Menu)

                ACF.SpawnMenuV2 = Menu
            else
                Menu:ClearAllTemporal()
                Menu:ClearAll()
            end

            local Reload = Menu:AddButton("Reload Menu")
            Reload:SetTooltip("You can also type 'acf_reload_spawn_menu' in console.")
            function Reload:DoClickInternal()
                ACF.Tool:LoadSpawnMenu(Panel)
            end

            local Tree = Menu:AddPanel("DTree")
            Tree:SetSize(0, 384)
            function Tree:OnNodeSelected(Node)
                if self.Selected == Node then return end
                if Node.Data.Type == "Category" then
                    self:SetSelectedItem(self.LastSelected)
                return end

                self.Selected = Node

                Menu:ClearTemporal()
                if Node.Action then
                    Menu:StartTemporal()

                    Node.Action(Menu)

                    Menu:EndTemporal()
                end

                self.LastSelected = Node
            end

            local TreeStruct = {
                Type = "Category",
                Root = true,
                ChildrenLookup = {},
                ChildrenList = {}
            }
            local Unacknowledged = {}
            for k, v in pairs(self.ToolDirectory) do Unacknowledged[k] = v end
            for _ = 1, 30 do
                for k, v in pairs(Unacknowledged) do
                    if Unacknowledged[k] then
                        local catsearch = TreeStruct
                        local parts = string.Split(k, "/")
                        for i = 1, #parts - 1 do
                            catsearch = catsearch.ChildrenLookup[parts[i]]
                            if not catsearch then break end
                        end

                        if catsearch then
                            if not catsearch.ChildrenLookup then
                                error("Tried to add category onto a menu... category was " .. v.Name .. ", tried to add to " .. catsearch.Name)
                            end

                            local obj = {
                                Name = parts[#parts],
                                Icon = v.Icon,
                                Type = v.Type,
                                Order = v.Order
                            }
                            catsearch.ChildrenLookup[parts[#parts]] = obj

                            if v.Type == "Category" then
                                obj.ChildrenLookup = {}
                                obj.ChildrenList = {}
                            end

                            catsearch.ChildrenList[#catsearch.ChildrenList + 1] = catsearch.ChildrenLookup[parts[#parts]]
                            Unacknowledged[k] = nil
                        end
                    end
                end
            end

            local AddNode
            Tree:SetLineHeight(19)
            function AddNode(node, to)
                if node.ChildrenList then
                    table.SortByMember(node.ChildrenList, "Order", true)
                    for _, child in ipairs(node.ChildrenList) do
                        local nodeControl = to:AddNode(child.Name, child.Icon)
                        AddNode(child, nodeControl)
                        nodeControl:SetExpanded(true)
                        nodeControl.Data = child
                        nodeControl:SetDoubleClickToOpen(false)
                        if node.Root then
                            nodeControl.Label:SetFont("ACF.ToolMenu.LargeNode")
                        else
                            nodeControl.Label:SetFont("ACF.ToolMenu.SmallNode")
                        end
                        function nodeControl:Paint(w, h)

                        end
                    end
                end
            end

            AddNode(TreeStruct, Tree)
        end

        function TOOL.BuildCPanel(dform)
            ACF.Tool:LoadSpawnMenu(dform)
        end
    end
    -- Lifehack
    if CLIENT and Refreshed then
        local instance = ACF.Tool:GetInstance()
        for k, v in pairs(TOOL) do
            instance[k] = v
        end
    end
end

SetupMenu(false)
hook.Add("InitPostEntity", "ACF_InitPostEntity_ToolSetup", function()
    SetupMenu(true)
end)