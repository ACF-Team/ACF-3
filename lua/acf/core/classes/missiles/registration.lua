local Classes  = ACF.Classes
local Missiles = Classes.Missiles
local Entries  = Classes.GetOrCreateEntries(Missiles)


function Missiles.Register(ID, Data)
	local Group = Classes.AddGroup(ID, Entries, Data)

	if not Group.Entity then
		Group.Entity = "acf_rack"
	end

	if Data.LimitConVar then
		Classes.AddSboxLimit(Data.LimitConVar)
	end

	return Group
end

function Missiles.RegisterItem(ID, ClassID, Data)
	local Class = Classes.AddGroupItem(ID, ClassID, Entries, Data)

	Class.Destiny = "Missiles"

	if Data.LimitConVar then
		Classes.AddSboxLimit(Data.LimitConVar)
	end

	return Class
end

Classes.AddGroupedFunctions(Missiles, Entries)
