local Storyboard = Ponder.API.NewStoryboard("acf", "tankbasics", "crew_extras")
Storyboard:WithName("Crew Extras")
Storyboard:WithModelIcon("models/chairs_playerstart/sitpose.mdl")
Storyboard:WithDescription("Learn about Efficiencies, Focus and Replacement")
Storyboard:WithIndexOrder(3)

local Tank = ACF.PonderModelCaches.TankSkeleton

local Chapter = Storyboard:Chapter("Efficiencies")
Chapter:AddDelay(1)

Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "Each crew member has an efficiency, which represents how effective they are at doing their tasks.\nValues in the menu for stuff like reload rate are based on an \"Ideal\" crew member, who is at 100% efficiency.\nEfficiency generally falls within 0% to 100%.",
    Position = Vector(0.5, 0.15, 0),
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "Some factors that affect efficiency are the crew's posture, their global lean, their health, their acceleration and their space and their commander's efficiency.",
    Position = Vector(0.5, 0.15, 0),
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "The exact details are elaborated on in the crew type specific guides.\nThe values shown in the following demonstrations are not exact.",
    Position = Vector(0.5, 0.15, 0),
}))

local Chapter = Storyboard:Chapter("Model Efficiency")
Chapter:AddDelay(1)

Chapter:AddInstruction("MoveCameraLookAt", {Length = 1,  Angle = 45, Distance = 2000}):DelayByLength()

Chapter:AddInstruction("Caption", {
    Text = "For a given crew type, their efficiency is affected by their model. For example, Loaders prefer standing.",
    Position = Vector(0.5, 0.15, 0),
})

Chapter:AddInstruction("PlaceModel", {
    Name = "Crew1",
    IdentifyAs = "acf_crew (sitting)",
    Model = "models/chairs_playerstart/sitpose.mdl",
    Position = Vector(0, -20, 0),
    ComeFrom = Vector(0, 0, 32)
})
Chapter:AddInstruction("MaterialModel", {Target = "Crew1", Material = "sprops/trans/lights/light_plastic"}):DelayByLength()

Chapter:AddInstruction("PlaceModel", {
    Name = "Crew2",
    IdentifyAs = "acf_crew (standing)",
    Model = "models/chairs_playerstart/standingpose.mdl",
    Angles = Angle(0, -90, 0),
    Position = Vector(-20, 0, 0),
    ComeFrom = Vector(0, 0, 32),
})
Chapter:AddInstruction("MaterialModel", {Target = "Crew2", Material = "sprops/trans/lights/light_plastic"}):DelayByLength()

local _, Name1 = Chapter:AddInstruction("Caption", {
    Text = "Model Eff: 0.75",
    Horizontal = TEXT_ALIGN_RIGHT,
    Position = Vector(0.7, 0.15, 0),
    ParentTo = "Crew1",
    TextLength = 2,
    UseEntity = true,
})

local _, Name2 = Chapter:AddInstruction("Caption", {
    Text = "Model Eff: 1.0",
    Horizontal = TEXT_ALIGN_LEFT,
    Position = Vector(0.7, 0.15, 0),
    ParentTo = "Crew2",
    TextLength = 2,
    UseEntity = true,
})

Chapter:AddDelay(3)

Chapter:AddInstruction("HideText", {Name = Name1}):DelayByLength()
Chapter:AddInstruction("HideText", {Name = Name2}):DelayByLength()
Chapter:AddInstruction("RemoveModel", {Name = "Crew2"}):DelayByLength()
Chapter:AddInstruction("TransformModel", {Target = "Crew1", Position = Vector(0, 0, 0), Length = 1}):DelayByLength()

local Chapter = Storyboard:Chapter("Lean Efficiency")
Chapter:AddDelay(1)

Chapter:AddInstruction("MoveCameraLookAt", {Length = 1,  Angle = -90, Distance = 1500}):DelayByLength()
Chapter:AddInstruction("TransformModel", {Target = "Crew1", Position = Vector(0, 0, 24), Length = 1}):DelayByLength()

Chapter:AddInstruction("Caption", {
    Text = "Lean efficiency is determined by how upright your crew are relative to the world upwards. The more upright they are, the better.",
    TextLength = 3,
    Position = Vector(0.5, 0.15, 0),
})

Chapter:AddDelay(1)

