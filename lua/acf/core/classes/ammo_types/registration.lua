local Classes   = ACF.Classes
local AmmoTypes = Classes.AmmoTypes
local Entries   = Classes.GetOrCreateEntries(AmmoTypes)

function AmmoTypes.Register(ID, Base)
	return Classes.AddObject(ID, Base, Entries)
end

Classes.AddSimpleFunctions(AmmoTypes, Entries)
