if true then return end

local Storyboard = Ponder.API.NewStoryboard("acf", "tankextras", "turret_extras")
Storyboard:WithName("Turret Extras")
Storyboard:WithBaseEntity(nil)
Storyboard:WithModelIcon("models/acf/core/t_drive_e.mdl")
Storyboard:WithDescription("Learn about motors, stabilizers and center of mass")
Storyboard:WithIndexOrder(98)

-------------------------------------------------------------------------------------------------

local Chapter = Storyboard:Chapter("WIP")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "This storyboard is not finished yet.",
    Position = Vector(0.5, 0.5, 0),
}))
