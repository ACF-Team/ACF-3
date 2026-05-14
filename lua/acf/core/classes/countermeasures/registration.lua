local Classes  = ACF.Classes
local Measures = Classes.Countermeasures
local Entries  = Classes.GetOrCreateEntries(Measures)


function Measures.Register(ID, Base)
	return Classes.AddObject(ID, Base, Entries)
end

Classes.AddSimpleFunctions(Measures, Entries)
