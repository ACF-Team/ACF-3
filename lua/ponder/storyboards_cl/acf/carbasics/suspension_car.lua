if true then return end

local Storyboard = Ponder.API.NewStoryboard("acf", "tankbasics", "suspension")
Storyboard:WithName("Suspension")
Storyboard:WithBaseEntity(nil)
Storyboard:WithModelIcon("models/xeon133/offroad/off-road-40.mdl")
Storyboard:WithDescription("Learn to use the suspension tool with cars")
Storyboard:WithIndexOrder(100)

-------------------------------------------------------------------------------------------------

local Chapter = Storyboard:Chapter("WIP")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "This storyboard is not finished yet.",
    Position = Vector(0.5, 0.5, 0),
}))
