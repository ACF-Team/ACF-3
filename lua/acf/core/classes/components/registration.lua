local Classes    = ACF.Classes
local Components = Classes.Components
local Entries    = Classes.GetOrCreateEntries(Components)


function Components.Register(ID, Data)
	local Group = Classes.AddGroup(ID, Entries, Data)

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

function Components.RegisterItem(ID, ClassID, Data)
	return Classes.AddGroupItem(ID, ClassID, Entries, Data)
end

Classes.AddGroupedFunctions(Components, Entries)

-- This isn't actually related to components, but it doesn't have its own unique place to go...
Classes.AddSboxLimit({
	Name   = "_acf_controller",
	Amount = 6,
	Text   = "Maximum amount of ACF controllers a player can create."
})