local Storyboard = Ponder.API.NewStoryboard("acf", "tankbasics", "crew_basics")
Storyboard:WithName("Crew Basics")
Storyboard:WithModelIcon("models/chairs_playerstart/sitpose.mdl")
Storyboard:WithDescription("Learn the basics of crew.")
Storyboard:WithIndexOrder(4)
local Tank = ACF.PonderModelCaches.TankSkeleton

local TorsoOffsets = {
    Standing = Vector(0, -8, 56-6),
    Sitting = Vector(0, -22, 38-6),
}

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Spawning")

-- Place crews
Chapter:AddInstruction("PlaceModel", {
    Name = "Crew1",
    IdentifyAs = "acf_crew (sitting)",
    Model = "models/chairs_playerstart/sitpose.mdl",
    Position = Vector(0, -20, 0),
    ComeFrom = Vector(0, 0, 32)
}):DelayByLength()
Chapter:AddInstruction("MaterialModel", {Target = "Crew1", Material = "sprops/trans/lights/light_plastic"})
Chapter:AddInstruction("PlaceModel", {
    Name = "Crew2",
    IdentifyAs = "acf_crew (standing)",
    Model = "models/chairs_playerstart/standingpose.mdl",
    Angles = Angle(0, -90, 0),
    Position = Vector(-20, 0, 0),
    ComeFrom = Vector(0, 0, 32),
}):DelayByLength()
Chapter:AddInstruction("MaterialModel", {Target = "Crew2", Material = "sprops/trans/lights/light_plastic"})

-- Spawn instructions
Chapter:AddDelay(1)

Chapter:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "These are crew members. They can be spawned from the ACF menu under the Crew category. The model and type can be chosen in the menu.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.5, 0)
})
Chapter:AddDelay(4)
Chapter:AddInstruction("HideText", {Name = "Explain"})

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Models")
Chapter:AddDelay(1)

Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "Some crew prefer sitting.",
    Horizontal = TEXT_ALIGN_RIGHT,
    Position = TorsoOffsets.Sitting,
    ParentTo = "Crew1",
    TextLength = 3,
    UseEntity = true,
}))

Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "Others prefer standing.",
    Horizontal = TEXT_ALIGN_RIGHT,
    Position = TorsoOffsets.Standing,
    ParentTo = "Crew2",
    TextLength = 3,
    UseEntity = true,
}))

-- Remove standing and move sitting into the center
Chapter:AddInstruction("RemoveModel", {Name = "Crew2"}):DelayByLength()
Chapter:AddInstruction("RemoveModel", {Name = "Crew1"}):DelayByLength()

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Tank Example")
Chapter:AddDelay(1)

Chapter:AddInstruction("MoveCameraLookAt", {Length = 2,  Angle = -45, Distance = 2000}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("PlaceModels", {Length = 2, Models = Tank}))

Chapter:AddInstruction("TransformModel", {Target = "Base", Rotation = Angle(0, 360, 0), Length = 2}):DelayByLength()
Chapter:AddInstruction("TransformModel", {Target = "TurretH", Rotation = Angle(0, 360, 0), Length = 2}):DelayByLength()
Chapter:AddInstruction("TransformModel", {Target = "TurretH2", Rotation = Angle(0, 360, 0), Length = 2}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "This is an example tank we'll use for demonstration.",
    Position = Vector(0.5, 0.15, 0)
}))

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Crew Types")
Chapter:AddDelay(1)

Chapter:AddInstruction("MoveCameraLookAt", {Length = 2,  Angle = -30, Distance = 2000}):DelayByLength()

Chapter:AddDelay(Chapter:AddInstruction("Caption", {
    Text = "Most tanks have a Driver, Gunner, Loader and Commander.",
    Position = Vector(0.5, 0.15, 0),
    Horizontal = TEXT_ALIGN_CENTER,
}))


Chapter:AddInstruction("Caption", {
    Text = "Driver",
    Horizontal = TEXT_ALIGN_RIGHT,
    Position = TorsoOffsets.Sitting,
    ParentTo = "Driver",
    TextLength = 3,
    UseEntity = true,
})

Chapter:AddInstruction("Caption", {
    Text = "Gunner",
    Position = TorsoOffsets.Sitting,
    ParentTo = "Gunner",
    TextLength = 3,
    UseEntity = true,
})

Chapter:AddInstruction("Caption", {
    Text = "Loader",
    Horizontal = TEXT_ALIGN_RIGHT,
    Position = TorsoOffsets.Standing,
    ParentTo = "Loader",
    TextLength = 3,
    UseEntity = true,
})

