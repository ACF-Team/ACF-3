local Storyboard = Ponder.API.NewStoryboard("acf", "crew", "crew-overview2")
Storyboard:WithName("Crew Extras")
Storyboard:WithModelIcon("models/chairs_playerstart/sitpose.mdl")
Storyboard:WithDescription("Learn about Efficiencies, Focus and Replacement")
Storyboard:WithIndexOrder(2)

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

local Chapter9 = Storyboard:Chapter("Efficiencies")
Chapter9:AddInstruction("Delay", {Length = 2})
Chapter9:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "Each crew member has an efficiency, which represents how effective they are at doing their tasks.\nValues in the menu for stuff like reload rate are based on an \"Ideal\" crew member, who is at 100% efficiency.\nEfficiency generally falls within 0% to 100%.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.15, 0)
})
Chapter9:AddInstruction("Delay", {Length = 8})
Chapter9:AddInstruction("HideText", {Name = "Explain"})
Chapter9:AddInstruction("Delay", {Length = 2})
Chapter9:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "Some factors that affect efficiency are the crew's posture, their global lean, their health, their acceleration and their space and their commander's efficiency.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.15, 0)
})
Chapter9:AddInstruction("Delay", {Length = 8})
Chapter9:AddInstruction("HideText", {Name = "Explain"})
Chapter9:AddInstruction("Delay", {Length = 2})
Chapter9:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "The exact details are elaborated on in the crew type specific guides.\nThe values shown in the following demonstrations are not exact.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.15, 0)
})
Chapter9:AddInstruction("Delay", {Length = 4})
Chapter9:AddInstruction("HideText", {Name = "Explain"})

local Chapter10 = Storyboard:Chapter("Model Efficiency")
Chapter10:AddInstruction("Delay", {Length = 2})
Chapter10:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "For a given crew type, their efficiency is affected by their model. For example, Loaders prefer standing.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.15, 0)
})

Chapter10:AddInstruction("MoveCameraLookAt", {Length = 2,  Angle = 45, Distance = 2000})
Chapter10:AddInstruction("Delay", {Length = 2})
Chapter10:AddInstruction("PlaceModel", {
    Name = "Crew1",
    IdentifyAs = "acf_crew (sitting)",
    Model = "models/chairs_playerstart/sitpose.mdl",
    Position = Vector(0, -20, 0),
    ComeFrom = Vector(0, 0, 32)
})
Chapter10:AddInstruction("MaterialModel", {Target = "Crew1", Material = "sprops/trans/lights/light_plastic"})
Chapter10:AddInstruction("Delay", {Length = 0.5})
Chapter10:AddInstruction("PlaceModel", {
    Name = "Crew2",
    IdentifyAs = "acf_crew (standing)",
    Model = "models/chairs_playerstart/standingpose.mdl",
    Angles = Angle(0, -90, 0),
    Position = Vector(-20, 0, 0),
    ComeFrom = Vector(0, 0, 32),
})
Chapter10:AddInstruction("MaterialModel", {Target = "Crew2", Material = "sprops/trans/lights/light_plastic"})
Chapter10:AddInstruction("Delay", {Length = 1})
Chapter10:AddInstruction("ShowText", {
    Name = "Explain",
    Text = "Model Eff: 0.75",
    Horizontal = TEXT_ALIGN_RIGHT,
    ParentTo = "Crew1"
})
Chapter10:AddInstruction("ShowText", {
    Name = "Explain2",
    Text = "Model Eff: 1.0",
    ParentTo = "Crew2"
})
Chapter10:AddInstruction("Delay", {Length = 4})
Chapter10:AddInstruction("HideText", {Name = "Explain"})
Chapter10:AddInstruction("HideText", {Name = "Explain2"})
Chapter10:AddInstruction("RemoveModel", {Name = "Crew2"})
Chapter10:AddInstruction("TransformModel", {Target = "Crew1", Position = Vector(0, 0, 0), Length = 2})

