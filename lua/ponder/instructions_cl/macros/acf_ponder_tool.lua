local ACFMenu = Ponder.API.NewInstructionMacro("ACF Menu")
local SelectedColor = Color(100, 255, 100, 255)
local ClearedColor = Color(255, 255, 255, 255)

function ACFMenu:Run(chapter, parameters)
    local length = parameters.Length or 1
    local timeForEachClick = length / (#parameters.Children + 1)

    local tAdd = 0
    for _, child in ipairs(parameters.Children) do
        chapter:AddInstruction("MoveToolgunTo", {Time = tAdd, Target = child, Easing = parameters.Easing})
        tAdd = tAdd + timeForEachClick
        chapter:AddInstruction("ClickToolgun", {Time = tAdd, Target = child})
        chapter:AddInstruction("ColorModel", {Time = tAdd, Target = child, Length = 0.1, Color = SelectedColor})
    end

    chapter:AddInstruction("MoveToolgunTo", {Time = tAdd, Target = parameters.Target, Easing = parameters.Easing})
    chapter:AddInstruction("ClickToolgun", {Time = tAdd + timeForEachClick, Target = parameters.Target})
    for _, child in ipairs(parameters.Children) do
        chapter:AddInstruction("ColorModel", {Time = tAdd + timeForEachClick, Target = child, Length = 0.1, Color = ClearedColor})
    end

    return tAdd + timeForEachClick
end

local CaptionIndex = 0 -- Systime as UUID? lol...
local Caption = Ponder.API.NewInstructionMacro("Caption")
function Caption:Run(chapter, parameters)
    local FadeInOutTime = parameters.FadeInOutTime or 0.5
    local WPM = parameters.WPM or 200
    local TextLength = parameters.TextLength or #string.Explode(" ", parameters.Text) / WPM * 60

    local UseEntity = parameters.UseEntity or false

    CaptionIndex = CaptionIndex + 1
    local Name = parameters.Name or "Caption" .. CaptionIndex
    local tAdd = 0
    chapter:AddInstruction("ShowText", {
        Time = parameters.Time or tAdd,
        Length = FadeInOutTime,
        Name = Name,
        Dimension = not UseEntity and "2D" or "3D",
        Text = parameters.Text,
        Horizontal = parameters.Horizontal or TEXT_ALIGN_CENTER,
        PositionRelativeToScreen = not UseEntity and true or false,
        Position = parameters.Position or Vector(0.5, 0.25, 0),
        ParentTo = parameters.ParentTo or nil,
    })
    tAdd = tAdd + FadeInOutTime + TextLength

    if not parameters.KeepText then
        chapter:AddInstruction("HideText", {
            Time = tAdd,
            Length = FadeInOutTime,
            Name = Name,
        })
        tAdd = tAdd + FadeInOutTime
    end

    return tAdd, Name
end

---

local StateText = Ponder.API.NewInstruction("StateText")
StateText.Name                     = ""
StateText.Dimension                = "3D"
StateText.Position                 = vector_origin
StateText.Icons                    = {}
StateText.Time                     = 0
StateText.Length                   = 0.5
StateText.Horizontal               = TEXT_ALIGN_LEFT
StateText.Vertical                 = TEXT_ALIGN_TOP
StateText.TextAlignment            = TEXT_ALIGN_LEFT
StateText.PositionRelativeToScreen = false
StateText.RenderOnTopOfRenderers   = true
StateText.LocalizeText             = true -- Running language.GetPhrase every frame MAY NOT BE A GOOD IDEA?
function StateText:First(playback)
    local env = playback.Environment
    local txt = env:NewText(self.Name)

    txt.Dimension = self.Dimension
    txt.Position = self.Position

    if self.ParentTo then
        local parent = env:GetNamedModel(self.ParentTo)
        txt.Parent = parent
    end

    txt.PositionRelativeToScreen = self.PositionRelativeToScreen
    txt.Horizontal               = self.Horizontal
    txt.Vertical                 = self.Vertical
    txt.TextAlignment            = self.TextAlignment
    txt.RenderOnTopOfRenderers   = self.RenderOnTopOfRenderers

    self:Update(playback)
end

function StateText:Update(playback)
    local env = playback.Environment
    local txt = env:GetNamedText(self.Name)

    local progress = math.ease.OutQuad(playback:GetInstructionProgress(self))

    local text = tostring(self.TextFunction(progress))
    self.Markup = "<font=DermaLarge>" .. (self.LocalizeText and language.GetPhrase(text) or text) .. "</font>"

    txt:SetMarkup(noMarkup and self.Markup or language.GetPhrase(self.Markup))
end

function StateText:Last(playback)
    local env = playback.Environment
    env:RemoveTextByName(self.Name)
end

---

local FlashModel = Ponder.API.NewInstructionMacro("FlashModel")
function FlashModel:Run(chapter, parameters)
    local length = parameters.Length or 1
    local reps = parameters.Reps or 1
    local lengthPerRep = length / reps

    local fillColor = parameters.FillColor or Color(0, 0, 255, 255)
    local clearColor = parameters.ClearColor or Color(255, 255, 255, 255)

    local tAdd = 0
    for _ = 1, reps do
        for _, model in ipairs(parameters.Models) do
            chapter:AddInstruction("ColorModel", {Time = tAdd, Target = model, Length = lengthPerRep / 2, Color = fillColor})
        end

        tAdd = tAdd + lengthPerRep / 2
        for _, model in ipairs(parameters.Models) do
            chapter:AddInstruction("ColorModel", {Time = tAdd, Target = model, Length = lengthPerRep / 2, Color = clearColor})
        end
        tAdd = tAdd + lengthPerRep / 2
    end

    return tAdd + length / 2
end

local PlaceModels = Ponder.API.NewInstructionMacro("PlaceModels")
function PlaceModels:Run(chapter, parameters)
    local length = parameters.Length or 1
    local timeForEachClick = length / (#parameters.Models + 1)

    local tAdd = 0
    for _, data in ipairs(parameters.Models) do
        chapter:AddInstruction("PlaceModel", {
            Time = tAdd,
            Name = data.Name,
            IdentifyAs = data.IdentifyAs,
            Model = data.Model,
            Angles = data.Angles,
            Position = data.Position,
            ComeFrom = data.ComeFrom,
            Scale = data.Scale,
            ParentTo = data.ParentTo or nil,
        })
        if data.Material then
            chapter:AddInstruction("MaterialModel", {Time = tAdd, Target = data.Name, Material = data.Material})
        end
        tAdd = tAdd + timeForEachClick
    end
    return tAdd + timeForEachClick
end

local RemoveModels = Ponder.API.NewInstructionMacro("RemoveModels")
function RemoveModels:Run(chapter, parameters)
    local length = parameters.Length or 1
    local timeForEachClick = length / (#parameters.Models + 1)

    local Models = table.Reverse(parameters.Models)
    local tAdd = 0
    for _, data in ipairs(Models) do
        chapter:AddInstruction("RemoveModel", {Time = tAdd, Name = data.Name})
        tAdd = tAdd + timeForEachClick
    end
    return tAdd + timeForEachClick
end
