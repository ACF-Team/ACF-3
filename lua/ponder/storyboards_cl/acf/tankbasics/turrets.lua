local Storyboard = Ponder.API.NewStoryboard("acf", "tankbasics", "turrets")
Storyboard:WithName("Turrets")
Storyboard:WithBaseEntity(nil)
Storyboard:WithModelIcon("models/acf/core/t_trun.mdl")
Storyboard:WithDescription("Learn how to aim at things")
Storyboard:WithIndexOrder(96)

-------------------------------------------------------------------------------------------------

local Chapter = Storyboard:Chapter("WIP")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "This storyboard is not finished yet.",
    Position = Vector(0.5, 0.5, 0),
}))
