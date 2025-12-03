local Storyboard = Ponder.API.NewStoryboard("acf", "tankbasics", "turrets")
Storyboard:WithName("Turrets")
Storyboard:WithBaseEntity(nil)
Storyboard:WithModelIcon("models/acf/core/t_trun.mdl")
Storyboard:WithDescription("Learn how to aim at things")
Storyboard:WithIndexOrder(96)

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

local Chapter = Storyboard:Chapter("Turret Menu")
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
Chapter:AddInstruction("ACF.SelectMenuTreeNode", {Name = "MainMenuCPanel", Select = "#acf.menu.turrets"}):DelayByLength()
Chapter:AddInstruction("ACF.ScrollToMenuPanel", {Name = "MainMenuCPanel", Scroll = "#acf.menu.turrets.components"}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "MainMenuCPanel", ComboBoxName = "TurretClass", OptionID = 1}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "MainMenuCPanel", ComboBoxName = "TurretComponentClass", OptionID = 1}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Ring diameters determine how large of a turret you can mount. For this example, set the ring diameter to 96."}))
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.turrets.ring_diameter", Value = 96}):DelayByLength()

local Chapter = Storyboard:Chapter("Horizontal Turret Spawn")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Spawn the horizontal turret ring and move it above the baseplate."}))
Chapter:AddInstruction("PlaceModel", {Name = "TurretH", IdentifyAs = "Turret Ring", Model = "models/acf/core/t_ring.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 36), ComeFrom = Vector(0, 0, 50), ParentTo = "Base"})

local Chapter = Storyboard:Chapter("Vertical Turret Spawn")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Now select a vertical turret ring with diameter 18 units."}))
Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "MainMenuCPanel", ComboBoxName = "TurretComponentClass", OptionID = 2}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.turrets.ring_diameter", Value = 18}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Spawn the vertical turret ring and move it towards the front of the turret ring and above."}))
Chapter:AddInstruction("PlaceModel", {Name = "TurretV", IdentifyAs = "Turret Trun", Model = "models/acf/core/t_trun.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, 48, 18), ComeFrom = Vector(0, 0, 50), ParentTo = "TurretH"})

local Chapter = Storyboard:Chapter("Alignment")
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1,  Angle = -180, Distance = 2000}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Make sure your vertical ring is aligned horizontally with the horizontal ring."}))
Chapter:AddInstruction("TransformModel", {Target = "TurretV", Position = Vector(12, 48, 18), Rotation = Angle(0, 90, 0), Length = 1}):DelayByLength()
Chapter:AddInstruction("TransformModel", {Target = "TurretV", Position = Vector(-12, 48, 18), Rotation = Angle(0, 90, 0), Length = 1}):DelayByLength()
Chapter:AddInstruction("TransformModel", {Target = "TurretV", Position = Vector(0, 48, 18), Rotation = Angle(0, 90, 0), Length = 1}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Here is how it looks from the sides."}))
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1,  Angle = 90, Height = 0}):DelayByLength()
Chapter:AddDelay(1)
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1,  Angle = 0, Height = 0}):DelayByLength()
Chapter:AddDelay(1)
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1,  Angle = -225, Distance = 2000}):DelayByLength()

local Chapter = Storyboard:Chapter("Arc Limits")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Try updating the vertical turret ring to have arc limits."}))
Chapter:AddInstruction("ACF.ScrollToMenuPanel", {Name = "MainMenuCPanel", Scroll = "#acf.menu.turrets.arc_settings"}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "For this example, use -10/+45 degrees."}))
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.turrets.min_degrees", Value = -10}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = "#acf.menu.turrets.max_degrees", Value = 45}):DelayByLength()
Chapter:AddDelay(1)
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Update the vertical turret ring by left clicking it with the new settings."}))
Chapter:AddInstruction("MoveToolgunTo", {Target = "TurretV", Easing = math.ease.InOutQuad}):DelayByLength()
Chapter:AddInstruction("ClickToolgun", {Target = "TurretV"}):DelayByLength()
Chapter:AddInstruction("MoveToolgunTo", {Easing = math.ease.InOutQuad}):DelayByLength()
Chapter:AddDelay(1)
Chapter:AddInstruction("RemovePanel", {Name = "MainMenuCPanel", Length = 1}):DelayByLength()
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

local Chapter = Storyboard:Chapter("Arc Limit Demonstration")
Chapter:AddInstruction("PlaceModel", {Name = "Gun", IdentifyAs = "125mm Cannon", Model = "models/tankgun_new/tankgun_100mm.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 0, 50), Scale = Vector(125 / 100, 125 / 100, 125 / 100), ParentTo = "TurretV", }):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Later on when we add a gun, this means it can point 10 degrees down and 45 degrees up at most."}))
Chapter:AddInstruction("TransformModel", {Target = "TurretV", Position = Vector(0, 48, 18), Rotation = Angle(-45, 90, 0), Length = 1}):DelayByLength()
Chapter:AddInstruction("TransformModel", {Target = "TurretV", Position = Vector(0, 48, 18), Rotation = Angle(10, 90, 0), Length = 1}):DelayByLength()
Chapter:AddInstruction("TransformModel", {Target = "TurretV", Position = Vector(0, 48, 18), Rotation = Angle(0, 90, 0), Length = 1}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "This stops your gun from clipping through your vehicle, which could cause issues like poor reloads."}))
Chapter:AddInstruction("RemoveModel", {Name = "Gun"}):DelayByLength()

local Chapter = Storyboard:Chapter("Parenting Turrets")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "But before we get there, parent vertical to horizontal, horizontal to baseplate."}))
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.multi_parent.listname")}):DelayByLength()
Chapter:AddDelay(1)
Chapter:AddDelay(Chapter:AddInstruction("Tools.MultiParent", {Children = {"TurretV"}, Parent = "TurretH", Easing = math.ease.InOutQuad, Length = 2}))
Chapter:AddDelay(Chapter:AddInstruction("Tools.MultiParent", {Children = {"TurretH"}, Parent = "Base", Easing = math.ease.InOutQuad, Length = 2}))
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()
Chapter:RecommendStoryboard("acf.tankbasics.weapons")