local Storyboard = Ponder.API.NewStoryboard("acf", "tankextras", "irst")
Storyboard:WithName("IRST")
Storyboard:WithModelIcon("models/props_lab/monitor01b.mdl")
Storyboard:WithDescription("Learn about the Infrared Search & Track sensor.")
Storyboard:WithIndexOrder(2)

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Setup")
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1, Angle = -225, Distance = 1600}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Length = 0.5,
    Models = {
        {Name = "Base", IdentifyAs = "Base", Model = "models/hunter/plates/plate2x5.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 0, 50), Scale = Vector(1, 1.25, 1), },
        {Name = "IRST", IdentifyAs = "IRST", Model = "models/props_lab/monitor01b.mdl", Angles = Angle(0, -90, 0), Position = Vector(0, 0, 15), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
    }
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "The IRST searches for players and contraptions passively, without emitting a signal that a warning receiver can detect."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Its range is unlimited, but its gimballed view cone is narrow: 2.5 degrees wide, able to steer up to 15 degrees off its forward axis."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "You can only place 2 per contraption."}))

local Chapter = Storyboard:Chapter("Wiring")

Chapter:AddInstruction("ShowToolgun", {Tool = "Wiring Tool"}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Wire its Active input to turn it on, and Pitch/Yaw to steer its gimbal manually."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Alternatively, wire a HitPos vector (such as from an AIO controller) to aim it directly at a position."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Its outputs report Detected, IDs, Position, Velocity, Distance and Type arrays for everything found, same as a radar."}))
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Like radars, multiple IRSTs can be linked to a Radar Synchronizer to merge their detections into one set of outputs."}))
