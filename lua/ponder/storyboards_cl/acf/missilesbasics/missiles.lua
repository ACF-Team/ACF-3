if true then return end

local Storyboard = Ponder.API.NewStoryboard("acf", "missilesbasics", "missiles")
Storyboard:WithName("Missiles")
Storyboard:WithModelIcon("models/missiles/at3.mdl")
Storyboard:WithDescription("Learn about the different types of missiles and setup a basic ATGM")
Storyboard:WithIndexOrder(100)

-------------------------------------------------------------------------------------------------

local Chapter = Storyboard:Chapter("WIP")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "This storyboard is not finished yet.",
    Position = Vector(0.5, 0.5, 0),
}))
