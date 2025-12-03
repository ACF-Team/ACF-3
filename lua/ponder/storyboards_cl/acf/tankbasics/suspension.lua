local Storyboard = Ponder.API.NewStoryboard("acf", "tankbasics", "suspension")
Storyboard:WithName("Suspension")
Storyboard:WithBaseEntity(nil)
Storyboard:WithModelIcon("models/xeon133/offroad/off-road-40.mdl")
Storyboard:WithDescription("Learn to use the suspension tool")
Storyboard:WithIndexOrder(97)

-------------------------------------------------------------------------------------------------

local Chapter = Storyboard:Chapter("Setup")
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1,  Angle = -225, Distance = 2000}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Length = 0.5,
    Models = {
        {Name = "Base", IdentifyAs = "Base", Model = "models/hunter/plates/plate2x5.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 0, 50), Scale = Vector(1, 1.25, 1), },
        {Name = "Engine", IdentifyAs = "Engine", Model = "models/engines/v12l.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, -84, 3), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        {Name = "Gearbox", IdentifyAs = "Gearbox", Model = "models/engines/transaxial_s.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, -144, 3), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", Scale = Vector(2, 2, 2)},
        {Name = "FuelTank1", IdentifyAs = "Fuel Tank", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, -90, 0), Position = Vector(36, -84, 15), ComeFrom = Vector(0, 0, 50), Scale = Vector(6, 2, 2), Material = "models/props_canal/metalcrate001d", ParentTo = "Base", },
        {Name = "FuelTank2", IdentifyAs = "Fuel Tank", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, -90, 0), Position = Vector(-36, -84, 15), ComeFrom = Vector(0, 0, 50), Scale = Vector(6, 2, 2), Material = "models/props_canal/metalcrate001d", ParentTo = "Base", },
    }
}))

local Chapter = Storyboard:Chapter("Adding Wheels")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Spawn out 8 wheels from the spawn menu.\nWe are using (models/xeon133/offroad/off-road-40.mdl) for this example."}))

Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Length = 4,
    Models = {
        {Name = "LWheel1", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(72, -144, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        {Name = "LWheel2", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(72, -48, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        {Name = "LWheel3", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(72, 48, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        {Name = "LWheel4", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(72, 144, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        {Name = "RWheel1", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(-72, -144, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        {Name = "RWheel2", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(-72, -48, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        {Name = "RWheel3", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(-72, 48, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        {Name = "RWheel4", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(-72, 144, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
    }
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Make sure they are all parallel to the baseplate.\nIdeally use Precision Alignment to align them properly, or the physics gun if you don't know Precision Alignment yet."}))

local Chapter = Storyboard:Chapter("Linking Wheels")
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Using the ACF Menu tool, link the wheels on either side of the gearbox to the gearbox."}))

Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {
    Children = {"LWheel1", "RWheel1"},
    Target = "Gearbox",
    Easing = math.ease.InOutQuad,
    Length = 2,
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Now power from the engine can reach the wheels."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "The suspension tool will consider these drive wheels / sprockets that all the other wheels will be slaved to."}))

Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

Chapter:AddDelay(1)
local Chapter = Storyboard:Chapter("Suspension Tool Usage")
Chapter:AddDelay(1)

Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("ACF Suspension Tool")}):DelayByLength()

Chapter:AddInstruction("PlacePanel", {
    Name = "SuspensionMenuCPanel",
    Type = "DPanel",
    Calls = {
        {Method = "SetSize", Args = {300, 700}},
        {Method = "SetPos", Args = {1500, 0}},
        {Method = "CenterVertical", Args = {}},
    },
    Length = 0.25,
}):DelayByLength()
Chapter:AddInstruction("ACF.CreateMenuCPanel", {Name = "SuspensionMenuCPanel", Label = "ACF Menu"}):DelayByLength()
Chapter:AddInstruction("ACF.InitializeCustomACFMenu", {Name = "SuspensionMenuCPanel", CreateMenu = ACF.CreateSuspensionToolMenuHeadless}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "We recommend beginners use rigid suspension, since it is the easiest and most optimized."}))
Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "SuspensionMenuCPanel", ComboBoxName = "Spring Type", OptionID = 1}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "First shift + right click the baseplate."}))
Chapter:AddDelay(Chapter:AddInstruction("FlashModel", {Reps = 2, Models = {"Base"}}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Select (in any order) all wheels you want attached with right click."}))
Chapter:AddDelay(Chapter:AddInstruction("FlashModel", {Reps = 2, Models = {"LWheel1", "LWheel2", "LWheel3", "LWheel4", "RWheel1", "RWheel2", "RWheel3", "RWheel4"}}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Clear the drivetrain of any previously existing constraints for optimization."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Press the create button once to create the suspension. Avoid doing this multiple times to prevent redundant constraints."}))
Chapter:RecommendStoryboard("acf.tankbasics.turrets")