--[[
Most of the crew model specific properties and logic is specified here.
]]--

local ACF         = ACF
local CrewModels = ACF.Classes.CrewModels

-- Deprecated
CrewModels.Register("Standing", {
    Name = "Standing Crew Member",
    Description = "This posture best suits a loader.",
    Model = "models/chairs_playerstart/standingpose.mdl",
    SuppressLoad = true,
    ScanOffsetL = Vector(0, -8, 56-6),
    MouthOffsetL = Vector(0, -7, 66),
    BaseErgoScores = {
        Gunner = 0.85,
        Loader = 1,
        Driver = 0.5,
        Commander = 1,
        Pilot = 0.1,
    },
    Preview = {
        FOV = 100,
    },
    Animation = {
        Model = "models/player/dod_german.mdl",
        Sequence = "walk_all",
    },
})

CrewModels.Register("Sitting", {
    Name = "Sitting Crew Member",
    Description = "This posture best suits a driver/gunner.",
    Model = "models/chairs_playerstart/sitpose.mdl",
    SuppressLoad = true,
    ScanOffsetL = Vector(0, -22, 38-6),
    MouthOffsetL = Vector(0, -18, 46),
    BaseErgoScores = {
        Gunner = 1,
        Loader = 0.85,
        Driver = 1,
        Commander = 1,
        Pilot = 1,
    },
    Preview = {
        FOV = 100,
    },
    Animation = {
        Model = "models/player/dod_german.mdl",
        Sequence = "sit_rollercoaster",
    },
})

-- New
CrewModels.Register("Sitting_Large", {
    Name = "Sitting Large Crew Member",
    Description = "This posture best suits a driver/gunner in larger vehicles.",
    Model = "models/acf/core/c_seated_l.mdl",
    ScanOffsetL = Vector(0, -10, 35),
    MouthOffsetL = Vector(0, -5, 45),
    BaseErgoScores = {
        Gunner = 1,
        Loader = 0.85,
        Driver = 1,
        Commander = 1,
        Pilot = 1,
    },
    Preview = {
        FOV = 100,
    },
    Animation = {
        Model = "models/player/dod_german.mdl",
        Sequence = "sit_rollercoaster",
    },
})

CrewModels.Register("Sitting_Medium", {
    Name = "Sitting Medium Crew Member",
    Description = "This posture best suits a driver/gunner in medium vehicles.",
    Model = "models/acf/core/c_seated_m.mdl",
    ScanOffsetL = Vector(0, -13, 25),
    MouthOffsetL = Vector(0, -8, 37),
    BaseErgoScores = {
        Gunner = 0.85,
        Loader = 0.65,
        Driver = 1,
        Commander = 1,
        Pilot = 1,
    },
    Preview = {
        FOV = 100,
    },
    Animation = {
        Model = "models/player/dod_german.mdl",
        Sequence = "sit_rollercoaster",
    },
})

CrewModels.Register("Sitting_Small", {
    Name = "Sitting Small Crew Member",
    Description = "This posture best suits a driver/gunner in small vehicles.",
    Model = "models/acf/core/c_seated_s.mdl",
    ScanOffsetL = Vector(0, -16, 25),
    MouthOffsetL = Vector(0, -18, 17),
    BaseErgoScores = {
        Gunner = 0.65,
        Loader = 0.45,
        Driver = 1,
        Commander = 1,
        Pilot = 1,
    },
    Preview = {
        FOV = 100,
    },
    Animation = {
        Model = "models/player/dod_german.mdl",
        Sequence = "sit_rollercoaster",
    },
})

CrewModels.Register("Standing_Large", {
    Name = "Standing Large Crew Member",
    Description = "This posture best suits a driver/gunner in large vehicles.",
    Model = "models/acf/core/c_standing_l.mdl",
    ScanOffsetL = Vector(0, -7, 52),
    MouthOffsetL = Vector(0, -4, 64),
    BaseErgoScores = {
        Gunner = 0.85,
        Loader = 1,
        Driver = 0.1,
        Commander = 1,
        Pilot = 0.1,
    },
    Preview = {
        FOV = 100,
    },
    Animation = {
        Model = "models/player/dod_german.mdl",
        Sequence = "walk_camera",
    },
})

CrewModels.Register("Standing_Medium", {
    Name = "Standing Medium Crew Member",
    Description = "This posture best suits a driver/gunner in medium vehicles.",
    Model = "models/acf/core/c_standing_m.mdl",
    ScanOffsetL = Vector(0, -6, 46),
    MouthOffsetL = Vector(0, 0, 58),
    BaseErgoScores = {
        Gunner = 0.75,
        Loader = 0.85,
        Driver = 0.1,
        Commander = 1,
        Pilot = 0.1,
    },
    Preview = {
        FOV = 100,
    },
    Animation = {
        Model = "models/player/dod_german.mdl",
        Sequence = "walk_camera",
    },
})

CrewModels.Register("Standing_Small", {
    Name = "Standing Small Crew Member",
    Description = "This posture best suits a driver/gunner in small vehicles.",
    Model = "models/acf/core/c_standing_s.mdl",
    ScanOffsetL = Vector(0, -5, 41),
    MouthOffsetL = Vector(0, 2, 52),
    BaseErgoScores = {
        Gunner = 0.65,
        Loader = 0.75,
        Driver = 0.1,
        Commander = 1,
        Pilot = 0.1,
    },
    Preview = {
        FOV = 100,
    },
    Animation = {
        Model = "models/player/dod_german.mdl",
        Sequence = "walk_camera",
    },
})