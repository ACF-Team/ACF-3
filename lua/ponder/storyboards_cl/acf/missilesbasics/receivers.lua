if true then return end

local Storyboard = Ponder.API.NewStoryboard("acf", "missilesbasics", "receivers")
Storyboard:WithName("Receivers")
Storyboard:WithModelIcon("models/bluemetaknight/laser_detector.mdl")
Storyboard:WithDescription("Learn about laser and radar warning receivers")
Storyboard:WithIndexOrder(97)

-------------------------------------------------------------------------------------------------

local Chapter = Storyboard:Chapter("WIP")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "This storyboard is not finished yet.",
    Position = Vector(0.5, 0.5, 0),
}))
