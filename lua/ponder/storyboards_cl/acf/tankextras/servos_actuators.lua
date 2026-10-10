local Storyboard = Ponder.API.NewStoryboard("acf", "tankextras", "servos_actuators")
Storyboard:WithName("Servos & Linear Actuators")
Storyboard:WithModelIcon("models/holograms/cylinder.mdl")
Storyboard:WithDescription("Learn about servo and linear actuator turret drives.")
Storyboard:WithIndexOrder(1)

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Servos")
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1, Angle = -225, Distance = 1600}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Length = 0.5,
    Models = {
        {Name = "Base1", IdentifyAs = "Base", Model = "models/hunter/plates/plate2x5.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 0, 50), Scale = Vector(1, 1.25, 1), },
        {Name = "HDrive", IdentifyAs = "Horizontal Drive", Model = "models/acf/core/t_drive_e.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 10), ComeFrom = Vector(0, 0, 50), ParentTo = "Base1", },
        {Name = "Servo", IdentifyAs = "Servo", Model = "models/holograms/cylinder.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 40, 10), ComeFrom = Vector(0, 0, 50), Scale = Vector(0.5, 0.5, 0.5), ParentTo = "HDrive", },
        {Name = "Rack", IdentifyAs = "Missile Rack", Model = "models/missiles/rkx1.mdl", Angles = Angle(0, 0, 0), Position = Vector(40, 0, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Servo", },
    }
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "A servo swings between two angles from a single signal. It's self powered, so it doesn't need a motor or gyro."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Parent a servo to a horizontal drive (or another servo), then parent your rack or weapon to the servo."}))

Chapter:AddInstruction("TransformModel", {Target = "Servo", Rotation = Angle(-30, 0, 0), Length = 1}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Wire its State input: non zero moves it to the On Angle you set in the menu, zero returns it to Off (0 degrees)."}))
Chapter:AddInstruction("TransformModel", {Target = "Servo", Rotation = Angle(0, 0, 0), Length = 1}):DelayByLength()

Chapter:AddInstruction("RemoveModel", {Name = "Base1"}):DelayByLength()
Chapter:AddInstruction("RemoveModel", {Name = "HDrive"}):DelayByLength()
Chapter:AddInstruction("RemoveModel", {Name = "Servo"}):DelayByLength()
Chapter:AddInstruction("RemoveModel", {Name = "Rack"}):DelayByLength()

local Chapter = Storyboard:Chapter("Linear Actuators")
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1, Angle = -225, Distance = 1600}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Length = 0.5,
    Models = {
        {Name = "Base2", IdentifyAs = "Base", Model = "models/hunter/plates/plate2x5.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 0, 50), Scale = Vector(1, 1.25, 1), },
        {Name = "Actuator", IdentifyAs = "Linear Actuator", Model = "models/holograms/cylinder.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 10), ComeFrom = Vector(0, 0, 50), Scale = Vector(0.5, 0.5, 0.5), ParentTo = "Base2", },
        {Name = "Rack", IdentifyAs = "Missile Rack", Model = "models/missiles/rkx1.mdl", Angles = Angle(-90, 90, 0), Position = Vector(0, 0, 20), ComeFrom = Vector(0, 0, 50), ParentTo = "Actuator", },
    }
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "A linear actuator extends along its Up axis instead of rotating. It's self powered, so it doesn't need a motor or gyro."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Parent it to a horizontal drive (or a servo/actuator), then parent your rack, weapon or hatch to it. It also works well as a powered door."}))

Chapter:AddInstruction("TransformModel", {Target = "Rack", Position = Vector(0, 0, 60), Length = 1}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Here, extending it raises the rack up out of the hull, like a pop up ATGM launcher."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Wire its Extend input from 0 to 1 to set the extension fraction. Its outputs report that fraction (Extension) and the extension in inches (Length)."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Overloading it or using a long, thin rod can make it buckle, letting it retract but not extend further."}))
Chapter:AddInstruction("TransformModel", {Target = "Rack", Position = Vector(0, 0, 20), Length = 1}):DelayByLength()
