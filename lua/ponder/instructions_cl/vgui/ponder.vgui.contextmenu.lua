-- Holds C, right clicks a model to open its context menu, then clicks one of the options.
-- Everything is drawn in 2D over the scene, so the model only needs to exist in the storyboard.

local ContextMenu = Ponder.API.NewRenderer("ContextMenu")

local Font = "Ponder.ContextMenu"
local RowHeight, SpacerHeight, Width, Padding = 30, 9, 260, 4
local RightClickColor = Color(255, 170, 60)

surface.CreateFont(Font, {font = "Tahoma", size = 20})

-- Seconds from the start of the click instruction
local RightClickAt, MoveToOptionAt, LeftClickAt, FadeOutAt = 0.8, 1.2, 2.4, 2.8
local ClickLength = 0.3

local CursorBody = {{x = 0, y = 0}, {x = 16, y = 16}, {x = 0, y = 22}}
local CursorTail = {{x = 5, y = 16}, {x = 9, y = 15}, {x = 13, y = 24}, {x = 9, y = 26}}
local CursorOutline = {{0, 0}, {16, 16}, {9, 16}, {13, 24}, {9, 26}, {5, 18}, {0, 22}}
local CursorScale = 1.5

local function Offset(Points, X, Y)
    local Moved = {}
    for I, P in ipairs(Points) do Moved[I] = {x = X + P.x * CursorScale, y = Y + P.y * CursorScale} end
    return Moved
end

