-- AutoRegisterV2 conversion: migrate legacy flat crew dupe data into the ACF_UserData field set. Crew
-- type/model/pose are addressed by short id (the class FQN suffix). Crew TYPE ids are unchanged, but the
-- MODEL and POSE ids were reformatted for the new class tree (underscores dropped from models,
-- snake_case → PascalCase for poses), so old dupes' ids must be remapped or they'll fail to resolve and
-- fall back to the default Sitting model / no pose.
local ModelRemap = {
	Sitting_Large   = "SittingLarge",
	Sitting_Medium  = "SittingMedium",
	Sitting_Small   = "SittingSmall",
	Standing_Large  = "StandingLarge",
	Standing_Medium = "StandingMedium",
	Standing_Small  = "StandingSmall",
}

local PoseRemap = {
	walk_camera      = "WalkCamera",
	walk_dual        = "WalkDual",
	walk_all         = "WalkAll",
	sit_rollercoaster = "SitRollercoaster",
	sit_camera       = "SitCamera",
}

ACF.Entities.RegisterCompatPatch("acf_crew", 2026062801, function(Data)
	if Data.ACF_UserData then return end

	local function Pick(Key)
		return Data[Key]
	end

	local CrewModelID = Pick("CrewModelID")
	local CrewPoseID  = Pick("CrewPoseID")

	Data.ACF_UserData = {
		CrewTypeID                = Pick("CrewTypeID"),
		CrewModelID               = ModelRemap[CrewModelID] or CrewModelID,
		CrewPoseID                = PoseRemap[CrewPoseID] or CrewPoseID,
		ReplaceOthers             = Pick("ReplaceOthers"),
		ReplaceSelf               = Pick("ReplaceSelf"),
		ReplacedOnlyLower         = Pick("ReplacedOnlyLower"),
		UseAnimation              = Pick("UseAnimation"),
		CrewPriority              = Pick("CrewPriority"),
		CrewPlayerModel           = Pick("CrewPlayerModel"),
		CrewPlayerModelBodygroups = Pick("CrewPlayerModelBodygroups"),
		CrewPlayerModelSkin       = Pick("CrewPlayerModelSkin"),
	}
end)
