--[[
Most of the crew model specific properties and logic is specified here.
]]--

local ACF         = ACF
local CrewModels = ACF.Classes.CrewModels

CrewModels.Register("Standing", {
    Name = "Standing Crew Member",
    Description = "This posture best suits a loader.",
    Model = "models/chairs_playerstart/standingpose.mdl",
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
})

CrewModels.Register("Sitting", {
    Name = "Sitting Crew Member",
    Description = "This posture best suits a driver/gunner.",
    Model = "models/chairs_playerstart/sitpose.mdl",
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
})
