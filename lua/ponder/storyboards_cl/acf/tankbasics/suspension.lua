local Storyboard = Ponder.API.NewStoryboard("acf", "tankbasics", "suspension")
Storyboard:WithName("Suspension")
Storyboard:WithBaseEntity(nil)
Storyboard:WithModelIcon("models/xeon133/offroad/off-road-80.mdl")
Storyboard:WithDescription("Learn how to make your tank move")
Storyboard:WithIndexOrder(97)

-------------------------------------------------------------------------------------------------

local Chapter = Storyboard:Chapter("WIP")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "This storyboard is not finished yet.",
    Position = Vector(0.5, 0.5, 0),
}))
