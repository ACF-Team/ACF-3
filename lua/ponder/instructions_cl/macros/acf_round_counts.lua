--- A proxy of the ammo crate's round counts window, built by the same code as the real one

local function DrawCursor(...) Ponder.API.RegisteredRenderers.ContextMenu.DrawCursor(...) end

local function PaintCursor(Panel)
    local Cursor = Panel.PonderCursor
    if Cursor then DrawCursor(Cursor.X, Cursor.Y, 255, Cursor.Click) end
end

local function GetWindow(playback, Name)
    local panel = playback.Environment:GetNamedObject("VGUIPanel", Name)
    return panel, panel and panel.RoundCounts
end

-- Keeps where the cursor starts, so the move can be eased from there
local function StartCursor(self, panel)
    local Cursor = panel.PonderCursor or {X = panel:GetWide() * 0.5, Y = 12}
    panel.PonderCursor = Cursor
    self.StartX, self.StartY = Cursor.X, Cursor.Y
end

local function MoveCursor(self, panel, Progress, X, Y)
    local Move = math.ease.InOutQuad(math.Clamp(Progress, 0, 1))
    panel.PonderCursor.X, panel.PonderCursor.Y = Lerp(Move, self.StartX, X), Lerp(Move, self.StartY, Y)
end

local CreateRoundCounts = Ponder.API.NewInstruction("ACF.CreateRoundCounts")
CreateRoundCounts.Length = 1

function CreateRoundCounts:First(playback)
    local panel = playback.Environment:GetNamedObject("VGUIPanel", self.Name)
    local Kinds = {}

    for Slot, Kind in ipairs(self.Kinds) do Kinds[Slot] = {Name = Kind.Name, Count = Kind.Count, Slot = Slot, Icon = Kind.Icon} end

    panel.RoundCounts = ACF.BuildRoundCountsMenu(panel, self.Capacity, Kinds)
    panel.RoundCapacity = self.Capacity
    panel:SetPos(self.Position and self.Position.x or 1160, self.Position and self.Position.y or (ScrH() - panel:GetTall()) * 0.5)
    panel.PaintOver = PaintCursor
end

--- Drags a divider of the bar until the kind before it holds Count rounds

local DragRoundDivider = Ponder.API.NewInstruction("ACF.DragRoundDivider")
DragRoundDivider.Length = 2
DragRoundDivider.Divider = 1

local ReachEnd, DragEnd = 0.35, 0.9 -- Fractions of the length

local function DividerPos(panel, Window, Index)
    local Bar = Window.Bar
    local X, Y = Bar:GetPos()
    return X + Bar:GetWide() * Window.Boundary(Index) / panel.RoundCapacity, Y + Bar:GetTall() * 0.5
end

function DragRoundDivider:First(playback)
    local panel, Window = GetWindow(playback, self.Name)
    if not Window then return end

    StartCursor(self, panel)
    self.From = Window.Boundary(self.Divider)
    self.To = self.From - Window.Entries[self.Divider].Count + self.Count
end

function DragRoundDivider:Update(playback)
    local panel, Window = GetWindow(playback, self.Name)
    if not (Window and panel.PonderCursor) then return end

    local Progress = playback:GetInstructionProgress(self)
    local Drag = math.ease.InOutQuad(math.Clamp((Progress - ReachEnd) / (DragEnd - ReachEnd), 0, 1))

    if Progress >= ReachEnd then Window.MoveDivider(self.Divider, Lerp(Drag, self.From, self.To)) end

    local X, Y = DividerPos(panel, Window, self.Divider)
    MoveCursor(self, panel, Progress / ReachEnd, X, Y)
    panel.PonderCursor.Click = Progress >= ReachEnd and Progress < DragEnd and 0.3 or nil
end

function DragRoundDivider:Last(playback)
    local panel, Window = GetWindow(playback, self.Name)
    if not Window then return end

    Window.MoveDivider(self.Divider, self.To)
    if panel.PonderCursor then panel.PonderCursor.Click = nil end
end

--- Moves the cursor onto Apply and clicks it, leaving the window for RemovePanel to close

local ClickRoundCountsApply = Ponder.API.NewInstruction("ACF.ClickRoundCountsApply")
ClickRoundCountsApply.Length = 1

function ClickRoundCountsApply:First(playback)
    local panel, Window = GetWindow(playback, self.Name)
    if Window then StartCursor(self, panel) end
end

function ClickRoundCountsApply:Update(playback)
    local panel, Window = GetWindow(playback, self.Name)
    if not (Window and panel.PonderCursor) then return end

    local Progress = playback:GetInstructionProgress(self)
    local Button = Window.Apply
    local X, Y = Button:GetPos()

    MoveCursor(self, panel, Progress / 0.6, X + Button:GetWide() * 0.5, Y + Button:GetTall() * 0.5)
    panel.PonderCursor.Click = Progress >= 0.6 and (Progress - 0.6) / 0.4 or nil
end

--- Opens the crate's context menu to pick Edit Round Counts, then places and fills the proxy window

local ShowRoundCounts = Ponder.API.NewInstructionMacro("ACF.ShowRoundCounts")

function ShowRoundCounts:Run(chapter, parameters)
    local Name = parameters.Name or "RoundCounts"
    local Start = chapter:AddInstruction("ContextMenu", {
        Target = parameters.Target,
        Append = {{Text = "Edit Round Counts", Icon = "icon16/table_edit.png"}},
        Select = "Edit Round Counts",
    })

    chapter:AddInstruction("PlacePanel", {
        Time = Start,
        Name = Name,
        Type = "DFrame",
        Calls = {
            {Method = "SetTitle", Args = {"Round Counts"}},
            {Method = "ShowCloseButton", Args = {false}},
            {Method = "SetDraggable", Args = {false}},
        },
        Length = 0.25,
    })
    chapter:AddInstruction("ACF.CreateRoundCounts", {Time = Start + 0.25, Name = Name, Capacity = parameters.Capacity, Kinds = parameters.Kinds, Position = parameters.Position})

    return Start + 1.25
end
