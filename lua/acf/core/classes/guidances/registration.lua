local Classes   = ACF.Classes
local Guidances = Classes.Guidances
local Entries   = Classes.GetOrCreateEntries(Guidances)


function Guidances.Register(ID, Base)
	return Classes.AddObject(ID, Base, Entries)
end

Classes.AddSimpleFunctions(Guidances, Entries)
