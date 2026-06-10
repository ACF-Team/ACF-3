local Classes = ACF.Classes
Classes.ArmorTypes = Classes.ArmorTypes or {}

local ArmorTypes = Classes.ArmorTypes

local Entries = Classes.GetOrCreateEntries(ArmorTypes)


function ArmorTypes.Register(ID, Base)

    return Classes.AddObject(ID, Base, Entries)

end


Classes.AddSimpleFunctions(ArmorTypes, Entries)