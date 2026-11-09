local Storyboard = Ponder.API.NewStoryboard("acf", "carbasics", "car_drivetrain")
Storyboard:WithName("Car Drivetrain")
Storyboard:WithBaseEntity(nil)
Storyboard:WithModelIcon("models/engines/linear_s.mdl")
Storyboard:WithDescription("Learn how to power every wheel of a car.")
Storyboard:WithIndexOrder(100)

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Disclaimer")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "These tutorials assume you've finished Tank Basics. Spawning, parenting and linking work the same way, so they're shown quickly here."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "A car differs from a tank in two ways: every wheel is powered through transfer cases, and the front wheels steer."}))

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Setup")
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1, Angle = -225, Distance = 1400}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Length = 0.5,
    Models = {
        {Name = "Base", IdentifyAs = "Base", Model = "models/hunter/plates/plate2x4.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 0, 50)},
        {Name = "AIO", IdentifyAs = "AIO Controller", Model = "models/hunter/plates/plate025x025.mdl", Position = Vector(-30, 30, 3), ComeFrom = Vector(0, 0, 50), ParentTo = "Base"},
        {Name = "Engine", IdentifyAs = "Engine", Model = "models/engines/v8s.mdl", Angles = Angle(0, -90, 0), Position = Vector(0, -36, 3), ComeFrom = Vector(0, 0, 50), ParentTo = "Base"},
        {Name = "FuelTank", IdentifyAs = "Fuel Tank", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, 90, 0), Position = Vector(30, 20, 12), ComeFrom = Vector(0, 0, 50), Scale = Vector(3, 1.5, 1.5), Material = "models/props_canal/metalcrate001d", ParentTo = "Base"},
    }
}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Start like a tank: a baseplate facing north with a linked controller, an engine and a fuel tank."}))

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Main Gearbox")
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")}):DelayByLength()
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
Chapter:AddInstruction("ACF.SelectMenuTreeNode", {Name = "MainMenuCPanel", Select = "#acf.menu.gearboxes"}):DelayByLength()
Chapter:AddInstruction("ACF.ScrollToMenuPanel", {Name = "MainMenuCPanel", Scroll = "#acf.menu.gearboxes.gearbox_info"}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "MainMenuCPanel", Choice = "Automatic"}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "MainMenuCPanel", Choice = "Automatic, Inline"}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "The main gearbox is an Automatic, Inline. It shifts by itself, so the controller only has to pick drive or reverse."}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Press Mouse1 (Left Click) to spawn it."}))
Chapter:AddInstruction("PlaceModel", {Name = "MainGearbox", IdentifyAs = "Main Gearbox", Model = "models/engines/linear_s.mdl", Position = Vector(96, 0, 0), Angles = Angle(0, 0, 0)}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Place it in front of the engine. Its input is on top, and it sends power out of both ends, one to each axle."}))
Chapter:AddInstruction("TransformModel", {Target = "MainGearbox", Position = Vector(0, 0, 3), Rotation = Angle(0, 0, 0), Length = 1}):DelayByLength()

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Transfer Cases")
Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "MainMenuCPanel", Choice = "Transfer Case"}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Each axle gets a Transfer Case, which splits power to its left and right wheels."}))
Chapter:AddInstruction("ACF.ScrollToMenuPanel", {Name = "MainMenuCPanel", Scroll = "#acf.menu.gearboxes.final_drive"}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = string.format(language.GetPhrase("#acf.menu.gearboxes.gear_number"), 1), Value = 1}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "MainMenuCPanel", SliderName = string.format(language.GetPhrase("#acf.menu.gearboxes.gear_number"), 2), Value = -1}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "The controller puts them in gear 1 to drive and gear 2 to reverse, so give gear 2 a negative ratio."}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Spawn two, and place one on each axle with its input shaft pointing towards the main gearbox."}))
Chapter:AddInstruction("PlaceModel", {Name = "FrontTransfer", IdentifyAs = "Transfer Case (Front)", Model = "models/engines/transaxial_s.mdl", Position = Vector(96, 0, 0), Angles = Angle(0, 0, 0)}):DelayByLength()
Chapter:AddInstruction("PlaceModel", {Name = "RearTransfer", IdentifyAs = "Transfer Case (Rear)", Model = "models/engines/transaxial_s.mdl", Position = Vector(96, 40, 0), Angles = Angle(0, 0, 0)}):DelayByLength()
Chapter:AddInstruction("TransformModel", {Target = "FrontTransfer", Position = Vector(0, 72, 3), Rotation = Angle(0, -90, 0), Length = 1}):DelayByLength()
Chapter:AddInstruction("TransformModel", {Target = "RearTransfer", Position = Vector(0, -72, 3), Rotation = Angle(0, 90, 0), Length = 1}):DelayByLength()
Chapter:AddDelay(1)
Chapter:AddInstruction("RemovePanel", {Name = "MainMenuCPanel", Length = 0.5}):DelayByLength()
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Wheels")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Spawn four wheels from the spawn menu, parallel to the baseplate, one at each end of both axles."}))
Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Length = 2,
    Models = {
        {Name = "FLWheel", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(72, 72, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base"},
        {Name = "FRWheel", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(-72, 72, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base"},
        {Name = "RLWheel", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(72, -72, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base"},
        {Name = "RRWheel", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(-72, -72, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base"},
    }
}))

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Parenting")
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.multi_parent.listname")}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Parent the gearboxes to the baseplate. Leave the wheels unparented, the suspension tool attaches them later."}))
Chapter:AddDelay(Chapter:AddInstruction("Tools.MultiParent", {Children = {"MainGearbox", "FrontTransfer", "RearTransfer"}, Parent = "Base", Easing = math.ease.InOutQuad, Length = 3}))
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Linking")
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Link the fuel tank to the engine, and the engine to the main gearbox."}))
Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {Children = {"FuelTank"}, Target = "Engine", Easing = math.ease.InOutQuad, Length = 2}))
Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {Children = {"Engine"}, Target = "MainGearbox", Easing = math.ease.InOutQuad, Length = 2}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Power flows from the entity you select first. Right click the main gearbox, then a transfer case, and repeat for the other one."}))
Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {Children = {"MainGearbox"}, Target = "FrontTransfer", Easing = math.ease.InOutQuad, Length = 2}))
Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {Children = {"MainGearbox"}, Target = "RearTransfer", Easing = math.ease.InOutQuad, Length = 2}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Link each pair of wheels to the transfer case on its axle."}))
Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {Children = {"FLWheel", "FRWheel"}, Target = "FrontTransfer", Easing = math.ease.InOutQuad, Length = 2}))
Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {Children = {"RLWheel", "RRWheel"}, Target = "RearTransfer", Easing = math.ease.InOutQuad, Length = 2}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Now every wheel receives power from the engine."}))

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("AIO Controller")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Link the main gearbox to your controller. Never link the transfer cases, the controller finds them through the main gearbox."}))
Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {Children = {"MainGearbox"}, Target = "AIO", Easing = math.ease.InOutQuad, Length = 2}))
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Next, make the front wheels steer."}))
Chapter:RecommendStoryboard("acf.carbasics.car_steering")
