local Storyboard = Ponder.API.NewStoryboard("acf", "crew", "crew-overview")
Storyboard:WithName("Crew Basics")
Storyboard:WithModelIcon("models/chairs_playerstart/sitpose.mdl")
Storyboard:WithDescription("Learn the basics of crew.")
Storyboard:WithIndexOrder(3)
local Tank = ACF.PonderModelCaches.TankSkeleton

-- Place crews
local Chapter1 = Storyboard:Chapter("Spawning")
Chapter1:AddInstruction("PlaceModel", {
    Name = "Crew1",
    IdentifyAs = "acf_crew (sitting)",
    Model = "models/chairs_playerstart/sitpose.mdl",
    Position = Vector(0, -20, 0),
    ComeFrom = Vector(0, 0, 32)
})
Chapter1:AddInstruction("MaterialModel", {Target = "Crew1", Material = "sprops/trans/lights/light_plastic"})
Chapter1:AddInstruction("Delay", {Length = 0.5})
Chapter1:AddInstruction("PlaceModel", {
    Name = "Crew2",
    IdentifyAs = "acf_crew (standing)",
    Model = "models/chairs_playerstart/standingpose.mdl",
    Angles = Angle(0, -90, 0),
    Position = Vector(-20, 0, 0),
    ComeFrom = Vector(0, 0, 32),
})
Chapter1:AddInstruction("MaterialModel", {Target = "Crew2", Material = "sprops/trans/lights/light_plastic"})
Chapter1:AddInstruction("Delay", {Length = 1})

-- Spawn instructions
Chapter1:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "These are crew members. They can be spawned from the ACF menu under the Crew category. The model and type can be chosen in the menu.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.5, 0)
})
Chapter1:AddInstruction("Delay", {Length = 4})
Chapter1:AddInstruction("HideText", {Name = "Explain"})

local Chapter2 = Storyboard:Chapter("Models")
Chapter2:AddInstruction("Delay", {Length = 2})
-- Show model types
Chapter2:AddInstruction("ShowText", {
    Name = "Explain1",
    Text = "Some crew prefer sitting.",
    Horizontal = TEXT_ALIGN_RIGHT,
    ParentTo = "Crew1"
})
Chapter2:AddInstruction("Delay", {Length = 2})
Chapter2:AddInstruction("HideText", {Name = "Explain1"})
Chapter2:AddInstruction("Delay", {Length = 2})
Chapter2:AddInstruction("ShowText", {
    Name = "Explain2",
    Text = "Others prefer standing.",
    ParentTo = "Crew2"
})
Chapter2:AddInstruction("Delay", {Length = 2})
Chapter2:AddInstruction("HideText", {Name = "Explain2"})
Chapter2:AddInstruction("Delay", {Length = 2})

-- Remove standing and move sitting into the center
Chapter2:AddInstruction("RemoveModel", {Name = "Crew2"})
Chapter2:AddInstruction("Delay", {Length = 0.5})
Chapter2:AddInstruction("HideText", {Name = "Explain1"})
Chapter2:AddInstruction("RemoveModel", {Name = "Crew1"})

local Chapter3 = Storyboard:Chapter("Tank Example")
Chapter3:AddInstruction("Delay", {Length = 1})
Chapter3:AddInstruction("MoveCameraLookAt", {Length = 2,  Angle = -45, Distance = 2000})
Chapter3:AddInstruction("Delay", {Length = 2})

local T1 = Chapter3:AddInstruction("PlaceModels", {
    Length = 2,
    Models = Tank
})
Chapter3:AddDelay(T1 + 1)
Chapter3:AddInstruction("TransformModel", {Target = "Base", Rotation = Angle(0, 360, 0), Length = 4})
Chapter3:AddInstruction("Delay", {Length = 4})
Chapter3:AddInstruction("TransformModel", {Target = "TurretH", Rotation = Angle(0, 360, 0), Length = 4})
Chapter3:AddInstruction("Delay", {Length = 4})
Chapter3:AddInstruction("TransformModel", {Target = "TurretH2", Rotation = Angle(0, 360, 0), Length = 4})
Chapter3:AddInstruction("Delay", {Length = 4})

Chapter3:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "This is an example tank we'll use for demonstration.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.5, 0)
})
Chapter3:AddInstruction("Delay", {Length = 4})
Chapter3:AddInstruction("HideText", {Name = "Explain"})

local Chapter4 = Storyboard:Chapter("Crew Types")
Chapter4:AddInstruction("Delay", {Length = 1})
Chapter4:AddInstruction("MoveCameraLookAt", {Length = 2,  Angle = -30, Distance = 2000})
Chapter4:AddInstruction("Delay", {Length = 3})
Chapter4:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "Most tanks have a Driver, Gunner, Loader and Commander.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.5, 0)
})
Chapter4:AddInstruction("Delay", {Length = 4})
Chapter4:AddInstruction("HideText", {Name = "Explain"})
Chapter4:AddInstruction("ShowText", {
    Name = "Explain1",
    Text = "Driver",
    Horizontal = TEXT_ALIGN_RIGHT,
    Position = Vector(0, -24, 24),
    ParentTo = "Driver"
})
Chapter4:AddInstruction("ShowText", {
    Name = "Explain2",
    Text = "Gunner",
    Position = Vector(0, -12, 48),
    ParentTo = "Gunner"
})
Chapter4:AddInstruction("ShowText", {
    Name = "Explain3",
    Text = "Loader",
    Horizontal = TEXT_ALIGN_RIGHT,
    Position = Vector(0, 0, 60),
    ParentTo = "Loader"
})
Chapter4:AddInstruction("ShowText", {
    Name = "Explain4",
    Text = "Commander",
    Horizontal = TEXT_ALIGN_RIGHT,
    Position = Vector(0, -12, 48),
    ParentTo = "Commander"
})
Chapter4:AddInstruction("ShowText", {
    Name = "Explain5",
    Text = "Extra Loader",
    Position = Vector(0, 0, 60),
    ParentTo = "Loader2"
})
Chapter4:AddInstruction("Delay", {Length = 4})
Chapter4:AddInstruction("HideText", {Name = "Explain1"})
Chapter4:AddInstruction("HideText", {Name = "Explain2"})
Chapter4:AddInstruction("HideText", {Name = "Explain3"})
Chapter4:AddInstruction("HideText", {Name = "Explain4"})
Chapter4:AddInstruction("HideText", {Name = "Explain5"})
Chapter4:AddInstruction("MoveCameraLookAt", {Length = 2,  Angle = -45, Distance = 2000})
Chapter4:AddInstruction("Delay", {Length = 2})

