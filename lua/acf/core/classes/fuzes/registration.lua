local Classes = ACF.Classes
local Fuzes   = Classes.Fuzes
local Entries = Classes.GetOrCreateEntries(Fuzes)


function Fuzes.Register(ID, Base)
	return Classes.AddObject(ID, Base, Entries)
end

Classes.AddSimpleFunctions(Fuzes, Entries)
