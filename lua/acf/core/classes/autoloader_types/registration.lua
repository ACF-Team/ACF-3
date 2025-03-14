local Classes = ACF.Classes
local AutoloaderTypes   = Classes.AutoloaderTypes
local Entries = {}


function AutoloaderTypes.Register(ID, Data)
	return Classes.AddSimple(ID, Entries, Data)
end

Classes.AddSimpleFunctions(AutoloaderTypes, Entries)