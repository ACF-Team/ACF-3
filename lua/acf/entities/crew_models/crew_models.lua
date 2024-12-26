local ACF         = ACF
local CrewModels = ACF.Classes.CrewModels

CrewModels.Register("Standing", {
    Name = "Standing Crew Member",
    Description = "This posture best suits a loader.",
    Model = "models/chairs_playerstart/standingpose.mdl",
    OffsetL = Vector(0, -8, 56),
    BaseErgoScores = {
        Gunner = 0.75,
        Loader = 1,
        Driver = 0.5,
    },
    Preview = {
        FOV = 100,
    },
})

CrewModels.Register("Sitting", {
    Name = "Sitting Crew Member",
    Description = "This posture best suits a driver/gunner.",
    Model = "models/chairs_playerstart/sitpose.mdl", 
    OffsetL = Vector(0, -22, 38),
    BaseErgoScores = {
        Gunner = 1,
        Loader = 0.75,
        Driver = 1,
    },
    Preview = {
        FOV = 100,
    },
})
