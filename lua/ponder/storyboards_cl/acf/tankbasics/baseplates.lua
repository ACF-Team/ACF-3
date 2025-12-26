local Storyboard = Ponder.API.NewStoryboard("acf", "tankbasics", "baseplates")
Storyboard:WithName("Baseplates")
Storyboard:WithBaseEntity(nil)
Storyboard:WithModelIcon("models/hunter/plates/plate1x2.mdl")
Storyboard:WithDescription("Learn the basics of baseplates.")
Storyboard:WithIndexOrder(100)

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Selecting")
Chapter:AddDelay(1)

Chapter:AddInstruction("Caption", {
    Text = "Start by selecting the ACF Menu tool, then in the menu, select Baseplates.",
    Length = 3
})

Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")}):DelayByLength()

-- ACF menu initialization
Chapter:AddInstruction("PlacePanel", {
    Name = "MainMenuCPanel",
    Type = "DPanel",
    Calls = {
        {Method = "SetSize", Args = {300, 600}},
        {Method = "SetPos", Args = {1500, 0}},
        {Method = "CenterVertical", Args = {}},
    },
    Length = 0.25,
}):DelayByLength()

Chapter:AddInstruction("ACF.CreateMenuCPanel", {Name = "MainMenuCPanel", Label = "ACF Menu"}):DelayByLength()
Chapter:AddInstruction("ACF.InitializeMainMenu", {Name = "MainMenuCPanel"}):DelayByLength()
Chapter:AddInstruction("ACF.SelectMenuTreeNode", {Name = "MainMenuCPanel", Select = "#acf.menu.baseplates"}):DelayByLength()

Chapter:AddDelay(1)
local Chapter = Storyboard:Chapter("Options")
Chapter:AddDelay(1)

Chapter:AddInstruction("Caption", {
    Text = "Scroll down and set the Length and Width to your desired size. For this example, use 240x96x1.5.",
    TextLength = 3,
})

Chapter:AddInstruction("ACF.ScrollToMenuPanel", {Name = "MainMenuCPanel", Scroll = "#acf.menu.baseplates.plate_thickness"}):DelayByLength()

Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.baseplates.plate_length", Value = 240}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.baseplates.plate_width", Value = 96}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.baseplates.plate_thickness", Value = 1.5}):DelayByLength()

Chapter:AddInstruction("Caption", {
    Text = "Average tank baseplates are typically around 144x78x1.5. This depends on the size of your tank.",
    TextLength = 3,
})

Chapter:AddDelay(1)
local Chapter = Storyboard:Chapter("Spawning")
Chapter:AddDelay(1)

Chapter:AddInstruction("Caption", {
    Text = "Press Mouse1 (Left Click) to spawn a baseplate where you're aiming.",
    TextLength = 3,
})

Chapter:AddInstruction("ClickToolgun", {}):DelayByLength()

Chapter:AddInstruction("PlaceModel", {
    Name = "Baseplate1",
    IdentifyAs = "acf_baseplate",
    Model = "models/hunter/plates/plate2x5.mdl",
    Scale = Vector(1, 1.25, 1),
    Position = Vector(0, 0, 0),
    ComeFrom = Vector(0, 0, 0)
}):DelayByLength()

Chapter:AddDelay(1)

Chapter:AddInstruction("RemovePanel", {Name = "MainMenuCPanel", Length = 1}):DelayByLength()

Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

Chapter:AddDelay(1)
local Chapter = Storyboard:Chapter("Orientation")
Chapter:AddDelay(1)

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "It should have automatically faced north when spawned.\nAlways build with them facing north."}))

Chapter:AddInstruction("Caption", {
    Text = "North",
    Horizontal = TEXT_ALIGN_RIGHT,
    Position = Vector(0, -100, 0),
    ParentTo = "Baseplate1",
    TextLength = 3,
    UseEntity = true,
})

Chapter:AddInstruction("Caption", {
    Text = "South",
    Horizontal = TEXT_ALIGN_RIGHT,
    Position = Vector(0, 100, 0),
    ParentTo = "Baseplate1",
    TextLength = 3,
    UseEntity = true,
})

