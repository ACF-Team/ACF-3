local Classes 	= ACF.Classes
local Turrets 	= Classes.Turrets
local Entries 	= {}


function Turrets.Register(ID, Data)
	local Group = Classes.AddGroup(ID, Entries, Data)

	if not Group.LimitConVar then
		print("Added LimitConVar for ",ID)
		Group.LimitConVar = {
			Name   = "_acf_turret",
			Amount = 24,
			Text   = "Maximum amount of ACF turrets a player can create."
		}
	end

	Classes.AddSboxLimit(Group.LimitConVar)

	return Group
end

function Turrets.RegisterItem(ID, ClassID, Data)
	return Classes.AddGroupItem(ID, ClassID, Entries, Data)
end

Classes.AddGroupedFunctions(Turrets, Entries)
