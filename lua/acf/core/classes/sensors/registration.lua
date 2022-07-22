local Classes = ACF.Classes
local Sensors = Classes.Sensors
local Entries = {}


function Sensors.Register(ID, Data)
	local Group = Classes.AddGroup(ID, Entries, Data)

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

function Sensors.RegisterItem(ID, ClassID, Data)
	return Classes.AddGroupItem(ID, ClassID, Entries, Data)
end

Classes.AddGroupedFunctions(Sensors, Entries)
