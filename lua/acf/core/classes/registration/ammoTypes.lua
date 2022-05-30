local Classes = ACF.Classes

Classes.AmmoTypes = Classes.AmmoTypes or {}

local AmmoTypes = Classes.AmmoTypes
local Entries   = {}


function AmmoTypes.Register(ID, Base)
	return Classes.AddObjectClass(ID, Base, Entries)
end

Classes.AddSimpleFunctions(AmmoTypes, Entries)
