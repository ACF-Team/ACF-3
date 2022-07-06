local Classes = ACF.Classes
local Crates  = Classes.Crates
local Entries = {}


-- NOTE: This registration function should only be used for backwards compatibility
-- ACF itself won't allow you to select whatever crate models you define with it
-- This is only used for old ammo crates that need to be ported into the new system
-- This function will only use the given ID, which should be the path of the model
-- and two fields from Data: Size and Offset, both vectors and optional
function Crates.Register(ID, Data)
	return Classes.AddSimple(ID, Entries, Data)
end

Classes.AddSimpleFunctions(Crates, Entries)
