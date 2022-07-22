local function AddVehicle( t, class )
	list.Set( "Vehicles", class, t )
end

local lCategory = "Playerstart Chairs"
local lAuthor = "aversion"
local lInformation = "Driving pose modeled with a playermodel mesh."
local lClass = "prop_vehicle_prisoner_pod"
local lKeyvalues = { vehiclescript = "scripts/vehicles/prisoner_pod.txt", limitview = "0" }
local lCategoryExp = "Playerstart Chairs (Experimental)"

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

AddVehicle( {
	Name = "Jeep Pose",
	Model = "models/chairs_playerstart/jeeppose.mdl",
	Class = lClass,
	Category = lCategory,

	Author = lAuthor,
	Information = lInformation,

	KeyValues = lKeyvalues,
	Members = {
		HandleAnimation = HandlePHXVehicleAnimation, ----
	}
}, "playerstart_chairs_jeep" )

AddVehicle( {
	Name = "Airboat Pose",  ----
	Model = "models/chairs_playerstart/airboatpose.mdl", ----
	Class = lClass,
	Category = lCategory,

	Author = lAuthor,
	Information = lInformation,

	KeyValues = lKeyvalues,
	Members = {
		HandleAnimation = HandlePHXAirboatAnimation, ----
	}
}, "playerstart_chairs_airboat" )

AddVehicle( {
	Name = "Sitting Pose",  ----
	Model = "models/chairs_playerstart/sitposealt.mdl", ----
	Class = lClass,
	Category = lCategory,

	Author = lAuthor,
	Information = lInformation,

	KeyValues = lKeyvalues,
	Members = {
		HandleAnimation = HandleRollercoasterAnimation, ----
	}
}, "playerstart_chairs_seated" )

AddVehicle( {
	Name = "Pod Pose",  ----
	Model = "models/chairs_playerstart/podpose.mdl", ----
	Class = lClass,
	Category = lCategory,

	Author = lAuthor,
	Information = lInformation,

	KeyValues = lKeyvalues,
	Members = {
		HandleAnimation = HandlePodAnim, ----
	}
}, "playerstart_chairs_podpose" )


---- Experimental seats ----


AddVehicle( {
	Name = "Sitting Pose (Alt Physics)",  ----
	Model = "models/chairs_playerstart/sitpose.mdl", ----
	Class = lClass,
	Category = lCategoryExp,

	Author = lAuthor,
	Information = lInformation,

	KeyValues = lKeyvalues,
	Members = {
		HandleAnimation = HandleRollercoasterAnimation, ----
	}
}, "playerstart_chairs_seated_alt" )

AddVehicle( {
	Name = "Standing Pose",  ----
	Model = "models/chairs_playerstart/standingpose.mdl", ----
	Class = lClass,
	Category = lCategoryExp,

	Author = lAuthor,
	Information = lInformation,

	KeyValues = lKeyvalues,
	Members = {
		HandleAnimation = HandlePodAnim, ----
	}
}, "playerstart_chairs_standing" )

AddVehicle( {
	Name = "Prone Pose",  ----
	Model = "models/chairs_playerstart/pronepose.mdl", ----
	Class = lClass,
	Category = lCategoryExp,

	Author = lAuthor,
	Information = lInformation,

	KeyValues = lKeyvalues,
	Members = {
		HandleAnimation = HandlePodAnim, ----
	}
}, "playerstart_chairs_prone" )