-- A mouse cursor, with a ring growing out of it while Click goes from 0 to 1
function ContextMenu.DrawCursor(X, Y, Alpha, Click, ClickColor)
    if Click then
        local C, R = ClickColor or color_white, 6 + Click * 22
        surface.DrawCircle(X, Y, R, C.r, C.g, C.b, (1 - Click) * Alpha)
        surface.DrawCircle(X, Y, R + 1, C.r, C.g, C.b, (1 - Click) * Alpha)
    end

    draw.NoTexture()
    surface.SetDrawColor(255, 255, 255, Alpha)
    surface.DrawPoly(Offset(CursorBody, X, Y))
    surface.DrawPoly(Offset(CursorTail, X, Y))

    surface.SetDrawColor(0, 0, 0, Alpha)
    for I, P in ipairs(CursorOutline) do
        local N = CursorOutline[I % #CursorOutline + 1]
        surface.DrawLine(X + P[1] * CursorScale, Y + P[2] * CursorScale, X + N[1] * CursorScale, Y + N[2] * CursorScale)
    end
end

local function Step(Time, Start, Length)
    return math.Clamp((Time - Start) / Length, 0, 1)
end

-- Top of each option's row, below the menu's top edge
local function GetRowY(Options, Index)
    local Y = Padding
    for I = 1, Index do
        if Options[I].Spacer then Y = Y + SpacerHeight end
        if I < Index then Y = Y + RowHeight end
    end
    return Y
end

function ContextMenu:Initialize(env)
    env.PonderContextMenu = nil
end

function ContextMenu:Render3D(env)
    local State = env.PonderContextMenu
    if not State then return end

    local Model = env:GetNamedModel(State.Target)
    if IsValid(Model) then State.Screen = Model:LocalToWorld(Model:OBBCenter()):ToScreen() end
end

function ContextMenu:Render2D(env)
    local State = env.PonderContextMenu
    if not (State and State.Screen) then return end

    local Time, Options, Selected = State.Time, State.Options, State.Selected
    local Alpha = (1 - Step(Time, FadeOutAt, State.Length - FadeOutAt)) * 255
    local MX, MY = State.Screen.x, State.Screen.y
    local OptionY = GetRowY(Options, Selected) + RowHeight * 0.5

    -- Glide onto the model, then down to the option once the menu is open
    local Reach = math.ease.InOutQuad(Step(Time, 0, RightClickAt))
    local Pick = math.ease.InOutQuad(Step(Time, MoveToOptionAt, LeftClickAt - MoveToOptionAt - 0.2))
    local X = Lerp(Pick, Lerp(Reach, MX + 220, MX), MX + 40)
    local Y = Lerp(Pick, Lerp(Reach, MY + 160, MY), MY + OptionY)

    if Time >= RightClickAt then
        local MenuAlpha = Step(Time, RightClickAt, 0.15) * Alpha
        local Height = GetRowY(Options, #Options) + RowHeight + Padding

        surface.SetDrawColor(160, 160, 160, MenuAlpha)
        surface.DrawRect(MX - 1, MY - 1, Width + 2, Height + 2)
        surface.SetDrawColor(240, 240, 240, MenuAlpha)
        surface.DrawRect(MX, MY, Width, Height)

        for Index, Option in ipairs(Options) do
            local RowY = MY + GetRowY(Options, Index)

            if Option.Spacer then
                surface.SetDrawColor(200, 200, 200, MenuAlpha)
                surface.DrawRect(MX + Padding, RowY - SpacerHeight * 0.5, Width - Padding * 2, 1)
            end

            if Index == Selected and Pick >= 1 then
                surface.SetDrawColor(144, 194, 255, MenuAlpha)
                surface.DrawRect(MX + 2, RowY, Width - 4, RowHeight)
            end

            if Option.Material then
                surface.SetMaterial(Option.Material)
                surface.SetDrawColor(255, 255, 255, MenuAlpha)
                surface.DrawTexturedRect(MX + 8, RowY + (RowHeight - 20) * 0.5, 20, 20)
            end

            draw.SimpleText(Option.Text, Font, MX + 36, RowY + RowHeight * 0.5, Color(40, 40, 40, MenuAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    local Click, ClickColor
    if Time >= RightClickAt and Time < RightClickAt + ClickLength then Click, ClickColor = Step(Time, RightClickAt, ClickLength), RightClickColor end
    if Time >= LeftClickAt and Time < LeftClickAt + ClickLength then Click = Step(Time, LeftClickAt, ClickLength) end

    ContextMenu.DrawCursor(X, Y, Alpha, Click, ClickColor)
end

local ContextMenuClick = Ponder.API.NewInstruction("ContextMenuClick")
ContextMenuClick.Length = 3.2

function ContextMenuClick:First(playback)
    playback.Environment.PonderContextMenu = {Target = self.Target, Options = self.Options, Selected = self.Selected, Length = self.Length, Time = 0}
end

function ContextMenuClick:Update(playback)
    local State = playback.Environment.PonderContextMenu
    if State then State.Time = playback:GetInstructionProgress(self) * self.Length end
end

function ContextMenuClick:Last(playback)
    playback.Environment.PonderContextMenu = nil
end

local DefaultOptions = {
    {Text = "Remove", Icon = "icon16/delete.png"},
    {Text = "Drive", Icon = "icon16/car.png"},
    {Text = "Disable Collisions", Icon = "icon16/collision_off.png"},
    {Text = "Copy Model to Clipboard", Icon = "icon16/page_copy.png"},
    {Text = "Copy Class to Clipboard", Icon = "icon16/page_copy.png"},
}

local Materials = {}
local function GetMaterial(Icon)
    if not Icon then return end
    Materials[Icon] = Materials[Icon] or Material(Icon)
    return Materials[Icon]
end

local ContextMenuMacro = Ponder.API.NewInstructionMacro("ContextMenu")

function ContextMenuMacro:Run(chapter, parameters)
    local Options, Selected = {}, 1
    local List = table.Add(table.Copy(parameters.Options or DefaultOptions), parameters.Append or {})

    for Index, Option in ipairs(List) do
        Options[Index] = {Text = Option.Text, Material = GetMaterial(Option.Icon), Spacer = Option.Spacer}
        if Option.Text == parameters.Select then Selected = Index end
    end

    local Length = ContextMenuClick.Length
    chapter:AddInstruction("KeyPress", {Name = "ContextMenuKey", Key = "C", Position = parameters.KeyPosition or Vector(0.5, 0.8, 0), Hold = Length - 0.6})
    chapter:AddInstruction("ContextMenuClick", {Target = parameters.Target, Options = Options, Selected = Selected})

    return Length
end

--[[ Example:
    Chapter:AddDelay(Chapter:AddInstruction("ContextMenu", {
        Target = "Crate",
        Append = {{Text = "Edit Crate", Icon = "icon16/box.png", Spacer = true}},
        Select = "Edit Crate",
    }))
]]