Chapter:AddInstruction("StateText", {
    ParentTo = Crew1,
    Position = Vector(0.7, 0.15, 0),
    Length = 6,
    TextFunction = function(progress)
        return "Lean Eff: " .. math.floor((1-progress) * 100) .. "%"
    end
})

Chapter:AddInstruction("TransformModel", {Target = "Crew1", Rotation = Angle(0, 0, 45), Length = 6}):DelayByLength()

Chapter:AddDelay(1)

Chapter:AddInstruction("TransformModel", {Target = "Crew1", Rotation = Angle(0, 0, 0), Length = 0.5}):DelayByLength()
Chapter:AddInstruction("TransformModel", {Target = "Crew1", Position = Vector(0, 0, 0), Length = 0.5}):DelayByLength()
Chapter:AddInstruction("MoveCameraLookAt", {Length = 1,  Angle = 45, Distance = 2000}):DelayByLength()

local Chapter = Storyboard:Chapter("Health Efficiency")
Chapter:AddDelay(1)

Chapter:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "Health efficiency is based on the percentage of the crew's health.\nStay Alive.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.15, 0)
})
Chapter:AddDelay(2)
Chapter:AddInstruction("ShowText", {
    Name = "Explain2",
    Text = "Health Eff: 100%",
    ParentTo = "Crew1"
})
Chapter:AddDelay(2)
Chapter:AddInstruction("PlaceModel", {
    Name = "Gun",
    IdentifyAs = "",
    Model = "models/tankgun_new/tankgun_100mm.mdl",
    Angles = Angle(0, -90, 0),
    Position = Vector(0, 192, 36),
    ComeFrom = Vector(0, 0, 32),
})
Chapter:AddDelay(2)
Chapter:AddInstruction("PlaySound", {Sound = "acf_base/weapons/cannon_new.mp3"})
Chapter:AddInstruction("SetSequence", {Name = "Gun", Sequence = "shoot"})
Chapter:AddInstruction("Delay", {Length = 0.5})
Chapter:AddInstruction("PlaySound", {Sound = "npc/zombie/zombie_voice_idle6.wav"})
Chapter:AddInstruction("MaterialModel", {Target = "Crew1", Material = "models/flesh"})
Chapter:AddInstruction("ChangeText", {
    Name = "Explain2",
    Text = "Health Eff: 0%",
})
Chapter:AddDelay(2)
Chapter:AddInstruction("RemoveModel", {Name = "Gun"})
Chapter:AddInstruction("HideText", {Name = "Explain"})
Chapter:AddInstruction("HideText", {Name = "Explain2"})
Chapter:AddInstruction("MaterialModel", {Target = "Crew1", Material = "sprops/trans/lights/light_plastic"})
Chapter:AddDelay(2)

local Chapter = Storyboard:Chapter("Acceleration Efficiency")
Chapter:AddDelay(2)
Chapter:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "Acceleration efficiency is based on the crew's acceleration.\nDon't drive into a wall.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.15, 0)
})
Chapter:AddInstruction("ShowText", {
    Name = "Explain2",
    Text = "Accel Eff: 100%",
    ParentTo = "Crew1"
})
Chapter:AddDelay(2)
Chapter:AddInstruction("TransformModel", {Target = "Crew1", Rotation = Angle(0, 360 * 10, 0), Length = 2})
Chapter:AddDelay(1)
Chapter:AddInstruction("ChangeText", {
    Name = "Explain2",
    Text = "Accel Eff: 50%",
})
Chapter:AddDelay(1)
Chapter:AddInstruction("TransformModel", {Target = "Crew1", Rotation = Angle(0, 360 * 20, 0), Length = 2})
Chapter:AddDelay(1)
Chapter:AddInstruction("ChangeText", {
    Name = "Explain2",
    Text = "Accel Eff: 0%",
})
Chapter:AddDelay(1)
Chapter:AddInstruction("TransformModel", {Target = "Crew1", Rotation = Angle(0, 360 * 100, 0), Length = 2})
Chapter:AddDelay(1)
Chapter:AddInstruction("PlaySound", {Sound = "npc/zombie/zombie_voice_idle6.wav"})
Chapter:AddInstruction("MaterialModel", {Target = "Crew1", Material = "models/flesh"})
Chapter:AddDelay(2)
Chapter:AddInstruction("MaterialModel", {Target = "Crew1", Material = "sprops/trans/lights/light_plastic"})
Chapter:AddInstruction("HideText", {Name = "Explain"})
Chapter:AddInstruction("HideText", {Name = "Explain2"})

