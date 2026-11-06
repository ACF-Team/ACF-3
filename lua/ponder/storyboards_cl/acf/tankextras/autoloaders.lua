local Storyboard = Ponder.API.NewStoryboard("acf", "tankextras", "autoloaders")
Storyboard:WithName("Autoloaders")
Storyboard:WithModelIcon("models/acf/autoloader_tractorbeam.mdl")
Storyboard:WithDescription("Learn how to load your gun without a loader")
Storyboard:WithIndexOrder(99.5)

-- Turret ring sits at world height 36, so the breech of the gun below is at world (0, -4, 54)
local BreechPos = Vector(0, -4, 54)

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Setup")
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1,  Angle = -135, Distance = 1600}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Length = 0.5,
    Models = {
        {Name = "Base", IdentifyAs = "Base", Model = "models/hunter/plates/plate2x5.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 0, 50), Scale = Vector(1, 1.25, 1), },
        {Name = "TurretH", IdentifyAs = "Turret Ring", Model = "models/acf/core/t_ring.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 36), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        {Name = "TurretV", IdentifyAs = "Turret Trun", Model = "models/acf/core/t_trun.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, 48, 18), ComeFrom = Vector(0, 0, 50), ParentTo = "TurretH", },
        {Name = "Gun", IdentifyAs = "125mm Cannon", Model = "models/tankgun_new/tankgun_100mm.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 0, 50), Scale = Vector(125 / 100, 125 / 100, 125 / 100), ParentTo = "TurretV", },
    }
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "An autoloader loads a gun by itself. Crew linked to the gun only take over if it is destroyed."}))

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Ammo")
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")}):DelayByLength()

Chapter:AddInstruction("PlacePanel", {
    Name = "MainMenuCPanel",
    Type = "DPanel",
    Calls = {
        {Method = "SetSize", Args = {300, 700}},
        {Method = "SetPos", Args = {1500, 0}},
        {Method = "CenterVertical", Args = {}},
    },
    Length = 0.25,
}):DelayByLength()

Chapter:AddInstruction("ACF.CreateMenuCPanel", {Name = "MainMenuCPanel", Label = "ACF Menu"}):DelayByLength()
Chapter:AddInstruction("ACF.InitializeMainMenu", {Name = "MainMenuCPanel"}):DelayByLength()
Chapter:AddInstruction("ACF.SelectMenuTreeNode", {Name = "MainMenuCPanel", Select = "#acf.menu.weapons"}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "MainMenuCPanel", Choice = "Cannon"}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.caliber", Value = 125}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Autoloaders only feed from a Carousel, Drum or Cassette, picked in the container settings."}))
Chapter:AddInstruction("ACF.ScrollToMenuPanel", {Name = "MainMenuCPanel", Scroll = "Container Settings"}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "MainMenuCPanel", Choice = "Carousel"}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Here we make a 125mm round, 90cm long, without case necking so its case is as wide as its caliber."}))
Chapter:AddInstruction("ACF.ScrollToMenuPanel", {Name = "MainMenuCPanel", Scroll = "#acf.menu.ammo.ammo_info"}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "MainMenuCPanel", Choice = "Armor Piercing"}):DelayByLength()
Chapter:AddInstruction("ACF.ScrollToMenuPanel", {Name = "MainMenuCPanel", Scroll = "#acf.menu.ammo.total_length"}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.ammo.total_length", Value = 90}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "Case Necking", Value = 0}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Making it two piece loads it in two halves, so the autoloader only needs to fit 45cm."}))
Chapter:AddInstruction("ACF.SetPanelCheckBox", {Name = "MainMenuCPanel", CheckBoxName = "Two Piece", Value = true}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Length = 0.5,
    Models = {
        {Name = "Carousel", IdentifyAs = "Ammo Carousel (125mmC AP)", Model = "models/acf/core/s_ammo_cyl.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, -27), ComeFrom = Vector(0, 0, 50), Scale = Vector(6, 6, 1), ParentTo = "TurretH", },
    }
}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Spawn the carousel under the turret. Its overlay lists the shell dimensions if you need them later."}))

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Mixing Rounds")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "A carousel can hold other rounds too. Pick another ammo type, then hold Alt and left click the carousel to add one."}))
Chapter:AddInstruction("ACF.ScrollToMenuPanel", {Name = "MainMenuCPanel", Scroll = "#acf.menu.ammo.ammo_info"}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "MainMenuCPanel", Choice = "High Explosive"}):DelayByLength()

Chapter:AddInstruction("MoveToolgunTo", {Target = "Carousel", Easing = math.ease.InOutQuad}):DelayByLength()
local Alt = Chapter:AddInstruction("KeyPress", {Name = "AltKey", Key = "Alt", Position = Vector(0.5, 0.8, 0), Hold = 0.8})
Chapter:AddDelay(Alt.PressedAt)
Chapter:AddInstruction("ClickToolgun", {Target = "Carousel"}):DelayByLength()
Chapter:AddDelay(0.8)
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("ACF.ShowRoundCounts", {Target = "Carousel", Capacity = 60, Kinds = {{Name = "HE", Count = 1}}}))
Chapter:AddInstruction("Caption", {Text = "Drag the divider to set how many it holds of each. The rest are the carousel's own round."})
Chapter:AddInstruction("ACF.DragRoundDivider", {Name = "RoundCounts", Count = 20}):DelayByLength()
Chapter:AddDelay(1.5)
Chapter:AddInstruction("ACF.ClickRoundCountsApply", {Name = "RoundCounts"}):DelayByLength()
Chapter:AddInstruction("RemovePanel", {Name = "RoundCounts", Length = 0.5}):DelayByLength()
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")}):DelayByLength()

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Fitting the Autoloader")
Chapter:AddInstruction("ACF.SelectMenuTreeNode", {Name = "MainMenuCPanel", Select = "#acf.menu.components"}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "MainMenuCPanel", Choice = "Autoloader"}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Under Components, pick Autoloader and size it to the round. Bigger autoloaders weigh more, so don't oversize it."}))
Chapter:AddInstruction("ACF.ScrollToMenuPanel", {Name = "MainMenuCPanel", Scroll = "Max Caliber (mm)"}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "Max Caliber (mm)", Value = 125}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "Length (cm)", Value = 45}):DelayByLength()

