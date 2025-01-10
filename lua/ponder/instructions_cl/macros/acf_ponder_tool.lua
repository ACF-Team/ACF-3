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