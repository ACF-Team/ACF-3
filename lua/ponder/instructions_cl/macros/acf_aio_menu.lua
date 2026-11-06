--- A proxy of the AIO controller's settings window, built from the controller's own edit data

local ZeroValues = {Bool = false, Float = 0, Int = 0, Vector = Vector(), String = ""}
local HighlightColor = Color(100, 255, 100, 90)
local HighlightTime = 2
local Settings, Defaults

-- Records the controller's editable NetworkVars by running its SetupDataTables on a stand in
local function GetSettings()
    if Settings then return Settings end

    local Stored = scripted_ents.GetStored("acf_controller")
    if not Stored then return {} end

    Settings = {}
    local Recorder = {NetworkVar = function(_, Type, Name, Extended, Extra)
        if isnumber(Name) then Name, Extended = Extended, Extra end -- The slot argument is optional
        if not (Extended and Extended.Edit) then return end
        Settings[#Settings + 1] = {Name = Name, Type = Type, Edit = Extended.Edit, Order = Extended.Edit.order or 0}
    end}

    Stored.t.SetupDataTables(Recorder)
    table.SortByMember(Settings, "Order", true)

    return Settings
end

local function PaintHighlight(Row, W, H)
    local Fade = 1 - (RealTime() - (Row.HighlightedAt or -math.huge)) / HighlightTime
    if Fade <= 0 then return end

    surface.SetDrawColor(HighlightColor.r, HighlightColor.g, HighlightColor.b, HighlightColor.a * Fade)
    surface.DrawRect(0, 0, W, H)
end

--- Filling a placed panel with the proxy settings

-- Shares the context menu's cursor, so both look the same
local function PaintWindowCursor(Panel)
    local Cursor = Panel.AIOCursor
    if Cursor then Ponder.API.RegisteredRenderers.ContextMenu.DrawCursor(Cursor.X, Cursor.Y, 255, Cursor.Click) end
end

local CreateAIOMenu = Ponder.API.NewInstruction("ACF.CreateAIOMenu")
CreateAIOMenu.Length = 1

function CreateAIOMenu:First(playback)
    local panel = playback.Environment:GetNamedObject("VGUIPanel", self.Name)
    Defaults = Defaults or include("entities/acf_controller/modules/defaults.lua")

    local Notice = panel:Add("DLabel")
    Notice:Dock(TOP)
    Notice:DockMargin(5, 5, 5, 5)
    Notice:SetText("Hover over an option to see its description.")
    Notice:SetDark(true)
    Notice:SetFont("ACF_Label")
    Notice:SizeToContents()

    local Properties = panel:Add("DProperties")
    Properties:Dock(FILL)

    panel.AIORows = {}
    for _, Setting in ipairs(GetSettings()) do
        local Row = Properties:CreateRow(Setting.Edit.category, Setting.Name)
        Row:Setup(Setting.Edit.type, Setting.Edit)
        Row:SetTooltip(Setting.Edit.tooltip or "")
        Row.PaintOver = PaintHighlight

        local Value = Defaults[Setting.Name]
        if Value == nil then Value = ZeroValues[Setting.Type] end
        if Value ~= nil then Row:SetValue(Value) end

        panel.AIORows[Setting.Name] = Row
    end

    panel.AIOProperties = Properties
    panel.PaintOver = PaintWindowCursor
end

--- Moves the cursor to a setting in the proxy AIO menu, then clicks to set and highlight it

local SetAIOSetting = Ponder.API.NewInstruction("ACF.SetAIOSetting")
SetAIOSetting.Length = 1.2

local MoveEnd, ClickEnd = 0.6, 0.85 -- Fractions of the length

local function Apply(self, Row)
    if self.Applied then return end
    self.Applied = true

    if self.Value ~= nil then Row:SetValue(self.Value) end
    Row.HighlightedAt = RealTime()
end

function SetAIOSetting:First(playback)
    local panel = playback.Environment:GetNamedObject("VGUIPanel", self.Name)
    local Row = panel.AIORows and panel.AIORows[self.Setting]
    if not IsValid(Row) then return end

    panel.AIOProperties:GetCanvas():ScrollToChild(Row)

    local Cursor = panel.AIOCursor or {X = panel:GetWide() * 0.5, Y = 12}
    panel.AIOCursor = Cursor
    self.StartX, self.StartY = Cursor.X, Cursor.Y
    self.Applied = false
end

function SetAIOSetting:Update(playback)
    local panel = playback.Environment:GetNamedObject("VGUIPanel", self.Name)
    local Row = panel.AIORows and panel.AIORows[self.Setting]
    if not (IsValid(Row) and panel.AIOCursor) then return end

    -- Recomputed every frame, since the list is still scrolling towards the row
    local Progress = playback:GetInstructionProgress(self)
    local TX, TY = panel:ScreenToLocal(Row:LocalToScreen(Row:GetWide() * 0.45 + 24, Row:GetTall() * 0.5))
    local Move = math.ease.InOutQuad(math.Clamp(Progress / MoveEnd, 0, 1))
    local Cursor = panel.AIOCursor

    Cursor.X, Cursor.Y = Lerp(Move, self.StartX, TX), Lerp(Move, self.StartY, TY)
    Cursor.Click = Progress >= MoveEnd and Progress < ClickEnd and (Progress - MoveEnd) / (ClickEnd - MoveEnd) or nil

    if Progress >= MoveEnd then Apply(self, Row) end
end

function SetAIOSetting:Last(playback)
    local panel = playback.Environment:GetNamedObject("VGUIPanel", self.Name)
    local Row = panel.AIORows and panel.AIORows[self.Setting]
    if not IsValid(Row) then return end

    Apply(self, Row)
    if panel.AIOCursor then panel.AIOCursor.Click = nil end
end

--- Opens the target's context menu to pick Edit AIO Settings, then places and fills the proxy window

local ShowAIOMenu = Ponder.API.NewInstructionMacro("ACF.ShowAIOMenu")

function ShowAIOMenu:Run(chapter, parameters)
    local Name = parameters.Name or "AIOMenu"
    local Start = 0

    if parameters.Target then
        Start = chapter:AddInstruction("ContextMenu", {
            Target = parameters.Target,
            Append = {{Text = "Edit AIO Settings", Icon = "icon16/image_edit.png", Spacer = true}},
            Select = "Edit AIO Settings",
        })
    end

    chapter:AddInstruction("PlacePanel", {
        Time = Start,
        Name = Name,
        Type = "DFrame",
        Calls = {
            {Method = "SetSize", Args = {360, 600}},
            {Method = "SetPos", Args = {1440, 0}},
            {Method = "CenterVertical", Args = {}},
            {Method = "SetTitle", Args = {"AIO Controller Settings"}},
            {Method = "ShowCloseButton", Args = {false}},
            {Method = "SetDraggable", Args = {false}},
        },
        Length = 0.25,
    })
    chapter:AddInstruction("ACF.CreateAIOMenu", {Time = Start + 0.25, Name = Name})

    return Start + 1.25
end
