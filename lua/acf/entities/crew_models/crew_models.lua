--[[
Most of the crew model specific properties and logic is specified here.
]]--

local ACF     = ACF
local Classes = ACF.Classes

Classes.DefineClass("ACF.CrewModels.BaseCrewModel", function() end)

Classes.DefineClass("ACF.CrewModels.Standing", "ACF.CrewModels.BaseCrewModel", function()
    CLASS.Name = "Standing Crew Member"
    CLASS.Description = "This posture best suits a loader."
    CLASS.Model = "models/chairs_playerstart/standingpose.mdl"
    CLASS.SuppressLoad = true
    CLASS.ScanOffsetL = Vector(0, -8, 56-6)
    CLASS.MouthOffsetL = Vector(0, -7, 66)
    CLASS.BaseErgoScores = {
        Gunner = 0.85,
        Loader = 1,
        Driver = 0.5,
        Commander = 1,
        Pilot = 0.1,
    }
    CLASS.Preview = {
        FOV = 100,
    }
    CLASS.Animation = {
        Model = "models/player/dod_german.mdl",
        Sequence = "walk_all",
    }
end)

Classes.DefineClass("ACF.CrewModels.Sitting", "ACF.CrewModels.BaseCrewModel", function()
    CLASS.Name = "Sitting Crew Member"
    CLASS.Description = "This posture best suits a driver/gunner."
    CLASS.Model = "models/chairs_playerstart/sitpose.mdl"
    CLASS.SuppressLoad = true
    CLASS.ScanOffsetL = Vector(0, -22, 38-6)
    CLASS.MouthOffsetL = Vector(0, -18, 46)
    CLASS.BaseErgoScores = {
        Gunner = 1,
        Loader = 0.85,
        Driver = 1,
        Commander = 1,
        Pilot = 1,
    }
    CLASS.Preview = {
        FOV = 100,
    }
    CLASS.Animation = {
        Model = "models/player/dod_german.mdl",
        Sequence = "sit_rollercoaster",
    }
end)

Classes.DefineClass("ACF.CrewModels.SittingLarge", "ACF.CrewModels.BaseCrewModel", function()
    CLASS.Name = "Sitting Large Crew Member"
    CLASS.Description = "This posture best suits a driver/gunner in larger vehicles."
    CLASS.Model = "models/acf/core/c_seated_l.mdl"
    CLASS.ScanOffsetL = Vector(0, -10, 35)
    CLASS.MouthOffsetL = Vector(0, -5, 45)
    CLASS.BaseErgoScores = {
        Gunner = 1,
        Loader = 0.85,
        Driver = 1,
        Commander = 1,
        Pilot = 1,
    }
    CLASS.Preview = {
        FOV = 100,
    }
    CLASS.Animation = {
        Model = "models/player/dod_german.mdl",
        Sequence = "sit_rollercoaster",
    }
end)

Classes.DefineClass("ACF.CrewModels.SittingMedium", "ACF.CrewModels.BaseCrewModel", function()
    CLASS.Name = "Sitting Medium Crew Member"
    CLASS.Description = "This posture best suits a driver/gunner in medium vehicles."
    CLASS.Model = "models/acf/core/c_seated_m.mdl"
    CLASS.ScanOffsetL = Vector(0, -13, 25)
    CLASS.MouthOffsetL = Vector(0, -8, 37)
    CLASS.BaseErgoScores = {
        Gunner = 0.85,
        Loader = 0.65,
        Driver = 1,
        Commander = 1,
        Pilot = 1,
    }
    CLASS.Preview = {
        FOV = 100,
    }
    CLASS.Animation = {
        Model = "models/player/dod_german.mdl",
        Sequence = "sit_rollercoaster",
    }
end)

Classes.DefineClass("ACF.CrewModels.SittingSmall", "ACF.CrewModels.BaseCrewModel", function()
    CLASS.Name = "Sitting Small Crew Member"
    CLASS.Description = "This posture best suits a driver/gunner in small vehicles."
    CLASS.Model = "models/acf/core/c_seated_s.mdl"
    CLASS.ScanOffsetL = Vector(0, -18, 17)
    CLASS.MouthOffsetL = Vector(0, -16, 25)
    CLASS.BaseErgoScores = {
        Gunner = 0.65,
        Loader = 0.45,
        Driver = 1,
        Commander = 1,
        Pilot = 1,
    }
    CLASS.Preview = {
        FOV = 100,
    }
    CLASS.Animation = {
        Model = "models/player/dod_german.mdl",
        Sequence = "sit_rollercoaster",
    }
end)

Classes.DefineClass("ACF.CrewModels.StandingLarge", "ACF.CrewModels.BaseCrewModel", function()
    CLASS.Name = "Standing Large Crew Member"
    CLASS.Description = "This posture best suits a driver/gunner in large vehicles."
    CLASS.Model = "models/acf/core/c_standing_l.mdl"
    CLASS.ScanOffsetL = Vector(0, -7, 52)
    CLASS.MouthOffsetL = Vector(0, -4, 64)
    CLASS.BaseErgoScores = {
        Gunner = 0.85,
        Loader = 1,
        Driver = 0.1,
        Commander = 1,
        Pilot = 0.1,
    }
    CLASS.Preview = {
        FOV = 100,
    }
    CLASS.Animation = {
        Model = "models/player/dod_german.mdl",
        Sequence = "walk_camera",
    }
end)

Classes.DefineClass("ACF.CrewModels.StandingMedium", "ACF.CrewModels.BaseCrewModel", function()
    CLASS.Name = "Standing Medium Crew Member"
    CLASS.Description = "This posture best suits a driver/gunner in medium vehicles."
    CLASS.Model = "models/acf/core/c_standing_m.mdl"
    CLASS.ScanOffsetL = Vector(0, -6, 46)
    CLASS.MouthOffsetL = Vector(0, 0, 58)
    CLASS.BaseErgoScores = {
        Gunner = 0.75,
        Loader = 0.85,
        Driver = 0.1,
        Commander = 1,
        Pilot = 0.1,
    }
    CLASS.Preview = {
        FOV = 100,
    }
    CLASS.Animation = {
        Model = "models/player/dod_german.mdl",
        Sequence = "walk_camera",
    }
end)

Classes.DefineClass("ACF.CrewModels.StandingSmall", "ACF.CrewModels.BaseCrewModel", function()
    CLASS.Name = "Standing Small Crew Member"
    CLASS.Description = "This posture best suits a driver/gunner in small vehicles."
    CLASS.Model = "models/acf/core/c_standing_s.mdl"
    CLASS.ScanOffsetL = Vector(0, -5, 41)
    CLASS.MouthOffsetL = Vector(0, 2, 52)
    CLASS.BaseErgoScores = {
        Gunner = 0.65,
        Loader = 0.75,
        Driver = 0.1,
        Commander = 1,
        Pilot = 0.1,
    }
    CLASS.Preview = {
        FOV = 100,
    }
    CLASS.Animation = {
        Model = "models/player/dod_german.mdl",
        Sequence = "walk_camera",
    }
end)