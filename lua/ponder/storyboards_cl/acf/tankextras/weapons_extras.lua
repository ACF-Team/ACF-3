if true then return end

local Storyboard = Ponder.API.NewStoryboard("acf", "tankextras", "weapon_extras")
Storyboard:WithName("Weapon Extras")
Storyboard:WithBaseEntity(nil)
Storyboard:WithModelIcon("models/munitions/round_100mm_ap.mdl")
Storyboard:WithDescription("Learn about the different weapon and ammo types")
Storyboard:WithIndexOrder(97)

-------------------------------------------------------------------------------------------------

local Chapter = Storyboard:Chapter("WIP")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "This storyboard is not finished yet.",
    Position = Vector(0.5, 0.5, 0),
}))
