local Classes = ACF.Classes

Classes.ArmorTypes = Classes.ArmorTypes or {}

local ArmorTypes = Classes.ArmorTypes
local Entries    = {}


function ArmorTypes.Register(ID, Base)
	return Classes.AddObjectClass(ID, Base, Entries)
end

Classes.AddSimpleFunctions(ArmorTypes, Entries)
Classes.AddSboxLimit({
	Name   = "_acf_armor",
	Amount = 50,
	Text   = "Maximum amount of ACF procedural armor plates a player can create"
})
