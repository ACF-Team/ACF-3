if true then return end

local Storyboard = Ponder.API.NewStoryboard("acf", "tankextras", "drivetrain_extras")
Storyboard:WithName("Drivetrain Extras")
Storyboard:WithModelIcon("models/engines/transaxial_s.mdl")
Storyboard:WithDescription("Learn about the different types of gearboxes and engines")
Storyboard:WithIndexOrder(100)

-------------------------------------------------------------------------------------------------

local Chapter = Storyboard:Chapter("WIP")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "This storyboard is not finished yet.",
    Position = Vector(0.5, 0.5, 0),
}))
