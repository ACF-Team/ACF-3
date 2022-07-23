local Category = "Playerstart Chairs"

local function AddVehicle(Class, Data)
	local Entry = {
		Name        = Data.Name,
		Model       = Data.Model,
		Class       = "prop_vehicle_prisoner_pod",
		Category    = Category,
		Author      = "aversion",
		Information = "Driving pose modeled with a playermodel mesh.",
		KeyValues   = {
			vehiclescript = "scripts/vehicles/prisoner_pod.txt",
			limitview     = "0"
		},
		Members = {
			HandleAnimation = Data.Animation,
		},
	}

	list.Set("Vehicles", Class, Entry)
end

local function HandleRollercoasterAnimation(_, Player)
	return Player:SelectWeightedSequence(ACT_GMOD_SIT_ROLLERCOASTER)
end

local function HandlePHXVehicleAnimation(_, Player)
	return Player:SelectWeightedSequence(ACT_DRIVE_JEEP)
end

local function HandlePHXAirboatAnimation(_, Player)
	return Player:SelectWeightedSequence(ACT_DRIVE_AIRBOAT)
end

local function HandlePodAnim(_, Player)
	return Player:LookupSequence("drive_pd")
end

AddVehicle("playerstart_chairs_jeep", {
	Name      = "Jeep Pose",
	Model     = "models/chairs_playerstart/jeeppose.mdl",
	Animation = HandlePHXVehicleAnimation,
})

AddVehicle("playerstart_chairs_airboat", {
	Name      = "Airboat Pose",
	Model     = "models/chairs_playerstart/airboatpose.mdl",
	Animation = HandlePHXAirboatAnimation,
})

AddVehicle("playerstart_chairs_seated", {
	Name      = "Sitting Pose",
	Model     = "models/chairs_playerstart/sitposealt.mdl",
	Animation = HandleRollercoasterAnimation,
})

AddVehicle("playerstart_chairs_podpose", {
	Name      = "Pod Pose",
	Model     = "models/chairs_playerstart/podpose.mdl",
	Animation = HandlePodAnim,
})


---- Experimental seats ----
Category = "Playerstart Chairs (Experimental)"


AddVehicle("playerstart_chairs_seated_alt", {
	Name      = "Sitting Pose (Alt Physics)",
	Model     = "models/chairs_playerstart/sitpose.mdl",
	Animation = HandleRollercoasterAnimation,
})

AddVehicle("playerstart_chairs_standing", {
	Name      = "Standing Pose",
	Model     = "models/chairs_playerstart/standingpose.mdl",
	Animation = HandlePodAnim,
})

AddVehicle("playerstart_chairs_prone", {
	Name      = "Prone Pose",
	Model     = "models/chairs_playerstart/pronepose.mdl",
	Animation = HandlePodAnim,
})
