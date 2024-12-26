local Classes = ACF.Classes
local CrewTypes   = Classes.CrewTypes
local Entries = {}


function CrewTypes.Register(ID, Data)
	return Classes.AddSimple(ID, Entries, Data)
end

Classes.AddSimpleFunctions(CrewTypes, Entries)