local Chapter11 = Storyboard:Chapter("Lean Efficiency")
Chapter11:AddInstruction("Delay", {Length = 2})
Chapter11:AddInstruction("MoveCameraLookAt", {Length = 2,  Angle = -90, Distance = 1500})
Chapter11:AddInstruction("Delay", {Length = 2})
Chapter11:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "Lean efficiency is determined by how upright your crew are relative to the world upwards. The more upright they are, the better.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.25, 0)
})

Chapter11:AddInstruction("Delay", {Length = 2})
Chapter11:AddInstruction("TransformModel", {Target = "Crew1", Position = Vector(0, 0, 24), Length = 2})
Chapter11:AddInstruction("Delay", {Length = 2})

Chapter11:AddInstruction("ShowText", {
    Name = "Explain",
    Text = "Lean Eff: 100%",
    ParentTo = "Crew1"
})
Chapter11:AddInstruction("Delay", {Length = 2})
Chapter11:AddInstruction("TransformModel", {Target = "Crew1", Rotation = Angle(0, 0, 22.5), Length = 1})
Chapter11:AddInstruction("Delay", {Length = 1})
Chapter11:AddInstruction("ChangeText", {
    Name = "Explain",
    Text = "Lean Eff: 50%",
})
Chapter11:AddInstruction("Delay", {Length = 1})
Chapter11:AddInstruction("TransformModel", {Target = "Crew1", Rotation = Angle(0, 0, 45), Length = 1})
Chapter11:AddInstruction("Delay", {Length = 1})
Chapter11:AddInstruction("ChangeText", {
    Name = "Explain",
    Text = "Lean Eff: 0%",
})
Chapter11:AddInstruction("Delay", {Length = 1})
Chapter11:AddInstruction("TransformModel", {Target = "Crew1", Rotation = Angle(0, 0, 0), Length = 1})
Chapter11:AddInstruction("Delay", {Length = 1})
Chapter11:AddInstruction("ChangeText", {
    Name = "Explain",
    Text = "Lean Eff: 100%",
})
Chapter11:AddInstruction("Delay", {Length = 1})
Chapter11:AddInstruction("MoveCameraLookAt", {Length = 2,  Angle = 45, Distance = 2000})
Chapter11:AddInstruction("TransformModel", {Target = "Crew1", Position = Vector(0, 0, 0), Length = 2})
Chapter11:AddInstruction("HideText", {Name = "Explain"})

local Chapter12 = Storyboard:Chapter("Health Efficiency")
Chapter12:AddInstruction("Delay", {Length = 2})
Chapter12:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "Health efficiency is based on the percentage of the crew's health.\nStay Alive.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.15, 0)
})
Chapter12:AddInstruction("Delay", {Length = 2})
Chapter12:AddInstruction("ShowText", {
    Name = "Explain2",
    Text = "Health Eff: 100%",
    ParentTo = "Crew1"
})
Chapter12:AddInstruction("Delay", {Length = 2})
Chapter12:AddInstruction("PlaceModel", {
    Name = "Gun",
    IdentifyAs = "",
    Model = "models/tankgun_new/tankgun_100mm.mdl",
    Angles = Angle(0, -90, 0),
    Position = Vector(0, 192, 36),
    ComeFrom = Vector(0, 0, 32),
})
Chapter12:AddInstruction("Delay", {Length = 2})
Chapter12:AddInstruction("SetSequence", {Name = "Gun", Sequence = "shoot"})
Chapter12:AddInstruction("MaterialModel", {Target = "Crew1", Material = "models/flesh"})
Chapter12:AddInstruction("ChangeText", {
    Name = "Explain2",
    Text = "Health Eff: 0%",
})
Chapter12:AddInstruction("Delay", {Length = 2})
Chapter12:AddInstruction("RemoveModel", {Name = "Gun"})
Chapter12:AddInstruction("HideText", {Name = "Explain"})
Chapter12:AddInstruction("HideText", {Name = "Explain2"})
Chapter12:AddInstruction("MaterialModel", {Target = "Crew1", Material = "sprops/trans/lights/light_plastic"})
Chapter12:AddInstruction("Delay", {Length = 2})

