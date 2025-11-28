local Storyboard = Ponder.API.NewStoryboard("acf", "tankbasics", "parenting_linking")
Storyboard:WithName("Parenting & Linking")
Storyboard:WithBaseEntity(nil)
Storyboard:WithModelIcon("models/weapons/w_toolgun.mdl")
Storyboard:WithDescription("Introducing parenting and linking")
Storyboard:WithIndexOrder(98)

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Setup")
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1,  Angle = -225, Distance = 2000}):DelayByLength()

Chapter:AddInstruction("PlaceModel", {
    Name = "Baseplate1",
    IdentifyAs = "acf_baseplate",
    Model = "models/hunter/plates/plate2x5.mdl",
    Position = Vector(0, 0, 0),
    Angles = Angle(0, 0, 0),
    Scale = Vector(1, 1.25, 1),
    ComeFrom = Vector(0, 0, 50)
}):DelayByLength()

Chapter:AddInstruction("PlaceModel", {
    Name = "Engine1",
    Model = "models/engines/v12l.mdl",
    Position = Vector(0, -84, 3),
    Angles = Angle(0, 90, 0),
}):DelayByLength()

Chapter:AddInstruction("PlaceModel", {
    Name = "FuelTank1",
    Model = "models/acf/core/s_fuel.mdl",
    Position = Vector(36, -84, 15),
    Scale = Vector(6, 2, 2),
    Angles = Angle(0, 90, 0),
}):DelayByLength()

Chapter:AddInstruction("PlaceModel", {
    Name = "FuelTank2",
    Model = "models/acf/core/s_fuel.mdl",
    Position = Vector(-36, -84, 15),
    Scale = Vector(6, 2, 2),
    Angles = Angle(0, 90, 0),
}):DelayByLength()

Chapter:AddInstruction("PlaceModel", {
    Name = "Gearbox1",
    Model = "models/engines/transaxial_s.mdl",
    Position = Vector(0, -144, 3),
    Angles = Angle(0, 90, 0),
    Scale = Vector(2, 2, 2),
}):DelayByLength()


local Chapter = Storyboard:Chapter("Parenting & Linking")
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.multi_parent.listname")}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "The Multi Parent tool can parent two entities together.",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(0.5, 0.15, 0),
}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "Parented entities will move and rotate together.",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(0.5, 0.15, 0),
}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "Parenting is considerably more optimized than constraints like welds, so use it whenever possible.",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(0.5, 0.15, 0),
}))
