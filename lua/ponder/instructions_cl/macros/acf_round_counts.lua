--- The ACF menu's round list, worked in a menu panel made by ACF.CreateMenuCPanel

local function FindRoundList(Parent)
    for _, Child in ipairs(Parent:GetChildren()) do
        if Child.ClassName == "ACF_RoundList" then return Child end

        local Found = FindRoundList(Child)
        if Found then return Found end
    end
end

local function GetRoundList(playback, Name)
    local panel = playback.Environment:GetNamedObject("VGUIPanel", Name)
    return panel and panel.Base and FindRoundList(panel.Base)
end

--- Clicks Add Round, the new row is a copy of the selected one

local AddMenuRound = Ponder.API.NewInstruction("ACF.AddMenuRound")
AddMenuRound.Length = 0.5

function AddMenuRound:First(playback)
    local List = GetRoundList(playback, self.Name)
    if List and List.OnAddRound then List:OnAddRound(List.Selected) end
end

--- Drags a divider of the round list's bar until the kind before it holds Count rounds

local DragRoundDivider = Ponder.API.NewInstruction("ACF.DragRoundDivider")
DragRoundDivider.Length = 2
DragRoundDivider.Divider = 1

function DragRoundDivider:First(playback)
    local List = GetRoundList(playback, self.Name)
    if not List then return end

    List:ResetBarCounts()
    List.Held = true

    self.From = List:Boundary(self.Divider)
    self.To = self.From - List.BarCounts[self.Divider] + self.Count
end

function DragRoundDivider:Update(playback)
    local List = GetRoundList(playback, self.Name)
    if not (List and self.From) then return end

    local Drag = math.ease.InOutQuad(math.Clamp(playback:GetInstructionProgress(self), 0, 1))

    List:MoveDivider(self.Divider, Lerp(Drag, self.From, self.To))
end

function DragRoundDivider:Last(playback)
    local List = GetRoundList(playback, self.Name)
    if not (List and self.From) then return end

    List:MoveDivider(self.Divider, self.To)
    List.Held = nil
    List:CommitBarCounts()
end
