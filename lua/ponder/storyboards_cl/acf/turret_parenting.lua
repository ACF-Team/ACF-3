local Storyboard = Ponder.API.NewStoryboard("acf", "turrets", "turret-parenting")
Storyboard:WithName("acf.storyboards.turrets.turret_parenting")
Storyboard:WithIndexOrder(0)
Storyboard:WithModelIcon("models/acf/core/t_ring.mdl")
Storyboard:WithDescription(language.GetPhrase("acf.storyboards.turrets.turret_parenting.desc"))

local Chapter1 = Storyboard:Chapter()
Chapter1:AddInstruction("PlaceModel", {
    Name = "TurretRing",
    IdentifyAs = "acf_turret",
    Model = "models/acf/core/t_ring.mdl",
    Position = Vector(0, 0, 10),
    ComeFrom = Vector(0, 0, 32)
})
Chapter1:AddInstruction("Delay", {Length = 0.5})
Chapter1:AddInstruction("PlaceModel", {
    Name = "TurretTrun",
    IdentifyAs = "acf_turret",
    Model = "models/acf/core/t_trun.mdl",
    Position = Vector(0, 20, 48),
    ComeFrom = Vector(0, 0, 32),
    ParentTo = "TurretRing"
})

Chapter1:AddInstruction("Delay", {Length = 0.75})

Chapter1:AddInstruction("ShowText", {
    Name = "ExplainHRing",
    Text = language.GetPhrase("acf.storyboards.turrets.turret_parenting.chapter1.explain_hring"),
    Time = 0,
    Position = Vector(0, 0, 10)
})

Chapter1:AddInstruction("Delay", {Length = 0.75})
Chapter1:AddInstruction("TransformModel", {Target = "TurretRing", Rotation = Angle(0, 45, 0), Length = 0.5})
Chapter1:AddInstruction("Delay", {Length = 0.6})
Chapter1:AddInstruction("TransformModel", {Target = "TurretRing", Rotation = Angle(0, -45, 0), Length = 0.75})
Chapter1:AddInstruction("Delay", {Length = 0.85})
Chapter1:AddInstruction("TransformModel", {Target = "TurretRing", Rotation = Angle(0, 0, 0), Length = 0.75})
Chapter1:AddInstruction("Delay", {Length = 0.65})
Chapter1:AddInstruction("HideText", {Name = "ExplainHRing", Length = 0.4})
Chapter1:AddInstruction("Delay", {Length = 0.3})

Chapter1:AddInstruction("ShowText", {
    Name = "ExplainVRing",
    Text = language.GetPhrase("acf.storyboards.turrets.turret_parenting.chapter1.explain_vring"),
    Time = 0,
    Position = Vector(0, 20, 48)
})

Chapter1:AddInstruction("Delay", {Length = 0.75})
Chapter1:AddInstruction("TransformModel", {Target = "TurretTrun", Rotation = Angle(45, 0, 0), Length = 0.5})
Chapter1:AddInstruction("Delay", {Length = 0.6})
Chapter1:AddInstruction("TransformModel", {Target = "TurretTrun", Rotation = Angle(-45, 0, 0), Length = 0.75})
Chapter1:AddInstruction("Delay", {Length = 0.85})
Chapter1:AddInstruction("TransformModel", {Target = "TurretTrun", Rotation = Angle(0, 0, 0), Length = 0.75})
Chapter1:AddInstruction("Delay", {Length = 0.65})
Chapter1:AddInstruction("HideText", {Name = "ExplainVRing", Length = 0.4})
Chapter1:AddInstruction("Delay", {Length = 0.3})

local Chapter2 = Storyboard:Chapter()
Chapter2:AddInstruction("MoveCameraLookAt", {Time = 0, Length = 1.6, Target = Vector(70, 0, 36), Angle = 30, Distance = 1700, Height = 250})
Chapter2:AddInstruction("Delay", {Length = 0.3})
Chapter2:AddInstruction("PlaceModel", {
    Name = "Gun",
    IdentifyAs = "acf_gun",
    Model = "models/tankgun_new/tankgun_100mm.mdl",
    Position = Vector(0, 0, 48),
    ComeFrom = Vector(500, 0, 0),
    Length = 1.3,
    ParentTo = "TurretTrun"
})

Chapter2:AddInstruction("Delay", {Length = 1.4})

Chapter2:AddInstruction("ShowText", {
    Name = "ExplainGun",
    Text = language.GetPhrase("acf.storyboards.turrets.turret_parenting.chapter2.explain_gun"),
    Time = 0,
    Position = Vector(0, 0, 0),
    ParentTo = "TurretTrun"
})

Chapter2:AddInstruction("ShowToolgun", {Length = .5, Tool = "Multi-Parent"})
local ParentingTime = Chapter2:AddInstruction("Tools.MultiParent", {
    Children = {"Gun"},
    Parent = "TurretTrun",
    Easing = math.ease.InOutQuad
})
Chapter2:AddInstruction("HideToolgun", {Time = ParentingTime, Length = .5})
Chapter2:AddInstruction("Delay", {Length = 3})

Chapter2:AddInstruction("TransformModel", {Target = "TurretRing", Rotation = Angle(0, 45, 0), Length = 0.75})
Chapter2:AddInstruction("TransformModel", {Target = "TurretTrun", Rotation = Angle(-25, 0, 0), Length = 0.75})

Chapter2:AddInstruction("HideText",    {Name = "ExplainGun", Time = 1})