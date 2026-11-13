local Storyboard = Ponder.API.NewStoryboard("acf", "carbasics", "car_steering")
Storyboard:WithName("Car Steering")
Storyboard:WithBaseEntity(nil)
Storyboard:WithModelIcon("models/xeon133/offroad/off-road-40.mdl")
Storyboard:WithDescription("Learn how to steer a car with steer plates.")
Storyboard:WithIndexOrder(99)

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
        {Name = "MainGearbox", IdentifyAs = "Main Gearbox", Model = "models/engines/linear_s.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 3), ComeFrom = Vector(0, 0, 50), ParentTo = "Base"},
        {Name = "FrontTransfer", IdentifyAs = "Transfer Case (Front)", Model = "models/engines/transaxial_s.mdl", Angles = Angle(0, -90, 0), Position = Vector(0, 72, 3), ComeFrom = Vector(0, 0, 50), ParentTo = "Base"},
        {Name = "RearTransfer", IdentifyAs = "Transfer Case (Rear)", Model = "models/engines/transaxial_s.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, -72, 3), ComeFrom = Vector(0, 0, 50), ParentTo = "Base"},
        {Name = "FLWheel", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(72, 72, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base"},
        {Name = "FRWheel", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(-72, 72, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base"},
        {Name = "RLWheel", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(72, -72, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base"},
        {Name = "RRWheel", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(-72, -72, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base"},
    }
}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "This continues from the Car Drivetrain tutorial, with every wheel powered and the main gearbox linked to your controller."}))

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Steer Plates")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Cars steer with steer plates. The front wheels are attached to one, and the controller turns it as you steer."}))
Chapter:AddInstruction("PlaceModel", {Name = "SteerPlate", IdentifyAs = "Steer Plate", Model = "models/hunter/plates/plate05x05.mdl", Position = Vector(-120, -130, 0), ComeFrom = Vector(0, 0, 50)}):DelayByLength()
Chapter:AddInstruction("ColorModel", {Target = "SteerPlate", Color = Color(100, 220, 255)})
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Spawn a small plate for each steered axle, facing north like the baseplate. It doesn't need to be on the vehicle, so most builders keep it off to the side, unparented."}))

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Suspension Tool")
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
Chapter:AddInstruction("ACF.SetPanelComboBox", {Name = "SuspensionMenuCPanel", Choice = "Spring Type: Rigid (None)"}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Shift + right click the baseplate, then right click the wheels that don't steer."}))
Chapter:AddDelay(Chapter:AddInstruction("FlashModel", {Reps = 2, Models = {"Base"}}))
Chapter:AddDelay(Chapter:AddInstruction("FlashModel", {Reps = 2, Models = {"RLWheel", "RRWheel"}}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Shift + right click the steer plate, then right click the wheels that steer with it."}))
Chapter:AddDelay(Chapter:AddInstruction("FlashModel", {Reps = 2, Models = {"SteerPlate"}}))
Chapter:AddInstruction("ColorModel", {Target = "SteerPlate", Color = Color(100, 220, 255)})
Chapter:AddDelay(Chapter:AddInstruction("FlashModel", {Reps = 2, Models = {"FLWheel", "FRWheel"}}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Press the create button once to create the suspension."}))
Chapter:AddInstruction("RemovePanel", {Name = "SuspensionMenuCPanel", Length = 0.5}):DelayByLength()
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Linking")
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Link the steer plate to your controller. It turns off the plate's gravity and holds its angle for you."}))
Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {Children = {"SteerPlate"}, Target = "AIO", Easing = math.ease.InOutQuad, Length = 2}))
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Steering Settings")
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "The controller won't steer until a few settings are filled in."}))
Chapter:AddDelay(Chapter:AddInstruction("ACF.ShowAIOMenu", {Target = "AIO"}))
Chapter:AddInstruction("ACF.SetAIOSetting", {Name = "AIOMenu", Setting = "SteerPercent1", Value = 1}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "SteerPercent1 is how much the front steer plate turns. Later plates use SteerPercent2 to 4, and a negative value turns the other way."}))
Chapter:AddInstruction("ACF.SetAIOSetting", {Name = "AIOMenu", Setting = "SteerRate", Value = 2}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "SteerRate is how fast the wheels turn towards their angle. At 0 they never move."}))
Chapter:AddInstruction("ACF.SetAIOSetting", {Name = "AIOMenu", Setting = "SteerLow", Value = 30}):DelayByLength()
Chapter:AddInstruction("ACF.SetAIOSetting", {Name = "AIOMenu", Setting = "SteerTop", Value = 10}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "SteerLow and SteerTop are the steering angles at SpeedLow and SpeedTop. Left at 0, BrakeStrength is used as the angle instead."}))
Chapter:AddInstruction("RemovePanel", {Name = "AIOMenu", Length = 0.5}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Sit in the baseplate and drive with W, A, S and D."}))
