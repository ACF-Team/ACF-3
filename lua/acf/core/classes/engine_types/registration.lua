local Classes = ACF.Classes
local Types   = Classes.EngineTypes
local Entries = Classes.GetOrCreateEntries(Types)

function Types.Register(ID, Data)
	return Classes.AddSimple(ID, Entries, Data)
end

Classes.AddSimpleFunctions(Types, Entries)
