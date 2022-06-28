local Classes    = ACF.Classes
local Components = Classes.Components
local Entries    = {}


function Components.RegisterGroup(ID, Data)
	local Group = Classes.AddClassGroup(ID, Entries, Data)

	if not Group.LimitConVar then
		Group.LimitConVar = {
			Name   = "_acf_misc",
			Amount = 32,
			Text   = "Maximum amount of ACF components a player can create."
		}
	end

	Classes.AddSboxLimit(Group.LimitConVar)

	return Group
end

function Components.Register(ID, ClassID, Data)
	return Classes.AddGrouped(ID, ClassID, Entries, Data)
end

Classes.AddGroupedFunctions(Components, Entries)
