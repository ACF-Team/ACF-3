local Classes = ACF.Classes
Classes.ProcArmorTypes = Classes.ProcArmorTypes or {}

local ProcArmorTypes = Classes.ProcArmorTypes

local Entries = Classes.GetOrCreateEntries(ProcArmorTypes)


function ProcArmorTypes.Register(ID, Base)

    return Classes.AddObject(ID, Base, Entries)

end


Classes.AddSimpleFunctions(ProcArmorTypes, Entries)