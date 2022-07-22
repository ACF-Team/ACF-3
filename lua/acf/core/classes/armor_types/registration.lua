local Classes    = ACF.Classes
local ArmorTypes = Classes.ArmorTypes
local Entries    = {}


function ArmorTypes.Register(ID, Base)
	return Classes.AddObject(ID, Base, Entries)
end

Classes.AddSimpleFunctions(ArmorTypes, Entries)
Classes.AddSboxLimit({
	Name   = "_acf_armor",
	Amount = 50,
	Text   = "Maximum amount of ACF procedural armor plates a player can create"
})