local Chapter13 = Storyboard:Chapter("Acceleration Efficiency")
Chapter13:AddInstruction("Delay", {Length = 2})
Chapter13:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "Acceleration efficiency is based on the crew's acceleration.\nDon't drive into a wall.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.15, 0)
})
Chapter13:AddInstruction("ShowText", {
    Name = "Explain2",
    Text = "Accel Eff: 100%",
    ParentTo = "Crew1"
})
Chapter13:AddInstruction("Delay", {Length = 2})
Chapter13:AddInstruction("TransformModel", {Target = "Crew1", Rotation = Angle(0, 360 * 10, 0), Length = 2})
Chapter13:AddInstruction("Delay", {Length = 1})
Chapter13:AddInstruction("ChangeText", {
    Name = "Explain2",
    Text = "Accel Eff: 50%",
})
Chapter13:AddInstruction("Delay", {Length = 1})
Chapter13:AddInstruction("TransformModel", {Target = "Crew1", Rotation = Angle(0, 360 * 20, 0), Length = 2})
Chapter13:AddInstruction("Delay", {Length = 1})
Chapter13:AddInstruction("ChangeText", {
    Name = "Explain2",
    Text = "Accel Eff: 0%",
})
Chapter13:AddInstruction("Delay", {Length = 1})
Chapter13:AddInstruction("TransformModel", {Target = "Crew1", Rotation = Angle(0, 360 * 100, 0), Length = 2})
Chapter13:AddInstruction("Delay", {Length = 1})
Chapter13:AddInstruction("MaterialModel", {Target = "Crew1", Material = "models/flesh"})
Chapter13:AddInstruction("Delay", {Length = 2})
Chapter13:AddInstruction("MaterialModel", {Target = "Crew1", Material = "sprops/trans/lights/light_plastic"})
Chapter13:AddInstruction("HideText", {Name = "Explain"})
Chapter13:AddInstruction("HideText", {Name = "Explain2"})

local Chapter14 = Storyboard:Chapter("Space Efficiency")
Chapter14:AddInstruction("Delay", {Length = 2})
Chapter14:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "Space efficiency is based on the crew's space.\nDon't put them in a box.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.15, 0)
})
Chapter14:AddInstruction("PlaceModel", {
    Name = "Box",
    IdentifyAs = "",
    Model = "models/hunter/blocks/cube025x025x025.mdl",
    Angles = Angle(0, 0, 0),
    Position = Vector(24, 0, 36),
    Scale = Vector(6, 6, 6),
    ComeFrom = Vector(0, 0, 0),
})
Chapter14:AddInstruction("MaterialModel", {Target = "Box", Material = "models/debug/debugwhite"})
Chapter14:AddInstruction("ColorModel", {Target = "Box", Color = Color(255, 0, 0, 150)})
Chapter14:AddInstruction("ShowText", {
    Name = "Explain2",
    Text = "Space Eff: 100%",
    ParentTo = "Crew1"
})
Chapter14:AddInstruction("Delay", {Length = 2})
Chapter14:AddInstruction("TransformModel", {Target = "Box", Scale = Vector(4, 4, 4), Length = 4})
Chapter14:AddInstruction("Delay", {Length = 2})
Chapter14:AddInstruction("ChangeText", {
    Name = "Explain2",
    Text = "Space Eff: 50%",
})
Chapter14:AddInstruction("Delay", {Length = 2})
Chapter14:AddInstruction("ChangeText", {
    Name = "Explain2",
    Text = "Space Eff: 0%",
})
Chapter14:AddInstruction("Delay", {Length = 2})
Chapter14:AddInstruction("HideText", {Name = "Explain"})
Chapter14:AddInstruction("HideText", {Name = "Explain2"})
Chapter14:AddInstruction("RemoveModel", {Name = "Box"})

