local Classes   = ACF.Classes
local AmmoTypes = Classes.AmmoTypes
local Entries   = Classes.GetOrCreateEntries(AmmoTypes)

function AmmoTypes.Register(ID, Base)
	return Classes.AddObject(ID, Base, Entries)
end

Classes.AddSimpleFunctions(AmmoTypes, Entries)
Classes.AddSboxLimit({
	Name   = "_acf_ammo",
	Amount = 32,
	Text   = "Maximum amount of ACF ammo crates a player can create."
})