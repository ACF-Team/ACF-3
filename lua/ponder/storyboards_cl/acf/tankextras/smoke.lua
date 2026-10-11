local Storyboard = Ponder.API.NewStoryboard("acf", "tankextras", "smoke")
Storyboard:WithName("Smoke")
Storyboard:WithModelIcon("models/bluemetaknight/laser_detector.mdl")
Storyboard:WithDescription("Learn how smoke clouds block optics, lasers and IRST.")
Storyboard:WithIndexOrder(5)

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Laser Warning Receiver")
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1, Angle = -225, Distance = 1800}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Length = 0.5,
    Models = {
        {Name = "Receiver", IdentifyAs = "Laser Warning Receiver", Model = "models/bluemetaknight/laser_detector.mdl", Angles = Angle(0, -90, 0), Position = Vector(0, 200, 15), ComeFrom = Vector(0, 0, 50), },
    }
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "A Laser Warning Receiver watches for laser light crossing its trace to the source, then warns you when one does."}))

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Triggering the Receiver")

Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Length = 0.5,
    Models = {
        {Name = "LaserComputer", IdentifyAs = "Laser Guidance Computer", Model = "models/props_lab/monitor01b.mdl", Angles = Angle(0, 90, 0), Position = Vector(-40, -200, 15), ComeFrom = Vector(0, 0, 50), },
        {Name = "OpticalComputer", IdentifyAs = "Optical Guidance Computer", Model = "models/props_lab/monitor01b.mdl", Angles = Angle(0, 90, 0), Position = Vector(40, -200, 15), ComeFrom = Vector(0, 0, 50), },
    }
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "A Laser Guidance Computer actively lases its target. That laser light is exactly what a Warning Receiver listens for."}))
Chapter:AddInstruction("DebugLine", {Name = "LaserTrace", Start = Vector(-40, -200, 15), End = Vector(0, 200, 15), Color = Color(255, 170, 60, 255)}):DelayByLength()
Chapter:AddInstruction("AddHalo", {Target = "Receiver", Color = Color(255, 220, 100, 255)})
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "The receiver reacts and warns you."}))
Chapter:AddInstruction("RemoveHalo", {Target = "Receiver"})
Chapter:AddInstruction("RemoveDebugOverlay", {Name = "LaserTrace"})

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "An Optical Guidance Computer tracks its target visually instead. No laser involved, so it never trips a Laser Warning Receiver."}))
Chapter:AddInstruction("DebugLine", {Name = "OpticalTrace", Start = Vector(40, -200, 15), End = Vector(0, 200, 15), Color = Color(150, 150, 150, 255)}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "No warning. The receiver only reacts to laser light, not any other way of tracking a target."}))
Chapter:AddInstruction("RemoveDebugOverlay", {Name = "OpticalTrace"})

Chapter:AddInstruction("RemoveModel", {Name = "OpticalComputer"}):DelayByLength()

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Smoke Blocks the Warning Receiver")

Chapter:AddInstruction("RemoveModel", {Name = "LaserComputer"}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Length = 0.5,
    Models = {
        {Name = "LaserComputer", IdentifyAs = "Laser Guidance Computer", Model = "models/props_lab/monitor01b.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, -200, 15), ComeFrom = Vector(0, 0, 50), },
    }
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "A smoke cloud is a volume of particles, created when Smoke ammunition detonates. It isn't an entity, just an area that blocks certain traces."}))

Chapter:AddInstruction("DebugLine", {Name = "Trace", Start = Vector(0, -200, 15), End = Vector(0, 200, 15), Color = Color(100, 255, 100, 255)}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "With nothing in the way, the laser's trace reaches the receiver and triggers it."}))
Chapter:AddInstruction("RemoveDebugOverlay", {Name = "Trace"})

Chapter:AddInstruction("DebugSphere", {Name = "Cloud", Position = Vector(0, 0, 20), Radius = 55, Color = Color(200, 200, 200, 120)}):DelayByLength()
Chapter:AddInstruction("DebugLine", {Name = "Trace", Start = Vector(0, -200, 15), End = Vector(0, -55, 17), Color = Color(255, 170, 60, 255)}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "A smoke cloud between them clips that trace short, stopping it at the near edge of the cloud instead."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Even with an active lock, the laser never reaches the receiver, so smoke keeps you from being warned."}))
Chapter:AddInstruction("RemoveDebugOverlay", {Name = "Trace"})

Chapter:AddInstruction("RemoveModel", {Name = "LaserComputer"}):DelayByLength()
Chapter:AddInstruction("RemoveModel", {Name = "Receiver"}):DelayByLength()

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("IRST")

Chapter:AddInstruction("RemoveDebugOverlay", {Name = "Cloud"})

Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Length = 0.5,
    Models = {
        {Name = "IRST", IdentifyAs = "IRST", Model = "models/props_lab/monitor01b.mdl", Angles = Angle(0, 90, 0), Position = Vector(-70, -200, 15), ComeFrom = Vector(0, 0, 50), },
        {Name = "Radar", IdentifyAs = "Radar", Model = "models/radar/radar_sml.mdl", Angles = Angle(0, 90, 0), Position = Vector(70, -200, 15), ComeFrom = Vector(0, 0, 50), },
        {Name = "TargetBase", IdentifyAs = "", Model = "models/hunter/plates/plate2x5.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 200, 0), ComeFrom = Vector(0, 0, 50), Scale = Vector(0.4, 0.4, 1), },
        {Name = "TargetCrate", IdentifyAs = "Ammo Crate", Model = "models/holograms/hq_rcube_thin.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 200, 16), ComeFrom = Vector(0, 0, 50), Scale = Vector(1.5, 1.5, 1), },
        {Name = "TargetCannon", IdentifyAs = "Cannon", Model = "models/tankgun_new/tankgun_100mm.mdl", Angles = Angle(0, -90, 0), Position = Vector(0, 200, 40), ComeFrom = Vector(0, 0, 50), },
    }
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "The IRST relies on a clear trace to each target it's scanning."}))
Chapter:AddInstruction("DebugLine", {Name = "IRSTTrace", Start = Vector(-70, -200, 15), End = Vector(0, 200, 16), Color = Color(100, 255, 100, 255)}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "With nothing in the way, that trace reaches the target and the IRST detects it."}))
Chapter:AddInstruction("RemoveDebugOverlay", {Name = "IRSTTrace"})

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "A smoke cloud between them hides anything behind it."}))
Chapter:AddInstruction("DebugSphere", {Name = "Cloud", Position = Vector(0, 0, 20), Radius = 55, Color = Color(200, 200, 200, 120)}):DelayByLength()
Chapter:AddInstruction("DebugLine", {Name = "IRSTTrace", Start = Vector(-70, -200, 15), End = Vector(-41, -36, 15), Color = Color(255, 80, 80, 255)}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "The IRST's trace clips short at the cloud's edge, so it never sees the target."}))

Chapter:AddInstruction("DebugLine", {Name = "RadarTrace", Start = Vector(70, -200, 15), End = Vector(0, 200, 16), Color = Color(100, 255, 100, 255)}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "A radar doesn't rely on that trace, so the same smoke cloud doesn't stop it from locking on."}))

Chapter:AddInstruction("RemoveDebugOverlay", {Name = "IRSTTrace"})
Chapter:AddInstruction("RemoveDebugOverlay", {Name = "RadarTrace"})
Chapter:AddInstruction("RemoveDebugOverlay", {Name = "Cloud"})
