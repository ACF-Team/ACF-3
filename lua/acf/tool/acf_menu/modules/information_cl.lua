-- This is a custom implementation for tool information 
local MenuImpl = ACF.MenuImpl

local GUI_ICONS = {
    lmb = "gui/lmb.png",
    rmb = "gui/rmb.png",
    key = "gui/key.png"
}

local MOUSE_BUTTONS = {lmb = true, rmb = true}

-- Instruction piece types
local IPTYPE_ICON  = 0
local IPTYPE_INPUT = 1
local IPTYPE_TEXT  = 2

-- Temporary! This should be in the tool context itself!
local Instructions = {
    {
        {Type = IPTYPE_ICON, Icon = "information"},
        {Type = IPTYPE_TEXT, Text = "Select an option from the spawnmenu."},
        {Type = IPTYPE_INPUT, Combo = {"SHIFT", "lmb"}},
        {Type = IPTYPE_TEXT, Text = "is a left click! Isn't that cool!"},
    }
}

surface.CreateFont("ACF.ToolMenu.Key", {
    font = "Tahoma",
    size = 13,
    weight = 900
})


local IconCache = {}
function MenuImpl:CacheIcon(path)
    if not IconCache[path] then IconCache[path] = Material(path) end
    return IconCache[path]
end

function MenuImpl:DrawInformation()
    local Gradient = surface.GetTextureID "gui/gradient"
    local Y = 160
    draw.TexturedQuad({texture = Gradient, x = 0, y = Y, w = ScrW() / 3, h = #Instructions * 26, color = Color(0, 0, 0, 230)})
    for I, Instruction in ipairs(Instructions) do
        local YO = (Y + ((I - 1) * 26)) + 2
        local XO = 64

        for _, RenderPiece in ipairs(Instruction) do
            if RenderPiece.Type == IPTYPE_ICON then
                local Icon = GUI_ICONS[RenderPiece.Icon] or ("icon16/" .. RenderPiece.Icon .. ".png")

                surface.SetMaterial(self:CacheIcon(Icon))
                surface.SetDrawColor(255, 255, 255)
                surface.DrawTexturedRect(XO, YO, 16, 16)
                XO = XO + 24
            elseif RenderPiece.Type == IPTYPE_INPUT then
                for I2, Key in ipairs(RenderPiece.Combo) do
                    if I2 ~= 1 then
                        XO = XO + 8
                        draw.TextShadow({text = "+", font = "ACF.ToolMenu.Key", pos = {XO, YO}, xalign = TEXT_ALIGN_CENTER, yalign = TEXT_ALIGN_TOP, color = color_white}, 1, 50)
                        XO = XO + 8
                    end
                    if MOUSE_BUTTONS[Key] then
                        surface.SetMaterial(self:CacheIcon(GUI_ICONS[Key]))
                        surface.SetDrawColor(255, 255, 255)
                        surface.DrawTexturedRect(XO, YO, 16, 16)
                        XO = XO + 16
                    else
                        surface.SetFont("ACF.ToolMenu.Key")
                        local TSX, TSY = surface.GetTextSize(Key)
                        TSX = TSX + 12
                        surface.SetMaterial(self:CacheIcon("gui/key.png"))
                        surface.SetDrawColor(255, 255, 255)
                        if TSX <= 16 then
                            surface.DrawTexturedRect(XO, YO, 16, 16)
                        else
                            -- need to stretch the key while keeping edges intact. There's probably a nicer way to do it, but this works
                            surface.DrawTexturedRectUV(XO, YO, 8, 16, 0, 0, 0.5, 1)
                            surface.DrawTexturedRectUV(XO + 8, YO, TSX - 16, 16, 0.5, 0, 0.5, 1)
                            surface.DrawTexturedRectUV(XO + (TSX - 8), YO, 8, 16, 0.5, 0, 1, 1)

                            draw.TextShadow({text = Key, font = "ACF.ToolMenu.Key", pos = {XO + (TSX / 2), YO + (TSY / 2)}, xalign = TEXT_ALIGN_CENTER, yalign = TEXT_ALIGN_CENTER, color = Color(45, 45, 45)}, 1, 50)
                        end
                        XO = XO + TSX
                    end
                end
                XO = XO + 8
            elseif RenderPiece.Type == IPTYPE_TEXT then
                local TX, _ = draw.TextShadow({text = language.GetPhrase(RenderPiece.Text), font = "GModToolHelp", pos = {XO, YO}, color = color_white}, 1)
                XO = XO + TX + 8
            else
                ErrorNoHalt("Bad icon type???")
            end
        end
    end
end

-- Hotload.
if ACF.MenuImpl_Hotload then
    ACF.MenuImpl_Hotload()
end