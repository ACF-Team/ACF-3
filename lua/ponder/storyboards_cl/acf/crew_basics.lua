local Storyboard = Ponder.API.NewStoryboard("acf", "crew", "crew-overview")
Storyboard:WithName("Crew Basics")
Storyboard:WithModelIcon("models/chairs_playerstart/sitpose.mdl")
Storyboard:WithDescription("Learn the basics of crew")
Storyboard:WithIndexOrder(1)

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
    Position = Vector(0.5, 0.25, 0)
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

local Chapter3 = Storyboard:Chapter("Types")
Chapter3:AddInstruction("MoveCameraLookAt", {Length = 2, Distance = 2000})
Chapter3:AddInstruction("Delay", {Length = 1})

-- Import tank skeleton
local Hull = {
    {Name = "0", IdentifyAs = "0", Model = "models/sprops/cuboids/height06/size_1/cube_6x6x6.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 0, 50), },
    {Name = "1", IdentifyAs = "1", Model = "models/hunter/plates/plate1x1.mdl", Angles = Angle(90, 180, 0), Position = Vector(-45.97, 71.17, 22.78), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "2", IdentifyAs = "2", Model = "models/hunter/plates/plate1x2.mdl", Angles = Angle(90, 180, 0), Position = Vector(-45.95, 0, 22.78), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "3", IdentifyAs = "3", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, -90, 0), Position = Vector(35.43, 79.76, 14.05), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "4", IdentifyAs = "4", Model = "models/hunter/plates/plate1x2.mdl", Angles = Angle(0, -90, 0), Position = Vector(0, 71.17, 45), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "5", IdentifyAs = "5", Model = "models/chairs_playerstart/sitpose.mdl", Angles = Angle(0, 0, 30), Position = Vector(0, 96.13, 2.82), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "6", IdentifyAs = "6", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, -90, 45), Position = Vector(31.24, -89.83, 30.29), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "7", IdentifyAs = "7", Model = "models/hunter/plates/platehole2x2.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, 0, 45), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "8", IdentifyAs = "8", Model = "models/hunter/plates/plate2x5.mdl", Angles = Angle(0, 0, 0), Position = Vector(-0.02, -35.59, 0.55), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "9", IdentifyAs = "9", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, -90, -45), Position = Vector(-31.28, -89.83, 30.29), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "10", IdentifyAs = "10", Model = "models/hunter/plates/plate05x2.mdl", Angles = Angle(0, 90, 0), Position = Vector(-0.02, 94.9, 0.55), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "11", IdentifyAs = "11", Model = "models/hunter/plates/plate025x1.mdl", Angles = Angle(0, -90, 90), Position = Vector(-45.95, -148.28, 22.78), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "12", IdentifyAs = "12", Model = "models/hunter/triangles/1x05x1.mdl", Angles = Angle(0, 0, 0), Position = Vector(23.71, 130.49, 34.64), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "13", IdentifyAs = "13", Model = "models/hunter/plates/plate025x1.mdl", Angles = Angle(0, -90, 90), Position = Vector(-45.97, 100.83, 22.78), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "14", IdentifyAs = "14", Model = "models/engines/v12l.mdl", Angles = Angle(0, 90, -45), Position = Vector(-3.56, -84.92, 2.57), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "15", IdentifyAs = "15", Model = "models/hunter/plates/plate1x2.mdl", Angles = Angle(90, 0, 0), Position = Vector(45.91, -94.9, 22.78), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "16", IdentifyAs = "16", Model = "models/hunter/plates/plate1x2.mdl", Angles = Angle(90, -90, 0), Position = Vector(0.01, -152.71, 22.8), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "17", IdentifyAs = "17", Model = "models/hunter/triangles/1x05x1.mdl", Angles = Angle(0, 180, -180), Position = Vector(-23.74, 130.49, 10.91), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "18", IdentifyAs = "18", Model = "models/hunter/plates/plate1x2.mdl", Angles = Angle(90, -90, 0), Position = Vector(0.01, -48.94, 22.79), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "19", IdentifyAs = "19", Model = "models/hunter/plates/plate025x2.mdl", Angles = Angle(0, 90, 0), Position = Vector(0.01, -148.27, 45.02), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "20", IdentifyAs = "20", Model = "models/hunter/plates/plate025x1.mdl", Angles = Angle(0, -90, -90), Position = Vector(45.91, -148.28, 22.78), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "21", IdentifyAs = "21", Model = "models/holograms/hq_rcube.mdl", Angles = Angle(0, -90, 0), Position = Vector(-35.47, 79.76, 14.05), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "22", IdentifyAs = "22", Model = "models/acf/core/t_ring.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, 0, 45), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "23", IdentifyAs = "23", Model = "models/hunter/plates/plate.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, 0, 45), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "24", IdentifyAs = "24", Model = "models/hunter/plates/plate1x2.mdl", Angles = Angle(0, -90, 0), Position = Vector(0, -71.17, 48.01), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "25", IdentifyAs = "25", Model = "models/hunter/plates/plate025x2.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, 100.83, 45), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "26", IdentifyAs = "26", Model = "models/engines/v12l.mdl", Angles = Angle(0, 90, 45), Position = Vector(3.52, -84.92, 2.57), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "27", IdentifyAs = "27", Model = "models/engines/transaxial_l.mdl", Angles = Angle(0.02, 90, 0), Position = Vector(-0.02, -143.2, 1.83), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "28", IdentifyAs = "28", Model = "models/hunter/triangles/1x05x1.mdl", Angles = Angle(0, 0, 0), Position = Vector(-23.74, 130.49, 34.64), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "29", IdentifyAs = "29", Model = "models/hunter/plates/plate1x2.mdl", Angles = Angle(90, 0, 0), Position = Vector(45.91, 0, 22.78), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "30", IdentifyAs = "30", Model = "models/hunter/triangles/1x05x1.mdl", Angles = Angle(0, 180, -180), Position = Vector(23.71, 130.49, 10.91), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "31", IdentifyAs = "31", Model = "models/hunter/plates/plate2x2.mdl", Angles = Angle(0, 180, 0), Position = Vector(0.01, -94.89, 45.02), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "32", IdentifyAs = "32", Model = "models/hunter/plates/plate1x1.mdl", Angles = Angle(90, 180, 0), Position = Vector(45.93, 71.17, 22.78), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "33", IdentifyAs = "33", Model = "models/hunter/plates/plate1x2.mdl", Angles = Angle(90, 90, 0), Position = Vector(0, 48.95, 22.78), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "34", IdentifyAs = "34", Model = "models/hunter/plates/plate1x2.mdl", Angles = Angle(90, 180, 0), Position = Vector(-45.95, -94.9, 22.78), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
    {Name = "35", IdentifyAs = "35", Model = "models/hunter/plates/plate025x1.mdl", Angles = Angle(0, -90, -90), Position = Vector(45.93, 100.83, 22.78), ComeFrom = Vector(0, 0, 50), ParentTo = "0", },
}