local Chapter15 = Storyboard:Chapter("Commander Efficiency")
Chapter15:AddInstruction("Delay", {Length = 2})
Chapter15:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "Commander efficiency is based on the commander's efficiency.\nIf the commander is gone, the other crews need to take over.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.15, 0)
})
Chapter15:AddInstruction("ShowText", {
    Name = "Explain2",
    Text = "Crew Eff: 1.0",
    Horizontal = TEXT_ALIGN_RIGHT,
    ParentTo = "Crew1"
})
Chapter15:AddInstruction("PlaceModel", {
    Name = "Commander",
    IdentifyAs = "",
    Model = "models/chairs_playerstart/sitpose.mdl",
    Angles = Angle(0, 0, 0),
    Position = Vector(0, 36, 0),
    ComeFrom = Vector(0, 0, 32),
})
Chapter15:AddInstruction("MaterialModel", {Target = "Commander", Material = "sprops/trans/lights/light_plastic"})
Chapter15:AddInstruction("ShowText", {
    Name = "Explain3",
    Text = "Commander Eff: 100%",
    ParentTo = "Commander"
})
Chapter15:AddInstruction("Delay", {Length = 2})
Chapter15:AddInstruction("RemoveModel", {Name = "Commander"})
Chapter15:AddInstruction("ChangeText", {
    Name = "Explain3",
    Text = "Commander Eff: 0%",
})
Chapter15:AddInstruction("HideText", {Name = "Explain3"})
Chapter15:AddInstruction("ChangeText", {
    Name = "Explain2",
    Text = "Crew Eff: 75%",
})
Chapter15:AddInstruction("Delay", {Length = 2})
Chapter15:AddInstruction("HideText", {Name = "Explain"})
Chapter15:AddInstruction("HideText", {Name = "Explain2"})

local Chapter16 = Storyboard:Chapter("Focus")
Chapter16:AddInstruction("Delay", {Length = 2})
Chapter16:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "A crew member will spread their focus across the entities they are linked to.\nFor example, a loader linked to two guns will reload both guns at half the speed.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.15, 0)
})
Chapter16:AddInstruction("PlaceModel", {
    Name = "Gun",
    IdentifyAs = "",
    Model = "models/tankgun_new/tankgun_100mm.mdl",
    Angles = Angle(0, 90, 0),
    Position = Vector(24, 0, 36),
    ComeFrom = Vector(0, 0, 32),
})
Chapter16:AddInstruction("PlaceModel", {
    Name = "Gun2",
    IdentifyAs = "",
    Model = "models/tankgun_new/tankgun_100mm.mdl",
    Angles = Angle(0, 90, 0),
    Position = Vector(-24, 0, 36),
    ComeFrom = Vector(0, 0, 32),
})
Chapter16:AddInstruction("Delay", {Length = 2})
Chapter16:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")})
local LT1 = Chapter16:AddInstruction("ACF Menu", {
    Children = {"Crew1"},
    Target = "Gun",
    Length = 2,
    Easing = math.ease.InOutQuad
})
Chapter16:AddInstruction("HideToolgun", {Time = LT1})
Chapter16:AddInstruction("Delay", {Length = 2})
Chapter16:AddInstruction("ShowText", {
    Name = "Explain2",
    Text = "Focus: 100%",
    ParentTo = "Crew1"
})
Chapter16:AddInstruction("ShowText", {
    Name = "Explain3",
    Text = "Reload: 10s",
    Horizontal = TEXT_ALIGN_RIGHT,
    ParentTo = "Gun"
})
Chapter16:AddInstruction("Delay", {Length = 2})
Chapter16:AddInstruction("ShowToolgun", {Tool = language.GetPhrase("tool.acf_menu.menu_name")})
local LT1 = Chapter16:AddInstruction("ACF Menu", {
    Children = {"Crew1"},
    Target = "Gun2",
    Length = 2,
    Easing = math.ease.InOutQuad
})
Chapter16:AddInstruction("HideToolgun", {Time = LT1})
Chapter16:AddInstruction("Delay", {Length = 2})
Chapter16:AddInstruction("ChangeText", {
    Name = "Explain2",
    Text = "Focus: 50%",
})
Chapter16:AddInstruction("ChangeText", {
    Name = "Explain3",
    Text = "Reload: 20s",
})
Chapter16:AddInstruction("ShowText", {
    Name = "Explain4",
    Text = "Reload: 20s",
    ParentTo = "Gun2"
})
Chapter16:AddInstruction("Delay", {Length = 2})
Chapter16:AddInstruction("HideText", {Name = "Explain"})
Chapter16:AddInstruction("HideText", {Name = "Explain2"})
Chapter16:AddInstruction("HideText", {Name = "Explain3"})
Chapter16:AddInstruction("HideText", {Name = "Explain4"})
Chapter16:AddInstruction("RemoveModel", {Name = "Gun"})
Chapter16:AddInstruction("RemoveModel", {Name = "Gun2"})
Chapter16:AddInstruction("RemoveModel", {Name = "Crew1"})

