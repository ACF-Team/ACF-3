local Classes   = ACF.Classes
local Gearboxes = Classes.Gearboxes
local Entries   = {}


function Gearboxes.RegisterGroup(ID, Data)
	local Group = Classes.AddClassGroup(ID, Entries, Data)

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

function Gearboxes.Register(ID, ClassID, Data)
	return Classes.AddGrouped(ID, ClassID, Entries, Data)
end

Classes.AddGroupedFunctions(Gearboxes, Entries)

do -- Discontinued function
	function ACF_DefineGearbox(ID)
		print("Attempted to register gearbox " .. ID .. " with a discontinued function. Use ACF.RegisterGearbox instead.")
	end
end
