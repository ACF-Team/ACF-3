local Storyboard = Ponder.API.NewStoryboard("acf", "tankbasics", "weapons")
Storyboard:WithName("Weapons")
Storyboard:WithBaseEntity(nil)
Storyboard:WithModelIcon("models/munitions/round_100mm.mdl")
Storyboard:WithDescription("Learn how to destroy other tanks")
Storyboard:WithIndexOrder(96)

-------------------------------------------------------------------------------------------------

local Chapter = Storyboard:Chapter("WIP")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "This storyboard is not finished yet.",
    Position = Vector(0.5, 0.5, 0),
}))