local Chapter = Storyboard:Chapter("Space Efficiency")
Chapter:AddDelay(2)
Chapter:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "Space efficiency is based on the crew's space.\nDon't put them in a box.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.15, 0)
})
Chapter:AddInstruction("PlaceModel", {
    Name = "Box",
    IdentifyAs = "",
    Model = "models/hunter/blocks/cube025x025x025.mdl",
    Angles = Angle(0, 0, 0),
    Position = Vector(24, 0, 36),
    Scale = Vector(6, 6, 6),
    ComeFrom = Vector(0, 0, 0),
})
Chapter:AddInstruction("MaterialModel", {Target = "Box", Material = "models/debug/debugwhite"})
Chapter:AddInstruction("ColorModel", {Target = "Box", Color = Color(255, 0, 0, 150)})
Chapter:AddInstruction("ShowText", {
    Name = "Explain2",
    Text = "Space Eff: 100%",
    ParentTo = "Crew1"
})
Chapter:AddDelay(2)
Chapter:AddInstruction("TransformModel", {Target = "Box", Scale = Vector(4, 4, 4), Length = 4})
Chapter:AddDelay(2)
Chapter:AddInstruction("ChangeText", {
    Name = "Explain2",
    Text = "Space Eff: 50%",
})
Chapter:AddDelay(2)
Chapter:AddInstruction("ChangeText", {
    Name = "Explain2",
    Text = "Space Eff: 0%",
})
Chapter:AddDelay(2)
Chapter:AddInstruction("HideText", {Name = "Explain"})
Chapter:AddInstruction("HideText", {Name = "Explain2"})
Chapter:AddInstruction("RemoveModel", {Name = "Box"})

local Chapter = Storyboard:Chapter("Commander Efficiency")
Chapter:AddDelay(2)
Chapter:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "Commander efficiency is based on the commander's efficiency.\nIf the commander is gone, the other crews need to take over.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.15, 0)
})
Chapter:AddInstruction("ShowText", {
    Name = "Explain2",
    Text = "Crew Eff: 1.0",
    Horizontal = TEXT_ALIGN_RIGHT,
    ParentTo = "Crew1"
})
Chapter:AddInstruction("PlaceModel", {
    Name = "Commander",
    IdentifyAs = "",
    Model = "models/chairs_playerstart/sitpose.mdl",
    Angles = Angle(0, 0, 0),
    Position = Vector(0, 36, 0),
    ComeFrom = Vector(0, 0, 32),
})
Chapter:AddInstruction("MaterialModel", {Target = "Commander", Material = "sprops/trans/lights/light_plastic"})
Chapter:AddInstruction("ShowText", {
    Name = "Explain3",
    Text = "Commander Eff: 100%",
    ParentTo = "Commander"
})
Chapter:AddDelay(2)
Chapter:AddInstruction("RemoveModel", {Name = "Commander"})
Chapter:AddInstruction("ChangeText", {
    Name = "Explain3",
    Text = "Commander Eff: 0%",
})
Chapter:AddInstruction("HideText", {Name = "Explain3"})
Chapter:AddInstruction("ChangeText", {
    Name = "Explain2",
    Text = "Crew Eff: 75%",
})
Chapter:AddDelay(2)
Chapter:AddInstruction("HideText", {Name = "Explain"})
Chapter:AddInstruction("HideText", {Name = "Explain2"})

