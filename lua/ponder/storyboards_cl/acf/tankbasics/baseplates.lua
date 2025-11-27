local Storyboard = Ponder.API.NewStoryboard("acf", "tankbasics", "baseplates")
Storyboard:WithName("Baseplates")
Storyboard:WithBaseEntity(nil)
Storyboard:WithModelIcon("models/hunter/plates/plate1x2.mdl")
Storyboard:WithDescription("Learn the basics of baseplates.")
Storyboard:WithIndexOrder(100)

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Spawning")

Chapter:AddInstruction("Caption", {
    Text = "Start by selecting the acf menu tool, then in the menu, select baseplates.",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(0.5, 0.15, 0),
    Length = 3,
})

Chapter:AddInstruction("ShowToolgun", {
    Tool = language.GetPhrase("tool.acf_menu.menu_name")
}):DelayByLength()

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

Chapter:AddDelay(2)

Chapter:AddInstruction("Caption", {
    Text = "Scroll down and set the Length and Width to your desired size (recommended 192x96 for starters).",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(0.5, 0.15, 0),
    Length = 3,
})

Chapter:AddInstruction("ACF.ScrollToMenuPanel", {Name = "MainMenuCPanel", Scroll = "#acf.menu.baseplates.plate_thickness"}):DelayByLength()

Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.baseplates.plate_length", Value = 192}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.baseplates.plate_width", Value = 96}):DelayByLength()

Chapter:AddDelay(2)

Chapter:AddInstruction("Caption", {
    Text = "Press Mouse1 (Left Click) to spawn a baseplate where you're aiming.",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(0.5, 0.15, 0),
    Length = 5,
})

Chapter:AddInstruction("ClickToolgun", {}):DelayByLength()

Chapter:AddInstruction("PlaceModel", {
    Name = "Baseplate1",
    IdentifyAs = "acf_baseplate",
    Model = "models/hunter/plates/plate1x2.mdl",
    Position = Vector(0, 0, 0),
    ComeFrom = Vector(0, 0, 0)
}):DelayByLength()

Chapter:AddDelay(2)

Chapter:AddInstruction("RemovePanel", {Name = "MainMenuCPanel", Length = 1}):DelayByLength()

Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

Chapter:AddDelay(2)

Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "Baseplates are the core of any ACF contraption and are required for your vehicles to work.",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(0.5, 0.15, 0),
}))

Chapter:AddInstruction("Caption", {
    Text = "They should automatically face north when spawned.\nMake sure to keep it this way.",
    Horizontal = TEXT_ALIGN_CENTER,
    Position = Vector(0.5, 0.15, 0),
})

Chapter:AddInstruction("RemoveModel", {Name = "Baseplate1"}):DelayByLength()