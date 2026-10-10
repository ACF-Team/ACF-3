local Storyboard = Ponder.API.NewStoryboard("acf", "tankextras", "radar_synchronizer")
Storyboard:WithName("Radar Synchronizer")
Storyboard:WithModelIcon("models/props_lab/reciever01d.mdl")
Storyboard:WithDescription("Learn how to combine multiple sensors with the Radar Synchronizer.")
Storyboard:WithIndexOrder(3)

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Setup")
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1, Angle = -225, Distance = 1800}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Length = 0.5,
    Models = {
        {Name = "Base", IdentifyAs = "Base", Model = "models/hunter/plates/plate2x5.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 0, 50), Scale = Vector(1, 1.25, 1), },
        {Name = "Radar1", IdentifyAs = "Radar", Model = "models/radar/radar_sml.mdl", Angles = Angle(0, 0, 0), Position = Vector(60, -60, 15), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        {Name = "Radar2", IdentifyAs = "Radar", Model = "models/radar/radar_sml.mdl", Angles = Angle(0, 180, 0), Position = Vector(-60, -60, 15), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        {Name = "Sync", IdentifyAs = "Radar Synchronizer", Model = "models/props_lab/reciever01d.mdl", Angles = Angle(0, -90, 0), Position = Vector(0, 60, 15), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
    }
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "The Radar Synchronizer links to multiple radars and IRSTs, running one combined detection pass in their place."}))

local Chapter = Storyboard:Chapter("Linking")

Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Right click each sensor, then right click the Synchronizer, to link them."}))
Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {
    Children = {"Radar1", "Radar2"},
    Target = "Sync",
    Easing = math.ease.InOutQuad,
    Length = 2,
}))

Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Once linked, those sensors stop scanning independently. The Synchronizer groups them by scan rate so none of them are sped up or slowed down."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "It picks the healthiest linked sensor with line of sight to each target, and merges every result into its own outputs."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "The merged picture is also mirrored back onto every linked radar, so a missile rack wired to that radar sees it too."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "You can only place 2 per contraption, and sensors auto unlink if they drift too far away."}))