local Chapter17 = Storyboard:Chapter("Crew Replacement")
Chapter17:AddInstruction("Delay", {Length = 2})
local T1 = Chapter17:AddInstruction("PlaceModels", {
    Length = 2,
    Models = Tank
})
Chapter17:AddDelay(T1 + 1)

Chapter17:AddInstruction("Delay", {Length = 2})
Chapter17:AddInstruction("ShowText", {
    Name = "Explain",
    Dimension = "2D",
    Text = "If a crew member is killed, the other crew members will take over their tasks.",
    Horizontal = TEXT_ALIGN_CENTER,
    PositionRelativeToScreen = true,
    Position = Vector(0.5, 0.15, 0)
})
Chapter17:AddInstruction("Delay", {Length = 2})
Chapter17:AddInstruction("PlaceModel", {
    Name = "Gun3",
    IdentifyAs = "",
    Model = "models/tankgun_new/tankgun_100mm.mdl",
    Angles = Angle(90, 0, 0),
    Scale = Vector(0.5, 0.5, 0.5),
    Position = Vector(0, 0, 144),
    ComeFrom = Vector(0, 0, 32),
    ParentTo = "Gunner"
})
Chapter17:AddInstruction("Delay", {Length = 2})
Chapter17:AddInstruction("SetSequence", {Name = "Gun3", Sequence = "shoot"})
Chapter17:AddInstruction("MaterialModel", {Target = "Gunner", Material = "models/flesh"})
Chapter17:AddInstruction("Delay", {Length = 2})
Chapter17:AddInstruction("MaterialModel", {Target = "Commander", Material = "models/flesh"})
Chapter17:AddInstruction("MaterialModel", {Target = "Gunner", Material = "sprops/trans/lights/light_plastic"})
Chapter17:AddInstruction("Delay", {Length = 2})
Chapter17:AddInstruction("SetSequence", {Name = "Gun3", Sequence = "shoot"})
Chapter17:AddInstruction("MaterialModel", {Target = "Gunner", Material = "models/flesh"})
Chapter17:AddInstruction("Delay", {Length = 2})
Chapter17:AddInstruction("MaterialModel", {Target = "Loader", Material = "models/flesh"})
Chapter17:AddInstruction("MaterialModel", {Target = "Gunner", Material = "sprops/trans/lights/light_plastic"})
Chapter17:AddInstruction("Delay", {Length = 2})
Chapter17:AddInstruction("RemoveModels", {Models = Tank})
Chapter17:AddInstruction("RemoveModel", {Name = "Gun3"})
Chapter17:AddInstruction("HideText", {Name = "Explain"})
Chapter17:AddInstruction("Delay", {Length = 2})