Chapter:AddInstruction("Caption", {
    Text = "East",
    Horizontal = TEXT_ALIGN_RIGHT,
    Position = Vector(-100, 0, 0),
    ParentTo = "Baseplate1",
    TextLength = 3,
    UseEntity = true,
})

Chapter:AddInstruction("Caption", {
    Text = "West",
    Horizontal = TEXT_ALIGN_RIGHT,
    Position = Vector(100, 0, 0),
    ParentTo = "Baseplate1",
    TextLength = 3,
    UseEntity = true,
})

Chapter:AddInstruction("MoveCameraLookAt", {Length = 1,  Angle = 0, Height = 2000}):DelayByLength()
Chapter:AddDelay(2)
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1,  Angle = 55, Distance = 1300, Height = 600}):DelayByLength()

Chapter:AddDelay(1)
local Chapter = Storyboard:Chapter("Info")
Chapter:AddDelay(1)

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Baseplates are the core of any ACF contraption and are REQUIRED for your vehicles to work."}))

Chapter:AddDelay(1)
local Chapter = Storyboard:Chapter("Baseplate Seats")
Chapter:AddDelay(1)

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Baseplates contain seats which are invisible to damage and view.\nPress ALT + E to sit in them."}))

Chapter:AddDelay(1)
local Chapter = Storyboard:Chapter("Baseplate Seats (Wiremod)")
Chapter:AddDelay(1)

Chapter:AddInstruction("Caption", {Text = "(Optional) If you are familiar with Wiremod, you can link Pod/Cam/EGP controllers by right click linking them to the baseplate with the wire tool."})

-- Spawn in pod controller
Chapter:AddInstruction("PlaceModel", {
    Name = "Pod1",
    IdentifyAs = "Pod Controller",
    Model = "models/jaanus/wiretool/wiretool_range.mdl",
    Position = Vector(-80, 0, 0),
    ComeFrom = Vector(0, 0, 30)
})
Chapter:AddInstruction("ColorModel", {Target = "Pod1", Color = Color(255, 0, 0)})

-- Link pod to baseplate
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.wire_adv.name")}):DelayByLength()
Chapter:AddDelay(1)
Chapter:AddInstruction("MoveToolgunTo", {Target = "Pod1", Easing = math.ease.InOutQuad}):DelayByLength()
Chapter:AddInstruction("ClickToolgun", {Target = "Pod1"}):DelayByLength()
Chapter:AddInstruction("MoveToolgunTo", {Target = "Baseplate1", Easing = math.ease.InOutQuad}):DelayByLength()
Chapter:AddInstruction("ClickToolgun", {Target = "Baseplate1"}):DelayByLength()
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

Chapter:AddDelay(1)
Chapter:AddInstruction("RemoveModel", {Name = "Pod1"}):DelayByLength()

Chapter:AddDelay(1)
local Chapter = Storyboard:Chapter("Baseplate Collisions")
Chapter:AddDelay(1)

Chapter:AddInstruction("Caption", {Text = "Baseplates will collide with other baseplates."})

Chapter:AddInstruction("MoveCameraLookAt", {Length = 1,  Angle = 45, Distance = 3000}):DelayByLength()

-- Animate Collision
Chapter:AddInstruction("PlaceModel", {
    Name = "Baseplate2",
    IdentifyAs = "acf_baseplate",
    Model = "models/hunter/plates/plate2x5.mdl",
    Position = Vector(0, 300, 0),
    ComeFrom = Vector(0, 0, 32)
}):DelayByLength()

Chapter:AddInstruction("TransformModel", {
    Target = "Baseplate2",
    Position = Vector(0, 190, 0),
    Rotation = Angle(0, 0, 0),
    Length = 0.5,
}):DelayByLength()

Chapter:AddInstruction("TransformModel", {
    Target = "Baseplate2",
    Position = Vector(0, 286, 0),
    Rotation = Angle(0, 0, 0),
    Length = 0.75,
})

Chapter:AddInstruction("TransformModel", {
    Target = "Baseplate1",
    Position = Vector(0, -96, 0),
    Rotation = Angle(0, 0, 0),
    Length = 0.75,
}):DelayByLength()

Chapter:RecommendStoryboard("acf.tankbasics.drivetrain")

