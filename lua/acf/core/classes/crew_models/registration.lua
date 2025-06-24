local Classes      = ACF.Classes
local CrewModels   = Classes.CrewModels
local Entries      = Classes.GetOrCreateEntries(CrewModels)


function CrewModels.Register(ID, Data)
	return Classes.AddSimple(ID, Entries, Data)
end

Classes.AddSimpleFunctions(CrewModels, Entries)