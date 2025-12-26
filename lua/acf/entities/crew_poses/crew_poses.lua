local ACF     = ACF
local CrewPoses = ACF.Classes.CrewPoses


CrewPoses.Register("walk_camera", {
	Name = "Camera Walk",
	Position = Vector(0, -6, 1),
	Angle = Angle(0, 90, 0),
})

CrewPoses.Register("walk_dual", {
	Name = "Dual Walk",
	Position = Vector(0, -6, 1),
	Angle = Angle(0, 90, 0),
})

CrewPoses.Register("walk_all", {
	Name = "All Walk",
	Position = Vector(0, -6, 1),
	Angle = Angle(0, 90, 0),
})

CrewPoses.Register("sit_rollercoaster", {
	Name = "Rollercoaster Sit",
	Position = Vector(0, -20, 20),
	Angle = Angle(0, 90, 0),
})

CrewPoses.Register("sit_camera", {
	Name = "Camera Sit",
	Position = Vector(0, -20, 16),
	Angle = Angle(0, 90, 0),
})
