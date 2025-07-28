local ACF     = ACF
local CrewPoses = ACF.Classes.CrewPoses


CrewPoses.Register("Standing", {
	Name = "Standing",
})

do
	CrewPoses.RegisterItem("walk_camera", "Standing", {
		Name = "Camera Walk",
		Position = Vector(0, -6, 1),
		Angle = Angle(0, 90, 0),
	})

	CrewPoses.RegisterItem("walk_dual", "Standing", {
		Name = "Dual Walk",
		Position = Vector(0, -6, 1),
		Angle = Angle(0, 90, 0),
	})

	CrewPoses.RegisterItem("walk_all", "Standing", {
		Name = "All Walk",
		Position = Vector(0, -6, 1),
		Angle = Angle(0, 90, 0),
	})
end

CrewPoses.Register("Sitting", {
	Name = "Sitting",
})

do
	CrewPoses.RegisterItem("sit_rollercoaster", "Sitting", {
		Name = "Rollercoaster Sit",
		Position = Vector(0, -20, 20),
		Angle = Angle(0, 90, 0),
	})

	CrewPoses.RegisterItem("sit_camera", "Sitting", {
		Name = "Camera Sit",
		Position = Vector(0, -20, 16),
		Angle = Angle(0, 90, 0),
	})
end