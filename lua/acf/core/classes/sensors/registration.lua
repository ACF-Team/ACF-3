local Classes = ACF.Classes
local Sensors = Classes.Sensors
local Entries = {}


function Sensors.RegisterGroup(ID, Data)
	local Group = Classes.AddClassGroup(ID, Entries, Data)

	if not Group.LimitConVar then
		Group.LimitConVar = {
			Name   = "_acf_sensor",
			Amount = 16,
			Text   = "Maximum amount of ACF sensors a player can create."
		}
	end

	Classes.AddSboxLimit(Group.LimitConVar)

	return Group
end

function Sensors.Register(ID, ClassID, Data)
	return Classes.AddGrouped(ID, ClassID, Entries, Data)
end

Classes.AddGroupedFunctions(Sensors, Entries)
