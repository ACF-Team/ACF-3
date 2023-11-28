local Classes   = ACF.Classes
local FuelTanks = Classes.FuelTanks
local Entries   = {}


function FuelTanks.Register(ID, Data)
	local Group = Classes.AddGroup(ID, Entries, Data)

	if not Group.LimitConVar then
		Group.LimitConVar = {
			Name   = "_acf_fueltank",
			Amount = 32,
			Text   = "Maximum amount of ACF fuel tanks a player can create."
		}
	end

	Classes.AddSboxLimit(Group.LimitConVar)

	return Group
end

function FuelTanks.RegisterItem(ID, ClassID, Data)
	local Class = Classes.AddGroupItem(ID, ClassID, Entries, Data)

	if Class.Name == nil then
		Class.Name = "Fuel Box"
	end

	if Class.IsExplosive == nil then
		Class.IsExplosive = true
	end

	return Class
end

Classes.AddGroupedFunctions(FuelTanks, Entries)
