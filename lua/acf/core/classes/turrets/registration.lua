local Classes 	= ACF.Classes
local Turrets 	= Classes.Turrets
local Entries   = Classes.GetOrCreateEntries(Turrets)

function Turrets.Register(ID, Data)
	local Group = Classes.AddGroup(ID, Entries, Data)

	if not Group.LimitConVar then
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
	local Item = Classes.AddGroupItem(ID, ClassID, Entries, Data)

	-- Lets an item have its own spawn limit independent of the group, same as CrewTypes.Register
	if Item.LimitConVar then Classes.AddSboxLimit(Item.LimitConVar) end

	return Item
end

Classes.AddGroupedFunctions(Turrets, Entries)
