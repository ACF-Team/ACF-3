ACF.Tool = {}

if CLIENT then
    surface.CreateFont("ACF.ToolMenu.Key", {
        font = "Tahoma",
        size = 13,
        weight = 900
    })
    surface.CreateFont("ACF.ToolMenu.Text", {
        font = "Tahoma",
        size = 14,
        weight = 900
    })
end
local function SetupMenu()
    local gmod_tool = weapons.GetStored "gmod_tool"
    if not gmod_tool then return end

    local acf_menu_v2 = gmod_tool.Tool.acf_menu_v2
    if not acf_menu_v2 then return end

    print("OK; found both")
    local TOOL = acf_menu_v2

    ACF.Tool.Instructions = {
        {{Type = "icon", Icon = "information"}, {Type = "text", Text = "Select an option from the spawn-menu."}},
        {{Type = "icon", Icon = "error"}, {Type = "text", Text = "This menu TOO fire"}},
        {{Type = "input", Combo = {"E", "lmb"}}, {Type = "text", Text = "Select an option from the spawn-menu."}},
        {{Type = "input", Combo = {"CTRL", "SHIFT", "rmb"}}, {Type = "text", Text = "Select an option from the spawn-menu."}},
        {{Type = "input", Combo = {"SHIFT", "lmb"}}, {Type = "text", Text = "Select an option from the spawn-menu."}},
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

    function TOOL:DrawHUD()
        local gradient = gmod_tool.Gradient
        local y = 160

        draw.TexturedQuad({texture = gradient, x = 0, y = y, w = ScrW() / 3, h = #ACF.Tool.Instructions * 28, color = Color(0, 0, 0, 230)})

        for i, v in ipairs(ACF.Tool.Instructions) do
            local yO = (y + ((i - 1) * 26)) + 6
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
                            draw.TextShadow({text = "+", font = "ACF.ToolMenu.Text", pos = {xO, yO}, xalign = TEXT_ALIGN_CENTER, yalign = TEXT_ALIGN_TOP, color = color_white}, 1, 50)
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
                    local tX, _ = draw.TextShadow({text = renderPiece.Text, font = "GModToolHelp", pos = {xO, yO},color = color_white}, 1)
                    xO = xO + tX
                end
            end
        end
    end

    -- Lifehack
    if CLIENT then
        local instance = ACF.Tool:GetInstance()
        for k, v in pairs(TOOL) do
            instance[k] = v
        end
    end
end

SetupMenu()
hook.Add("InitPostEntity", "ACF_InitPostEntity_ToolSetup", function()
    SetupMenu()
end)