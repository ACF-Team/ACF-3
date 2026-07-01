ACF.Entities.RegisterCompatPatch("acf_opticalcomputer", 2026062101, function(Data)
	Data.Class = "acf_computer"
end)

local Classes = ACF.Classes

-- Components are V2 classes (ACF.Components.*) with no CLASS.ID; map a legacy computer id to its FQN by
-- matching the FQN suffix, falling back to a working guidance computer for unknown legacy ids.
local function ComponentFQN(ID)
	if Classes.GetSubtypeByName("ACF.Components.BaseComponent", ID) then return ID end -- already an FQN

	for _, Class in ipairs(Classes.GetSubtypesAsList("ACF.Components.BaseComponent")) do
		if Classes.GetTypeName(Class):match("[^.]+$") == ID then return Classes.GetTypeName(Class) end
	end

	return "ACF.Components.LaserGuidanceComputer"
end

-- AutoRegisterV2 conversion: migrate legacy flat computer dupe data into the nested ACF_UserData field set.
ACF.Entities.RegisterCompatPatch("acf_computer", 2026062801, function(Data)
	if Data.ACF_UserData then return end

	-- Values may live at the top level (modern legacy dupes) or under a nested "Data" table (older/ACE).
	local Old = Data.Data or {}
	local ID  = Old.Computer or Data.Computer or Old.Component or Data.Component or Data.Id

	Data.ACF_UserData = {
		Computer = {Type = ComponentFQN(ID), Data = {}},
	}
end)
