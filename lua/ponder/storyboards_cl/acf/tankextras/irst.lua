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

-- A narrow wedge flashing across the gimbal's steer range, standing in for the view cone sweeping.
local function Beam(name, yaw)
    local origin = Vector(0, 0, 15)
    local p2 = origin + Angle(0, yaw - 1.25, 0):Forward() * 70
    local p3 = origin + Angle(0, yaw + 1.25, 0):Forward() * 70
    Chapter:AddInstruction("DebugTriangle", {Name = name, P1 = origin, P2 = p2, P3 = p3, Color = Color(255, 210, 100, 150), Lifetime = 0.3})
end

Beam("IrstBeam1", -105)
Chapter:AddDelay(0.5)
Beam("IrstBeam2", -90)
Chapter:AddDelay(0.5)
Beam("IrstBeam3", -75)
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Its range is unlimited, but its gimballed view cone is narrow: 2.5 degrees wide, able to steer up to 15 degrees off its forward axis."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "You can only place 2 per contraption."}))

local Chapter = Storyboard:Chapter("Wiring")

Chapter:AddInstruction("ShowToolgun", {Tool = "Wiring Tool"}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Wire its Active input to turn it on, and Pitch/Yaw to steer its gimbal manually."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Alternatively, wire a HitPos vector (such as from an AIO controller) to aim it directly at a position."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Its outputs report Detected, IDs, Position, Velocity, Distance and Type arrays for everything found, same as a radar."}))
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

Chapter:AddInstruction("PlaceModel", {Name = "AIO", IdentifyAs = "AIO Controller", Model = "models/hunter/plates/plate025x025.mdl", Position = Vector(-30, 60, 3), ComeFrom = Vector(0, 0, 50), ParentTo = "Base"}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Or link it to an AIO controller. Its contacts show on the HUD, and selecting one points the IRST at it."}))
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {Children = {"IRST"}, Target = "AIO", Easing = math.ease.InOutQuad, Length = 2}))
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Like radars, multiple IRSTs can be linked to a Radar Synchronizer to merge their detections into one set of outputs."}))
