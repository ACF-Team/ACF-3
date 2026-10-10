local Storyboard = Ponder.API.NewStoryboard("acf", "tankextras", "smoke")
Storyboard:WithName("Smoke")
Storyboard:WithModelIcon("models/props_lab/monitor01b.mdl")
Storyboard:WithDescription("Learn how smoke clouds block optics, lasers and IRST.")
Storyboard:WithIndexOrder(5)

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Smoke Clouds")
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1, Angle = -225, Distance = 1800}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Length = 0.5,
    Models = {
        {Name = "Sensor", IdentifyAs = "", Model = "models/props_lab/monitor01b.mdl", Angles = Angle(0, -90, 0), Position = Vector(0, -200, 15), ComeFrom = Vector(0, 0, 50), },
        {Name = "Target", IdentifyAs = "", Model = "models/hunter/blocks/cube025x025x025.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 200, 10), ComeFrom = Vector(0, 0, 50), },
    }
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "A smoke cloud is a volume of particles, created when Smoke ammunition detonates. It isn't an entity, just an area that blocks certain traces."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "It blocks for most of its lifetime, but stops blocking once it has thinned out near the end."}))

local Chapter = Storyboard:Chapter("Blocking Line of Sight")

Chapter:AddInstruction("DebugLine", {Name = "Trace", Start = Vector(0, -200, 15), End = Vector(0, 200, 10), Color = Color(100, 255, 100, 255)}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "With nothing in the way, a trace between a sensor and its target reaches all the way through."}))
Chapter:AddInstruction("RemoveDebugOverlay", {Name = "Trace"})

Chapter:AddInstruction("DebugSphere", {Name = "Cloud", Position = Vector(0, 0, 20), Radius = 110, Color = Color(200, 200, 200, 120)}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "A smoke cloud sitting between them clips that trace short, stopping it at the near edge of the cloud instead."}))
Chapter:AddInstruction("DebugLine", {Name = "Trace", Start = Vector(0, -200, 15), End = Vector(0, -110, 19), Color = Color(255, 80, 80, 255)}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Anything whose detection depends on that trace now fails to see the target."}))

local Chapter = Storyboard:Chapter("IRST")

Chapter:AddInstruction("AddHalo", {Target = "Sensor", Color = Color(255, 220, 100, 255)})
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "The IRST relies on a clear trace to each target it's scanning. A smoke cloud across that trace hides anything behind it."}))
Chapter:AddInstruction("RemoveHalo", {Target = "Sensor"})

local Chapter = Storyboard:Chapter("Laser Warning Receiver")

Chapter:AddInstruction("AddHalo", {Target = "Sensor", Color = Color(255, 220, 100, 255)})
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "A Laser Warning Receiver normally warns you when a laser crosses its trace to the source. Smoke blocks that trace too, so you won't be warned."}))
Chapter:AddInstruction("RemoveHalo", {Target = "Sensor"})

local Chapter = Storyboard:Chapter("Laser Guidance Computer")

Chapter:AddInstruction("AddHalo", {Target = "Sensor", Color = Color(255, 220, 100, 255)})
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "A Laser Guidance Computer's rangefinding and lock both trace to the target. Smoke clips that trace short, breaking its lock."}))
Chapter:AddInstruction("RemoveHalo", {Target = "Sensor"})

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Optical Guidance Computers are blocked the same way. Radars are not, so smoke won't hide you from one."}))

Chapter:AddInstruction("RemoveDebugOverlay", {Name = "Trace"})
Chapter:AddInstruction("RemoveDebugOverlay", {Name = "Cloud"})
