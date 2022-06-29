local Classes   = ACF.Classes
local AmmoTypes = Classes.AmmoTypes
local Entries   = {}


function AmmoTypes.Register(ID, Base)
	return Classes.AddObjectClass(ID, Base, Entries)
end

Classes.AddSimpleFunctions(AmmoTypes, Entries)
