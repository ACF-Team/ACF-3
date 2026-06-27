local ACF     = ACF
local Classes = ACF.Classes

Classes.DefineClass("ACF.CrewPoses.BaseCrewPose", function() end)

Classes.DefineClass("ACF.CrewPoses.WalkCamera", "ACF.CrewPoses.BaseCrewPose", function()
	CLASS.Name = "Camera Walk"
	CLASS.Position = Vector(0, -6, 1)
	CLASS.Angle = Angle(0, 90, 0)
end)

Classes.DefineClass("ACF.CrewPoses.WalkDual", "ACF.CrewPoses.BaseCrewPose", function()
	CLASS.Name = "Dual Walk"
	CLASS.Position = Vector(0, -6, 1)
	CLASS.Angle = Angle(0, 90, 0)
end)

Classes.DefineClass("ACF.CrewPoses.WalkAll", "ACF.CrewPoses.BaseCrewPose", function()
	CLASS.Name = "All Walk"
	CLASS.Position = Vector(0, -6, 1)
	CLASS.Angle = Angle(0, 90, 0)
end)

Classes.DefineClass("ACF.CrewPoses.SitRollercoaster", "ACF.CrewPoses.BaseCrewPose", function()
	CLASS.Name = "Rollercoaster Sit"
	CLASS.Position = Vector(0, -20, 20)
	CLASS.Angle = Angle(0, 90, 0)
end)

Classes.DefineClass("ACF.CrewPoses.SitCamera", "ACF.CrewPoses.BaseCrewPose", function()
	CLASS.Name = "Camera Sit"
	CLASS.Position = Vector(0, -20, 16)
	CLASS.Angle = Angle(0, 90, 0)
end)