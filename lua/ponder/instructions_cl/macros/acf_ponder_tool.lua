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

local Caption = Ponder.API.NewInstructionMacro("Caption")
function Caption:Run(chapter, parameters)
    local length = parameters.Length or 1
    local tAdd = 0
    chapter:AddInstruction("ShowText", {
        Time = parameters.Time or tAdd,
        Name = parameters.Name or "Explain",
        Dimension = parameters.Dimension or "2D",
        Text = parameters.Text,
        Horizontal = parameters.Horizontal or TEXT_ALIGN_CENTER,
        PositionRelativeToScreen = true,
        Position = parameters.Position or Vector(0.5, 0.25, 0)
    })
    tAdd = tAdd + length
    chapter:AddInstruction("HideText", {Time = tAdd, Name = "Explain"})

    if parameters.Delay then
        tAdd = tAdd + parameters.Delay
        chapter:AddInstruction("Delay", {Length = tAdd + parameters.Delay})
    end

    return tAdd
end

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
