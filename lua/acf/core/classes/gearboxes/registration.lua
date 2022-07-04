local Classes   = ACF.Classes
local Gearboxes = Classes.Gearboxes
local Entries   = {}


function Gearboxes.Register(ID, Data)
	local Group = Classes.AddGroup(ID, Entries, Data)

	if not Group.Sound then
		Group.Sound = "buttons/lever7.wav"
	end

	if not Group.LimitConVar then
		Group.LimitConVar = {
			Name   = "_acf_gearbox",
			Amount = 24,
			Text   = "Maximum amount of ACF gearboxes a player can create."
		}
	end

	Classes.AddSboxLimit(Group.LimitConVar)

	return Group
end

function Gearboxes.RegisterItem(ID, ClassID, Data)
	return Classes.AddGroupItem(ID, ClassID, Entries, Data)
end

Classes.AddGroupedFunctions(Gearboxes, Entries)