Chapter:AddInstruction("MoveCameraLookAt", {Length = 1,  Angle = -90, Distance = 1200}):DelayByLength()
Chapter:AddInstruction("DebugLine", {Name = "BreechLine", Start = BreechPos, End = BreechPos - Vector(0, 64, 0), Color = Color(100, 255, 100, 255), IgnoreZ = true}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Length = 0.5,
    Models = {
        {Name = "Autoloader", IdentifyAs = "Autoloader", Model = "models/acf/autoloader_tractorbeam.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, -28, 18), ComeFrom = Vector(0, 0, 50), Scale = Vector(0.41, 0.68, 0.68), ParentTo = "TurretH", },
    }
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Place it on the line behind the breech, facing the way the gun fires, within 10 degrees."}))
Chapter:AddInstruction("RemoveDebugOverlay", {Name = "BreechLine"})
Chapter:AddInstruction("RemovePanel", {Name = "MainMenuCPanel", Length = 0.5}):DelayByLength()
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1,  Angle = -135, Distance = 1600}):DelayByLength()

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Parenting and Linking")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Give the autoloader the same parent as its ammo."}))
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.multi_parent.listname")}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Tools.MultiParent", {Children = {"Autoloader", "Carousel"}, Parent = "TurretH", Easing = math.ease.InOutQuad, Length = 2}))
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Link the carousel to the gun, then the autoloader to the gun and the carousel."}))
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {Children = {"Carousel"}, Target = "Gun", Easing = math.ease.InOutQuad, Length = 2}))
Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {Children = {"Autoloader"}, Target = "Gun", Easing = math.ease.InOutQuad, Length = 2}))
Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {Children = {"Autoloader"}, Target = "Carousel", Easing = math.ease.InOutQuad, Length = 2}))
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Reloading")
Chapter:AddInstruction("PlaceModel", {
    Name = "Blocker",
    IdentifyAs = "Armor Plate",
    Model = "models/hunter/plates/plate025x025.mdl",
    Angles = Angle(90, 90, 0),
    Position = Vector(0, -12, 18),
    Scale = Vector(1.5, 1.5, 1),
    ComeFrom = Vector(0, 0, 50),
    ParentTo = "TurretH",
}):DelayByLength()
Chapter:AddInstruction("MaterialModel", {Target = "Blocker", Material = "models/debug/debugwhite"})
Chapter:AddInstruction("ColorModel", {Target = "Blocker", Color = Color(255, 0, 0, 200)})

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "It needs a clear path to the breech and to its ammo. Anything in the way stops it loading."}))
Chapter:AddInstruction("RemoveModel", {Name = "Blocker"}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Keep the ammo, autoloader and breech close, height costing most, with shells facing the way it rams them.\nIts overlay shows the estimated reload time."}))

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Elevation")
Chapter:AddInstruction("ShowText", {Name = "State", Text = "Loading", ParentTo = "Autoloader"})
Chapter:AddInstruction("TransformModel", {Target = "TurretV", Rotation = Angle(-20, 90, 0), Length = 2}):DelayByLength()
Chapter:AddInstruction("ChangeText", {Name = "State", Text = "Waiting"})
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "It only loads while lined up with the breech, so an elevated gun waits until it comes back."}))

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("AIO Controller")
Chapter:AddInstruction("PlaceModel", {Name = "AIO", IdentifyAs = "AIO Controller", Model = "models/hunter/plates/plate025x025.mdl", Position = Vector(-30, 100, 3), ComeFrom = Vector(0, 0, 50), ParentTo = "Base"}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "An AIO controller linked to the gun and both turret rings can level it for you."}))
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {Children = {"Gun", "TurretH", "TurretV"}, Target = "AIO", Easing = math.ease.InOutQuad, Length = 3}))
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("ACF.ShowAIOMenu", {Target = "AIO"}))
Chapter:AddInstruction("Caption", {Text = "Set ReloadAngle to 0.01 to level the gun automatically while loading."})
Chapter:AddInstruction("ACF.SetAIOSetting", {Name = "AIOMenu", Setting = "ReloadAngle", Value = 0.01}):DelayByLength()
Chapter:AddDelay(1.5)
Chapter:AddInstruction("TransformModel", {Target = "TurretV", Rotation = Angle(0, 90, 0), Length = 2}):DelayByLength()
Chapter:AddInstruction("ChangeText", {Name = "State", Text = "Loading"})
Chapter:AddDelay(4)
Chapter:AddInstruction("RemovePanel", {Name = "AIOMenu", Length = 0.5}):DelayByLength()
Chapter:AddInstruction("HideText", {Name = "State"})
