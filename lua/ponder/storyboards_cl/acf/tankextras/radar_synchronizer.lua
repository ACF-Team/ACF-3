local Storyboard = Ponder.API.NewStoryboard("acf", "tankextras", "radar_synchronizer")
Storyboard:WithName("Radar Synchronizer")
Storyboard:WithModelIcon("models/props_lab/reciever01d.mdl")
Storyboard:WithDescription("Learn how to combine multiple sensors with the Radar Synchronizer.")
Storyboard:WithIndexOrder(3)

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Setup")
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1, Angle = -225, Distance = 1800}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {
    Length = 0.5,
    Models = {
        {Name = "Base", IdentifyAs = "Base", Model = "models/hunter/plates/plate2x5.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 0, 50), Scale = Vector(1, 1.25, 1), },
        {Name = "Radar1", IdentifyAs = "Radar", Model = "models/radar/radar_sml.mdl", Angles = Angle(0, 0, 0), Position = Vector(60, -60, 15), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        {Name = "Radar2", IdentifyAs = "Radar", Model = "models/radar/radar_sml.mdl", Angles = Angle(0, 180, 0), Position = Vector(-60, -60, 15), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
        {Name = "Sync", IdentifyAs = "Radar Synchronizer", Model = "models/props_lab/reciever01d.mdl", Angles = Angle(0, -90, 0), Position = Vector(0, 60, 15), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
    }
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "The Radar Synchronizer links to multiple radars and IRSTs, running one combined detection pass in their place."}))

local Chapter = Storyboard:Chapter("Linking")

-- A short flat wedge flashing outward from a sensor, standing in for one scan tick.
local function Ping(name, origin, yaw, color)
    local p2 = origin + Angle(0, yaw - 20, 0):Forward() * 45
    local p3 = origin + Angle(0, yaw + 20, 0):Forward() * 45
    Chapter:AddInstruction("DebugTriangle", {Name = name, P1 = origin, P2 = p2, P3 = p3, Color = color, Lifetime = 0.3})
end

local Radar1Pos, Radar1Yaw = Vector(60, -60, 15), 0
local Radar2Pos, Radar2Yaw = Vector(-60, -60, 15), 180
local Cyan, Orange, Green  = Color(80, 200, 255, 150), Color(255, 160, 60, 150), Color(100, 255, 100, 160)

Ping("RadarPing1", Radar1Pos, Radar1Yaw, Cyan)
Chapter:AddDelay(0.5)
Ping("RadarPing2", Radar2Pos, Radar2Yaw, Orange)
Chapter:AddDelay(0.4)
Ping("RadarPing3", Radar1Pos, Radar1Yaw, Cyan)
Chapter:AddDelay(0.6)
Ping("RadarPing4", Radar2Pos, Radar2Yaw, Orange)
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Unlinked, each radar scans on its own schedule, out of step with the other."}))

Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Right click each sensor, then right click the Synchronizer, to link them."}))
Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {
    Children = {"Radar1", "Radar2"},
    Target = "Sync",
    Easing = math.ease.InOutQuad,
    Length = 2,
}))

Chapter:AddInstruction("HideToolgun", {}):DelayByLength()

-- Same color, same tick, to show both radars now scan in step with each other.
Ping("RadarPing5", Radar1Pos, Radar1Yaw, Green)
Ping("RadarPing6", Radar2Pos, Radar2Yaw, Green)
Chapter:AddDelay(0.6)
Ping("RadarPing7", Radar1Pos, Radar1Yaw, Green)
Ping("RadarPing8", Radar2Pos, Radar2Yaw, Green)
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "Once linked, those sensors stop scanning independently. The Synchronizer groups them by scan rate so none of them are sped up or slowed down."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "It picks the healthiest linked sensor with line of sight to each target, and merges every result into its own outputs."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "The merged picture is also mirrored back onto every linked radar, so a missile rack wired to that radar sees it too."}))
Chapter:AddDelay(Chapter:AddInstruction("Caption", {Text = "You can only place 2 per contraption, and sensors auto unlink if they drift too far away."}))
