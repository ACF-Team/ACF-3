if true then return end

local Storyboard = Ponder.API.NewStoryboard("acf", "missilesbasics", "guidances")
Storyboard:WithName("Guidances")
Storyboard:WithModelIcon("models/props_lab/monitor01b.mdl")
Storyboard:WithDescription("Learn about the different guidance methods for missiles")
Storyboard:WithIndexOrder(99)

-------------------------------------------------------------------------------------------------

local Chapter = Storyboard:Chapter("WIP")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "This storyboard is not finished yet.",
    Position = Vector(0.5, 0.5, 0),
}))
