local Classes      = ACF.Classes
local CrewPoses   = Classes.CrewPoses
local Entries      = Classes.GetOrCreateEntries(CrewPoses)


function CrewPoses.Register(ID, Data)
	return Classes.AddSimple(ID, Entries, Data)
end

Classes.AddSimpleFunctions(CrewPoses, Entries)