local Storyboard = Ponder.API.NewStoryboard("acf", "tankbasics", "armor")
Storyboard:WithName("Armor")
Storyboard:WithBaseEntity(nil)
Storyboard:WithModelIcon("models/props_c17/streetsign004f.mdl")
Storyboard:WithDescription("Learn how to protect your tank")
Storyboard:WithIndexOrder(95)

-------------------------------------------------------------------------------------------------

local Chapter = Storyboard:Chapter("WIP")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "This storyboard is not finished yet.",
    Position = Vector(0.5, 0.5, 0),
}))