local Turret = {
    {Name = "36", IdentifyAs = "", Model = "models/hunter/plates/plate.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 0), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "37", IdentifyAs = "", Model = "models/holograms/cylinder.mdl", Angles = Angle(0, 0, 0), Position = Vector(29.59, -29.59, 34.09), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "38", IdentifyAs = "", Model = "models/hunter/plates/plate.mdl", Angles = Angle(0, 0, 0), Position = Vector(29.59, -29.59, 34.09), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "39", IdentifyAs = "", Model = "models/acf/core/t_trun.mdl", Angles = Angle(0, 0, 0), Position = Vector(29.59, -29.59, 49.05), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "40", IdentifyAs = "", Model = "models/hunter/plates/plate.mdl", Angles = Angle(0, 0, 0), Position = Vector(29.59, -29.59, 49.05), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "41", IdentifyAs = "", Model = "models/machinegun/machinegun_20mm.mdl", Angles = Angle(0, 0, 0), Position = Vector(29.59, -29.59, 49.05), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "42", IdentifyAs = "", Model = "models/hunter/plates/plate1x2.mdl", Angles = Angle(0, 180, 0), Position = Vector(-71.17, 0, 3), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "43", IdentifyAs = "", Model = "models/hunter/triangles/075x075.mdl", Angles = Angle(0, 180, 90), Position = Vector(59.31, -29.41, 13.37), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "44", IdentifyAs = "", Model = "models/hunter/plates/plate075x2.mdl", Angles = Angle(90, 0, 0), Position = Vector(-93.4, 0, 13.37), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "45", IdentifyAs = "", Model = "models/hunter/plates/plate1x2.mdl", Angles = Angle(0, 180, 0), Position = Vector(-71.17, 0, 35.59), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "46", IdentifyAs = "", Model = "models/acf/core/t_drive_e.mdl", Angles = Angle(90, 89.97, 0), Position = Vector(37.83, -33.47, 11.13), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "47", IdentifyAs = "", Model = "models/hunter/plates/plate075x3.mdl", Angles = Angle(90, -90, 0), Position = Vector(-23.72, -45.91, 13.37), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "48", IdentifyAs = "", Model = "models/chairs_playerstart/sitpose.mdl", Angles = Angle(0, -89.99, 0), Position = Vector(19.89, 29.92, -30.91), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "49", IdentifyAs = "", Model = "models/chairs_playerstart/sitpose.mdl", Angles = Angle(0, -89.99, 0), Position = Vector(-7.11, 17.92, -30.91), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "50", IdentifyAs = "", Model = "models/acf/core/t_drive_e.mdl", Angles = Angle(0, 90.02, 0), Position = Vector(-40.82, -37.82, 15.51), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "51", IdentifyAs = "", Model = "models/acf/core/t_trun.mdl", Angles = Angle(0, -0.02, 0), Position = Vector(45.95, 0, 19.3), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "52", IdentifyAs = "", Model = "models/hunter/plates/plate.mdl", Angles = Angle(0, -0.02, 0), Position = Vector(45.95, 0, 19.3), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "53", IdentifyAs = "", Model = "models/tankgun_new/tankgun_100mm.mdl", Angles = Angle(0, 0, 0), Position = Vector(45.95, 0, 19.3), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "54", IdentifyAs = "", Model = "models/hunter/plates/plate075x3.mdl", Angles = Angle(90, 90, 0), Position = Vector(-23.72, 45.95, 13.37), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "55", IdentifyAs = "", Model = "models/hunter/plates/platehole2x2.mdl", Angles = Angle(0, 0, 0), Position = Vector(0, 0, 3), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "56", IdentifyAs = "", Model = "models/acf/core/t_gyro.mdl", Angles = Angle(0, 90, -90), Position = Vector(43.48, 26.86, 10.48), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "57", IdentifyAs = "", Model = "models/hunter/tubes/circle2x2.mdl", Angles = Angle(0, 180, 0), Position = Vector(0, 0, -42), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "58", IdentifyAs = "", Model = "models/holograms/hq_rcube_thin.mdl", Angles = Angle(0, 90, 0), Position = Vector(-71.17, 0, 19.5), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "59", IdentifyAs = "", Model = "models/hunter/plates/plate2x2.mdl", Angles = Angle(0, 90, 0), Position = Vector(0, 0, 35.59), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "60", IdentifyAs = "", Model = "models/hunter/plates/plate075x2.mdl", Angles = Angle(90, 0, 0), Position = Vector(45.95, 0, 13.37), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "61", IdentifyAs = "", Model = "models/chairs_playerstart/standingpose.mdl", Angles = Angle(0, -44.98, 0), Position = Vector(-20.66, -21.62, -40.37), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "62", IdentifyAs = "", Model = "models/hunter/triangles/075x075.mdl", Angles = Angle(90, -90, 0), Position = Vector(59.31, 29.45, 13.37), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
    {Name = "63", IdentifyAs = "", Model = "models/acf/core/t_computer.mdl", Angles = Angle(0, -90, 0), Position = Vector(35.51, 38.65, 10.39), ComeFrom = Vector(0, 0, 50), ParentTo = "22", },
}

local T1 = Chapter3:AddInstruction("PlaceModels", {
    Length = 2,
    Models = Hull
})

Chapter3:AddDelay(T1 + 1)

local T2 = Chapter3:AddInstruction("PlaceModels", {
    Length = 2,
    Models = Turret,
})

Chapter3:AddDelay(T2 + 1)

-- Chapter3:AddInstruction("TransformModel", {Target = "0", Rotation = Angle(0, -90, 0), Length = 1.0})

-- Chapter3:AddInstruction("Delay", {Length = 1})

Chapter3:AddInstruction("TransformModel", {Target = "22", Rotation = Angle(0, 360, 0), Length = 1.0})

Chapter3:AddInstruction("Delay", {Length = 1})