local Storyboard = Ponder.API.NewStoryboard("acf", "tankextras", "servos_actuators")
Storyboard:WithName("Servos & Linear Actuators")
Storyboard:WithModelIcon("models/holograms/cylinder.mdl")
Storyboard:WithDescription("Learn about servo and linear actuator turret drives.")
Storyboard:WithIndexOrder(1)

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Servo Menu")
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")}):DelayByLength()

Chapter:AddInstruction("PlacePanel", {
    Name = "ServoMenuCPanel",
    Type = "DPanel",
    Calls = {
        {Method = "SetSize", Args = {300, 700}},
        {Method = "SetPos", Args = {1500, 0}},
        {Method = "CenterVertical", Args = {}},
    },
    Length = 0.25,
}):DelayByLength()

Chapter:AddInstruction("ACF.CreateMenuCPanel", {Name = "ServoMenuCPanel", Label = "ACF Menu"}):DelayByLength()
-- Builds the servo's real menu, the same one the toolgun opens for it in game.
Chapter:AddInstruction("ACF.InitializeCustomMenu", {Name = "ServoMenuCPanel", BuildCPanel = function(Panel)
    local Menu = ACF.InitMenuBase(Panel)
    local Data = ACF.Classes.GetTypeByName("ACF.Turrets.Servo.Standard")
    ACF.CreateTurretServoMenu(Data, Menu, {Set = function() end})
    return Menu
end}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "This is the servo's menu. Set the On Angle: the degrees it swings to when its State input goes non zero."}))
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "ServoMenuCPanel", SliderName = "#acf.menu.turrets.on_angle", Value = 30}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Left click to place it, or left click an existing servo to update it with these settings."}))
Chapter:AddInstruction("RemovePanel", {Name = "ServoMenuCPanel", Length = 1}):DelayByLength()
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Servos")
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1, Angle = -225, Distance = 1600}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Length = 0.5,
    Models = {
        {Name = "Base1", IdentifyAs = "Base", Model = "models/hunter/plates/plate2x5.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 0, 50), Scale = Vector(1, 1.25, 1), },
        {Name = "HDrive", IdentifyAs = "Horizontal Drive", Model = "models/acf/core/t_drive_e.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 10), ComeFrom = Vector(0, 0, 50), ParentTo = "Base1", },
        {Name = "Servo", IdentifyAs = "Servo", Model = "models/holograms/cylinder.mdl", Angles = Angle(0, 0, 90), Position = Vector(0, 40, 10), ComeFrom = Vector(0, 0, 50), Scale = Vector(0.5, 0.5, 0.5), ParentTo = "HDrive", },
        {Name = "Rack", IdentifyAs = "Missile Rack", Model = "models/missiles/rkx1.mdl", Angles = Angle(0, 0, -90), Position = Vector(40, 0, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Servo", },
    }
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "A servo swings between two angles from a single signal. It's self powered, so it doesn't need a motor or gyro."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Parent a servo to a horizontal drive (or another servo), then parent your rack or weapon to the servo."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "A servo always swings around the axis it was mounted on. Lay it on its side, like here, and that swing becomes elevation instead of traverse."}))

Chapter:AddInstruction("TransformModel", {Target = "Servo", Rotation = Angle(-30, 0, 90), Length = 1}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Wire its State input: non zero moves it to the On Angle you set in the menu, zero returns it to Off (0 degrees)."}))
Chapter:AddInstruction("TransformModel", {Target = "Servo", Rotation = Angle(0, 0, 90), Length = 1}):DelayByLength()

Chapter:AddInstruction("RemoveModel", {Name = "Base1"}):DelayByLength()
Chapter:AddInstruction("RemoveModel", {Name = "HDrive"}):DelayByLength()
Chapter:AddInstruction("RemoveModel", {Name = "Servo"}):DelayByLength()
Chapter:AddInstruction("RemoveModel", {Name = "Rack"}):DelayByLength()

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Actuator Menu")
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")}):DelayByLength()

Chapter:AddInstruction("PlacePanel", {
    Name = "ActuatorMenuCPanel",
    Type = "DPanel",
    Calls = {
        {Method = "SetSize", Args = {300, 700}},
        {Method = "SetPos", Args = {1500, 0}},
        {Method = "CenterVertical", Args = {}},
    },
    Length = 0.25,
}):DelayByLength()

Chapter:AddInstruction("ACF.CreateMenuCPanel", {Name = "ActuatorMenuCPanel", Label = "ACF Menu"}):DelayByLength()
-- Builds the actuator's real menu, the same one the toolgun opens for it in game.
Chapter:AddInstruction("ACF.InitializeCustomMenu", {Name = "ActuatorMenuCPanel", BuildCPanel = function(Panel)
    local Menu = ACF.InitMenuBase(Panel)
    local Data = ACF.Classes.GetTypeByName("ACF.Turrets.Actuator.Hydraulic")
    ACF.CreateTurretActuatorMenu(Data, Menu, {Set = function() end})
    return Menu
end}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "This is the actuator's menu. Bore sets its thickness and strength, Stroke sets how far it can extend."}))
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "ActuatorMenuCPanel", SliderName = "#acf.menu.turrets.actuator_bore", Value = 4}):DelayByLength()
Chapter:AddInstruction("ACF.SetPanelSlider", {Name = "ActuatorMenuCPanel", SliderName = "#acf.menu.turrets.actuator_stroke", Value = 40}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Left click to place it, or left click an existing actuator to update it with these settings."}))
Chapter:AddInstruction("RemovePanel", {Name = "ActuatorMenuCPanel", Length = 1}):DelayByLength()
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Linear Actuators")
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1, Angle = -225, Distance = 1600}):DelayByLength()

-- The body stays fixed; the rod is its own part that telescopes out of it, same as the real entity.
Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Length = 0.5,
    Models = {
        {Name = "Base2", IdentifyAs = "Base", Model = "models/hunter/plates/plate2x5.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 0, 50), Scale = Vector(1, 1.25, 1), },
        {Name = "ActuatorBody", IdentifyAs = "Linear Actuator", Model = "models/holograms/cylinder.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 15), ComeFrom = Vector(0, 0, 50), Scale = Vector(0.7, 0.7, 2.5), ParentTo = "Base2", },
        {Name = "ActuatorRod", IdentifyAs = "Actuator Rod", Model = "models/holograms/cylinder.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 3), ComeFrom = Vector(0, 0, 50), Scale = Vector(0.35, 0.35, 3), ParentTo = "ActuatorBody", },
        {Name = "Rack", IdentifyAs = "Missile Rack", Model = "models/missiles/rkx1.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 12), ComeFrom = Vector(0, 0, 50), ParentTo = "ActuatorRod", },
    }
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "A linear actuator extends along its Up axis instead of rotating. It's self powered, so it doesn't need a motor or gyro."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "In game it's a single entity, but the rod that extends is its own part riding inside the body, like here."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Parent it to a horizontal drive (or a servo/actuator), then parent your rack, weapon or hatch to it. It also works well as a powered door."}))

Chapter:AddInstruction("TransformModel", {Target = "ActuatorRod", Position = Vector(0, 0, 25), Length = 1}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Here, extending it raises the rack up out of the hull, like a pop up ATGM launcher."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Wire its Extend input from 0 to 1 to set the extension fraction. Its outputs report that fraction (Extension) and the extension in inches (Length)."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Overloading it or using a long, thin rod can make it buckle, letting it retract but not extend further."}))
Chapter:AddInstruction("TransformModel", {Target = "ActuatorRod", Position = Vector(0, 0, 3), Length = 1}):DelayByLength()
