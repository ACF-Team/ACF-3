-- AutoRegisterV2 conversion: migrate legacy flat crew dupe data into the ACF_UserData field set. All
-- crew fields are flat scalars/strings whose names match the new field set (crew type/model/pose are
-- addressed by short id, i.e. the class FQN suffix), so this is a straight copy.
ACF.Entities.RegisterCompatPatch("acf_crew", 2026062801, function(Data)
	if Data.ACF_UserData then return end

	-- Values may live at the top level (modern legacy dupes) or under a nested "Data" table (older/ACE).
	local Old = Data.Data or {}

	local function Pick(Key)
		local Value = Old[Key]
		if Value == nil then Value = Data[Key] end
		return Value
	end

	Data.ACF_UserData = {
		CrewTypeID                = Pick("CrewTypeID"),
		CrewModelID               = Pick("CrewModelID"),
		CrewPoseID                = Pick("CrewPoseID"),
		ReplaceOthers             = Pick("ReplaceOthers"),
		ReplaceSelf               = Pick("ReplaceSelf"),
		UseAnimation              = Pick("UseAnimation"),
		CrewPriority              = Pick("CrewPriority"),
		CrewPlayerModel           = Pick("CrewPlayerModel"),
		CrewPlayerModelBodygroups = Pick("CrewPlayerModelBodygroups"),
		CrewPlayerModelSkin       = Pick("CrewPlayerModelSkin"),
	}
end)
