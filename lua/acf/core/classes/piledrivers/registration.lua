local Classes     = ACF.Classes
local Piledrivers = Classes.Piledrivers
local Entries     = {}


function Piledrivers.Register(ID, Data)
	local Group = Classes.AddGroup(ID, Entries, Data)

	Group.Cyclic = math.min(120, Group.Cyclic or 60)

	if not Group.LimitConVar then
		Group.LimitConVar = {
			Name = "_acf_piledriver",
			Amount = 4,
			Text = "Maximum amount of ACF piledrivers a player can create."
		}
	end

	Classes.AddSboxLimit(Group.LimitConVar)

	if not Group.Cleanup then
		Group.Cleanup = "acf_piledriver"
	end

	return Group
end

function Piledrivers.RegisterItem(ID, ClassID, Data)
	return Classes.AddGroupItem(ID, ClassID, Entries, Data)
end

Classes.AddGroupedFunctions(Piledrivers, Entries)
