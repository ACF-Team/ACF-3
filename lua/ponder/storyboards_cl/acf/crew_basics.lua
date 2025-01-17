local Storyboard = Ponder.API.NewStoryboard("acf", "crew", "crew-overview")
Storyboard:WithName("Crew Basics")
Storyboard:WithModelIcon("models/chairs_playerstart/sitpose.mdl")
Storyboard:WithDescription("Learn the basics of crew")
Storyboard:WithIndexOrder(3)

-- Import tank skeleton
-- (Baseplate: 2x5, Engine: V12L, Gearbox: Transaxial L, Main Gun: 125mmC, RWS Gun: 20mmMG)
local Tank = {
    {Name = "Base", IdentifyAs = "Base", Model = "models/hunter/plates/plate2x5.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 0, 50), Scale = Vector(1, 1.25, 1), },

    -- Engine area
    {Name = "Engine", IdentifyAs = "Engine", Model = "models/engines/v12l.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, -84, 3), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
    {Name = "Gearbox", IdentifyAs = "Gearbox", Model = "models/engines/transaxial_l.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, -144, 3), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
    {Name = "FuelTank1", IdentifyAs = "Fuel Tank", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, -90, 0), Position = Vector(36, -84, 15), ComeFrom = Vector(0, 0, 50), Scale = Vector(6, 2, 2), Material = "models/props_canal/metalcrate001d", ParentTo = "Base", },
    {Name = "FuelTank2", IdentifyAs = "Fuel Tank", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, -90, 0), Position = Vector(-36, -84, 15), ComeFrom = Vector(0, 0, 50), Scale = Vector(6, 2, 2), Material = "models/props_canal/metalcrate001d", ParentTo = "Base", },

    -- Driver area
    {Name = "FuelTank3", IdentifyAs = "Fuel Tank", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, -90, 0), Position = Vector(36, 120, 15), ComeFrom = Vector(0, 0, 50), Scale = Vector(4, 2, 2), Material = "models/props_canal/metalcrate001d", ParentTo = "Base", },
    {Name = "FuelTank4", IdentifyAs = "Fuel Tank", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, -90, 0), Position = Vector(-36, 120, 15), ComeFrom = Vector(0, 0, 50), Scale = Vector(4, 2, 2), Material = "models/props_canal/metalcrate001d", ParentTo = "Base", },
    {Name = "Driver", IdentifyAs = "Driver", Model = "models/chairs_playerstart/sitpose.mdl", Angles = Angle(0, 0, 30), Position = Vector(0, 144, 3), ComeFrom = Vector(0, 0, 50), Material = "sprops/sprops_grid_12x12", ParentTo = "Base", },
    {Name = "AmmoCrate3", IdentifyAs = "Ammo Crate (125mmC AP)", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, 90, 0), Position = Vector(24, 72, 15), ComeFrom = Vector(0, 0, 50), Scale = Vector(3, 3.5, 2), Material = "phoenix_storms/future_vents", ParentTo = "Base", },
    {Name = "AmmoCrate4", IdentifyAs = "Ammo Crate (125mmC HE)", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, 90, 0), Position = Vector(-24, 72, 15), ComeFrom = Vector(0, 0, 50), Scale = Vector(3, 3.5, 2), Material = "phoenix_storms/future_vents", ParentTo = "Base", },

    -- Wheels
    {Name = "LWheel1", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(72, -144, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
    {Name = "LWheel2", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(72, -48, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
    {Name = "LWheel3", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(72, 48, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
    {Name = "LWheel4", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(72, 144, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
    {Name = "RWheel1", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(-72, -144, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
    {Name = "RWheel2", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(-72, -48, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
    {Name = "RWheel3", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(-72, 48, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
    {Name = "RWheel4", IdentifyAs = "Wheel", Model = "models/xeon133/offroad/off-road-40.mdl", Angles = Angle(0, 0, 0), Position = Vector(-72, 144, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },

    -- Turret
    {Name = "TurretH", IdentifyAs = "Turret Ring", Model = "models/acf/core/t_ring.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 36), ComeFrom = Vector(0, 0, 50), ParentTo = "Base", },
    {Name = "TurretV", IdentifyAs = "Turret Trun", Model = "models/acf/core/t_trun.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, 48, 18), ComeFrom = Vector(0, 0, 50), ParentTo = "TurretH", },
    {Name = "AmmoCrate1", IdentifyAs = "Ammo Crate (125mmC AP)", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, 90, 0), Position = Vector(24, -72, 24), ComeFrom = Vector(0, 0, 50), Scale = Vector(4, 4, 2), Material = "phoenix_storms/future_vents", ParentTo = "TurretH", },
    {Name = "AmmoCrate2", IdentifyAs = "Ammo Crate (125mmC HE)", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, 90, 0), Position = Vector(-24, -72, 24), ComeFrom = Vector(0, 0, 50), Scale = Vector(4, 4, 2), Material = "phoenix_storms/future_vents", ParentTo = "TurretH", },

    -- Turret Electronics
    {Name = "BallComp", IdentifyAs = "Ballistic Computer", Model = "models/acf/core/t_computer.mdl", Angles = Angle(0, 0, 0), Position = Vector(-36, 36, 12), ComeFrom = Vector(0, 0, 50), ParentTo = "TurretH", },
    {Name = "Gyro", IdentifyAs = "Two Axis Gyro", Model = "models/acf/core/t_gyro.mdl", Angles = Angle(0, 0, 0), Position = Vector(-24, 42, 9), ComeFrom = Vector(0, 0, 50), ParentTo = "TurretH", },
    {Name = "MotorH", IdentifyAs = "Turret Ring Motor", Model = "models/acf/core/t_drive_e.mdl", Angles = Angle(0, 0, 0), Position = Vector(-36, -36, 15), ComeFrom = Vector(0, 0, 50), Scale = Vector(1.5, 1.5, 1.5), ParentTo = "TurretH", },
    {Name = "MotorV", IdentifyAs = "Turret Trun Motor", Model = "models/acf/core/t_drive_e.mdl", Angles = Angle(90, 0, 0), Position = Vector(36, 48, 18), ComeFrom = Vector(0, 0, 50), Scale = Vector(1.5, 1.5, 1.5), ParentTo = "TurretH", },

    -- Turret crew
    {Name = "Gun", IdentifyAs = "125mm Cannon", Model = "models/tankgun_new/tankgun_100mm.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 0, 50), Scale = Vector(125 / 100, 125 / 100, 125 / 100), ParentTo = "TurretV", },
    {Name = "Gunner", IdentifyAs = "Gunner", Model = "models/chairs_playerstart/sitpose.mdl", Angles = Angle(0, 0, 0), Position = Vector(-24, 18, -33), ComeFrom = Vector(0, 0, 50), Material = "sprops/sprops_grid_12x12", ParentTo = "TurretH", },
    {Name = "Commander", IdentifyAs = "Gunner", Model = "models/chairs_playerstart/sitpose.mdl", Angles = Angle(0, 0, 0), Position = Vector(24, 18, -33), ComeFrom = Vector(0, 0, 50), Material = "sprops/sprops_grid_12x12", ParentTo = "TurretH", },
    {Name = "Loader", IdentifyAs = "Loader", Model = "models/chairs_playerstart/standingpose.mdl", Angles = Angle(0, 45, 0), Position = Vector(20, -20, -33), ComeFrom = Vector(0, 0, 50), Material = "sprops/sprops_grid_12x12", ParentTo = "TurretH", },
    {Name = "Loader2", IdentifyAs = "Loader (Extra)", Model = "models/chairs_playerstart/standingpose.mdl", Angles = Angle(0, -45, 0), Position = Vector(-20, -20, -33), ComeFrom = Vector(0, 0, 50), Material = "sprops/sprops_grid_12x12", ParentTo = "TurretH", },

    -- RWS
    {Name = "TurretH2", IdentifyAs = "Turret Ring (RWS)", Model = "models/holograms/cylinder.mdl", Angles = Angle(0, 0, 0), Position = Vector(30, 30, 36), ComeFrom = Vector(0, 0, 50), Scale = Vector(3 / 12, 3 / 12, 1), ParentTo = "TurretH", },
    {Name = "TurretV2", IdentifyAs = "Turret Trun (RWS)", Model = "models/acf/core/t_trun.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, 0, 12), ComeFrom = Vector(0, 0, 50), Scale = Vector(0.15, 0.15, 0.15), ParentTo = "TurretH2", },
    {Name = "Gun2", IdentifyAs = "12.7mm Machineg Gun", Model = "models/machinegun/machinegun_20mm.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 0, 0), Scale = Vector(12.7 / 20, 12.7 / 20, 12.7 / 20), ParentTo = "TurretV2", },
    {Name = "AmmoCrate5", IdentifyAs = "Ammo Crate (12.7mmMG)", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, 0, -12), ComeFrom = Vector(0, 0, 50), Scale = Vector(1, 1, 1), Material = "phoenix_storms/future_vents", ParentTo = "TurretH2", },
}

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