local Chapter5 = Storyboard:Chapter("Drivers")
Chapter5:AddInstruction("Delay", {Length = 1})
Chapter5:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "Drivers affect the fuel consumption rate of your engines.\nLink them to your baseplate. They can only be linked to one entity.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.15, 0)
})
Chapter5:AddInstruction("FlashModel", {Reps = 2, Models = {"Driver", "Base"}})
Chapter5:AddInstruction("Delay", {Length = 2})
Chapter5:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")})
local LT1 = Chapter5:AddInstruction("ACF Menu", {
    Children = {"Driver"},
    Target = "Base",
    Length = 2,
    Easing = math.ease.InOutQuad
})
Chapter5:AddInstruction("HideToolgun", {Time = LT1})
Chapter5:AddInstruction("Delay", {Length = 6})
Chapter5:AddInstruction("HideText", {Name = "Explain"})

local Chapter6 = Storyboard:Chapter("Gunners")
Chapter6:AddInstruction("Delay", {Length = 1})
Chapter6:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "Gunners affect the accuracy of your guns.\nLink them to your turret ring/baseplate, which ever the guns are located on.\nThey can only be linked to one entity.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.15, 0)
})
Chapter6:AddInstruction("FlashModel", {Reps = 2, Models = {"Gunner", "TurretH"}})
Chapter6:AddInstruction("Delay", {Length = 2})
Chapter6:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")})
local LT1 = Chapter6:AddInstruction("ACF Menu", {
    Children = {"Gunner"},
    Target = "TurretH",
    Length = 2,
    Easing = math.ease.InOutQuad
})
Chapter6:AddInstruction("HideToolgun", {Time = LT1})
Chapter6:AddInstruction("Delay", {Length = 6})
Chapter6:AddInstruction("HideText", {Name = "Explain"})

local Chapter7 = Storyboard:Chapter("Loaders")
Chapter7:AddInstruction("Delay", {Length = 2})
Chapter7:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "Loaders affect the reload speed of your guns. Link them to your gun(s).",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.15, 0)
})
Chapter7:AddInstruction("FlashModel", {Reps = 2, Models = {"Loader", "Loader2", "Gun"}})
Chapter7:AddInstruction("Delay", {Length = 2})
Chapter7:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")})
local LT1 = Chapter7:AddInstruction("ACF Menu", {
    Children = {"Loader", "Loader2"},
    Target = "Gun",
    Length = 4,
    Easing = math.ease.InOutQuad
})
Chapter7:AddInstruction("HideToolgun", {Time = LT1})
Chapter7:AddInstruction("Delay", {Length = 6})
Chapter7:AddInstruction("HideText", {Name = "Explain"})

local Chapter8 = Storyboard:Chapter("Commanders")
Chapter8:AddInstruction("Delay", {Length = 2})
Chapter8:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "Commanders affect the efficiency of your crew. They work without linking.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.15, 0)
})
Chapter8:AddInstruction("FlashModel", {Reps = 2, Models = {"Commander"}})
Chapter8:AddInstruction("Delay", {Length = 2})
Chapter8:AddInstruction("FlashModel", {Reps = 2, Models = {"Gunner", "Loader", "Driver", "Loader2"}})
Chapter8:AddInstruction("Delay", {Length = 4})
Chapter8:AddInstruction("HideText", {Name = "Explain"})
Chapter8:AddInstruction("Delay", {Length = 2})
Chapter8:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "They can be linked to guns and turret rings as you would with a loader and gunner.\nThis is for RWSes and the like, but it impacts their ability to command.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.15, 0)
})
Chapter8:AddInstruction("FlashModel", {Reps = 2, Models = {"Commander"}})
Chapter8:AddInstruction("Delay", {Length = 2})
Chapter8:AddInstruction("FlashModel", {Reps = 2, Models = {"TurretH2", "Gun2"}})
Chapter8:AddInstruction("Delay", {Length = 2})
Chapter8:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")})
local LT1 = Chapter8:AddInstruction("ACF Menu", {
    Children = {"Gun2", "TurretH2"},
    Target = "Commander",
    Length = 4,
    Easing = math.ease.InOutQuad
})
Chapter8:AddInstruction("HideToolgun", {Time = LT1})
Chapter8:AddInstruction("Delay", {Length = 6})
Chapter8:AddInstruction("HideText", {Name = "Explain"})
Chapter8:AddInstruction("Delay", {Length = 2})
Chapter8:AddInstruction("RemoveModels", {Models = Tank})