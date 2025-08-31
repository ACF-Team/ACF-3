local Classes      = ACF.Classes
local CrewPoses    = Classes.CrewPoses
local Entries      = Classes.GetOrCreateEntries(CrewPoses)


function CrewPoses.Register(ID, Data)
	local Group = Classes.AddGroup(ID, Entries, Data)

	return Group
end

function CrewPoses.RegisterItem(ID, ClassID, Data)
	local Class = Classes.AddGroupItem(ID, ClassID, Entries, Data)

	return Class
end

Classes.AddGroupedFunctions(CrewPoses, Entries)