Chapter:AddInstruction("Caption", {
    Text = "Commander",
    Horizontal = TEXT_ALIGN_RIGHT,
    Position = TorsoOffsets.Sitting,
    ParentTo = "Commander",
    TextLength = 3,
    UseEntity = true,
})

Chapter:AddInstruction("Caption", {
    Text = "Extra Loader",
    Position = TorsoOffsets.Standing,
    ParentTo = "Loader2",
    TextLength = 3,
    UseEntity = true,
})

Chapter:AddDelay(3)

Chapter:AddInstruction("MoveCameraLookAt", {Length = 2,  Angle = -45, Distance = 2000}):DelayByLength()

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Drivers")
Chapter:AddDelay(1)

local _, Name = Chapter:AddInstruction("Caption", {
    Text = "Drivers affect the fuel consumption rate of your engines.\nLink them to your baseplate. They can only be linked to one entity.",
    Position = Vector(0.5, 0.15, 0),
    KeepText = true,
})

Chapter:AddDelay(Chapter:AddInstruction("FlashModel", {Reps = 2, Models = {"Driver", "Base"}}))
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {Children = {"Driver"}, Target = "Base", Length = 2, Easing = math.ease.InOutQuad}))
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()
Chapter:AddInstruction("HideText", {Name = Name}):DelayByLength()

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Gunners")
Chapter:AddDelay(1)

local _, Name = Chapter:AddInstruction("Caption", {
    Text = "Gunners affect the accuracy of your guns.\nLink them to your turret ring/baseplate, which ever the guns are located on.\nThey can only be linked to one entity.",
    Position = Vector(0.5, 0.15, 0),
    KeepText = true,
})

Chapter:AddDelay(Chapter:AddInstruction("FlashModel", {Reps = 2, Models = {"Gunner", "TurretH"}}))
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {Children = {"Gunner"}, Target = "TurretH", Length = 2, Easing = math.ease.InOutQuad}))
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()
Chapter:AddInstruction("HideText", {Name = Name}):DelayByLength()

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Loaders")
Chapter:AddDelay(1)

local _, Name = Chapter:AddInstruction("Caption", {
    Text = "Loaders affect the reload speed of your guns. Link them to your gun(s).",
    Position = Vector(0.5, 0.15, 0),
    KeepText = true,
})

Chapter:AddDelay(Chapter:AddInstruction("FlashModel", {Reps = 2, Models = {"Loader", "Loader2", "Gun"}}))
Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")}):DelayByLength()
Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {Children = {"Loader", "Loader2"}, Target = "Gun", Length = 4, Easing = math.ease.InOutQuad}))
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()
Chapter:AddInstruction("HideText", {Name = Name}):DelayByLength()

-------------------------------------------------------------------------------------------------
local Chapter = Storyboard:Chapter("Commanders")
Chapter:AddDelay(1)

local _, Name = Chapter:AddInstruction("Caption", {
    Text = "Commanders affect the efficiency of your crew. They work without linking.",
    Position = Vector(0.5, 0.15, 0),
    KeepText = true,
})

Chapter:AddDelay(Chapter:AddInstruction("FlashModel", {Reps = 2, Models = {"Commander"}}))
Chapter:AddDelay(Chapter:AddInstruction("FlashModel", {Reps = 2, Models = {"Gunner", "Loader", "Driver", "Loader2"}}))
Chapter:AddInstruction("HideText", {Name = Name}):DelayByLength()

Chapter:AddDelay(1)

local _, Name = Chapter:AddInstruction("Caption", {
    Text = "They can be linked to guns and turret rings as you would with a loader and gunner.\nThis is for RWSes and the like, but it impacts their ability to command.",
    Position = Vector(0.5, 0.15, 0),
    KeepText = true,
})

Chapter:AddDelay(Chapter:AddInstruction("FlashModel", {Reps = 2, Models = {"Commander"}}))
Chapter:AddDelay(Chapter:AddInstruction("FlashModel", {Reps = 2, Models = {"TurretH2", "Gun2"}}))

Chapter:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")})
Chapter:AddDelay(Chapter:AddInstruction("ACF Menu", {Children = {"Gun2", "TurretH2"}, Target = "Commander", Length = 4, Easing = math.ease.InOutQuad}))
Chapter:AddInstruction("HideToolgun", {}):DelayByLength()
Chapter:AddInstruction("HideText", {Name = Name}):DelayByLength()
Chapter:AddInstruction("RemoveModels", {Models = Tank})