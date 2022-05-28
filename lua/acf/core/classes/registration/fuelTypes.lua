local Classes = ACF.Classes

Classes.FuelTypes = Classes.FuelTypes or {}

local Types   = Classes.FuelTypes
local Entries = {}


function Types.Register(ID, Data)
	return Classes.AddSimple(ID, Entries, Data)
end

Classes.AddSimpleFunctions(Types, Entries)
