if true then return end

local Storyboard = Ponder.API.NewStoryboard("acf", "missilesbasics", "radars")
Storyboard:WithName("Radars")
Storyboard:WithModelIcon("models/radar/radar_sp_sml.mdl")
Storyboard:WithDescription("Learn about how to search and track targets")
Storyboard:WithIndexOrder(98)

-------------------------------------------------------------------------------------------------

local Chapter = Storyboard:Chapter("WIP")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "This storyboard is not finished yet.",
    Position = Vector(0.5, 0.5, 0),
}))