local Chapter = Storyboard:Chapter("Focus")
Chapter:AddDelay(2)
Chapter:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "A crew member will spread their focus across the entities they are linked to.\nFor example, a loader linked to two guns will reload both guns at half the speed.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.15, 0)
})
Chapter:AddInstruction("PlaceModel", {
    Name = "Gun",
    IdentifyAs = "",
    Model = "models/tankgun_new/tankgun_100mm.mdl",
    Angles = Angle(0, 90, 0),
    Position = Vector(24, 0, 36),
    ComeFrom = Vector(0, 0, 32),
})
Chapter:AddInstruction("PlaceModel", {
    Name = "Gun2",
    IdentifyAs = "",
    Model = "models/tankgun_new/tankgun_100mm.mdl",
    Angles = Angle(0, 90, 0),
    Position = Vector(-24, 0, 36),
    ComeFrom = Vector(0, 0, 32),
})
Chapter:AddDelay(2)
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")})
local LT1 = Chapter:AddInstruction("ACF Menu", {
    Children = {"Crew1"},
    Target = "Gun",
    Length = 2,
    Easing = math.ease.InOutQuad
})
Chapter:AddInstruction("HideToolgun", {Time = LT1})
Chapter:AddDelay(2)
Chapter:AddInstruction("ShowText", {
    Name = "Explain2",
    Text = "Focus: 100%",
    ParentTo = "Crew1"
})
Chapter:AddInstruction("ShowText", {
    Name = "Explain3",
    Text = "Reload: 10s",
    Horizontal = TEXT_ALIGN_RIGHT,
    ParentTo = "Gun"
})
Chapter:AddDelay(2)
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")})
local LT1 = Chapter:AddInstruction("ACF Menu", {
    Children = {"Crew1"},
    Target = "Gun2",
    Length = 2,
    Easing = math.ease.InOutQuad
})
Chapter:AddInstruction("HideToolgun", {Time = LT1})
Chapter:AddDelay(2)
Chapter:AddInstruction("ChangeText", {
    Name = "Explain2",
    Text = "Focus: 50%",
})
Chapter:AddInstruction("ChangeText", {
    Name = "Explain3",
    Text = "Reload: 20s",
})
Chapter:AddInstruction("ShowText", {
    Name = "Explain4",
    Text = "Reload: 20s",
    ParentTo = "Gun2"
})
Chapter:AddDelay(2)
Chapter:AddInstruction("HideText", {Name = "Explain"})
Chapter:AddInstruction("HideText", {Name = "Explain2"})
Chapter:AddInstruction("HideText", {Name = "Explain3"})
Chapter:AddInstruction("HideText", {Name = "Explain4"})
Chapter:AddInstruction("RemoveModel", {Name = "Gun"})
Chapter:AddInstruction("RemoveModel", {Name = "Gun2"})
Chapter:AddInstruction("RemoveModel", {Name = "Crew1"})

local Chapter = Storyboard:Chapter("Crew Replacement")
Chapter:AddDelay(2)
local T1 = Chapter:AddInstruction("PlaceModels", {
    Length = 2,
    Models = Tank
})
Chapter:AddDelay(T1 + 1)

Chapter:AddDelay(2)
Chapter:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "If a crew member is killed, the other crew members will take over their tasks.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.15, 0)
})
Chapter:AddDelay(2)
Chapter:AddInstruction("PlaceModel", {
    Name = "Gun3",
    IdentifyAs = "",
    Model = "models/tankgun_new/tankgun_100mm.mdl",
    Angles = Angle(90, 0, 0),
    Scale = Vector(0.5, 0.5, 0.5),
    Position = Vector(0, 0, 144),
    ComeFrom = Vector(0, 0, 32),
    ParentTo = "Gunner"
})
Chapter:AddDelay(2)
Chapter:AddInstruction("PlaySound", {Sound = "acf_base/weapons/cannon_new.mp3"})
Chapter:AddInstruction("SetSequence", {Name = "Gun3", Sequence = "shoot"})
Chapter:AddInstruction("PlaySound", {Sound = "npc/zombie/zombie_voice_idle6.wav"})
Chapter:AddInstruction("MaterialModel", {Target = "Gunner", Material = "models/flesh"})
Chapter:AddDelay(2)
Chapter:AddInstruction("MaterialModel", {Target = "Commander", Material = "models/flesh"})
Chapter:AddInstruction("MaterialModel", {Target = "Gunner", Material = "sprops/trans/lights/light_plastic"})
Chapter:AddDelay(2)
Chapter:AddInstruction("PlaySound", {Sound = "acf_base/weapons/cannon_new.mp3"})
Chapter:AddInstruction("SetSequence", {Name = "Gun3", Sequence = "shoot"})
Chapter:AddInstruction("PlaySound", {Sound = "npc/zombie/zombie_voice_idle6.wav"})
Chapter:AddInstruction("MaterialModel", {Target = "Gunner", Material = "models/flesh"})
Chapter:AddDelay(2)
Chapter:AddInstruction("MaterialModel", {Target = "Loader", Material = "models/flesh"})
Chapter:AddInstruction("MaterialModel", {Target = "Gunner", Material = "sprops/trans/lights/light_plastic"})
Chapter:AddDelay(2)
Chapter:AddInstruction("RemoveModels", {Models = Tank})
Chapter:AddInstruction("RemoveModel", {Name = "Gun3"})
Chapter:AddInstruction("HideText", {Name = "Explain"})
Chapter:AddDelay(2)