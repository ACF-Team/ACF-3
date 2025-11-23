local Storyboard = Ponder.API.NewStoryboard("acf", "tankbasics", "baseplates")
Storyboard:WithName("Baseplates")
Storyboard:WithBaseEntity(nil)
Storyboard:WithModelIcon("models/hunter/plates/plate1x2.mdl")
Storyboard:WithDescription("Learn the basics of crew.")
Storyboard:WithIndexOrder(5)

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Spawning")

Chapter:AddInstruction("PlaceModel", {
    Name = "Baseplate1",
    IdentifyAs = "acf_baseplate",
    Model = "models/hunter/plates/plate1x2.mdl",
    Position = Vector(0, 0, 0),
    ComeFrom = Vector(0, 0, 32)
}):DelayByLength()

Chapter:AddInstruction("Caption", {
    Text = "Baseplates are the core of any ACF contraption and are required for your vehicles to work.",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(0.5, 0.15, 0),
}):DelayByLength()

Chapter:AddInstruction("RemoveModel", {
    Name = "Baseplate1",
}):DelayByLength()

Chapter:AddInstruction("Caption", {
    Text = "Start by selecting the acf menu tool, then in the menu, select baseplates",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(0.5, 0.15, 0),
})