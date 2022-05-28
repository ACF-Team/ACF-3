local Classes = ACF.Classes

Classes.Piledrivers = Classes.Piledrivers or {}

local Piledrivers = Classes.Piledrivers
local Entries     = {}


function Piledrivers.RegisterGroup(ID, Data)
	local Group = Classes.AddClassGroup(ID, Entries, Data)

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

function Piledrivers.Register(ID, ClassID, Data)
	return Classes.AddGrouped(ID, ClassID, Entries, Data)
end

Classes.AddGroupedFunctions(Piledrivers, Entries)
