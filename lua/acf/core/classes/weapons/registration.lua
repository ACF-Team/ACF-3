local Classes = ACF.Classes
local Weapons = Classes.Weapons
local Entries = {}


function Weapons.Register(ID, Data)
	local Group = Classes.AddGroup(ID, Entries, Data)

	if not Group.LimitConVar then
		Group.LimitConVar = {
			Name   = "_acf_weapon",
			Amount = 16,
			Text   = "Maximum amount of ACF weapons a player can create."
		}
	end

	Classes.AddSboxLimit(Group.LimitConVar)

	if not Group.Cleanup then
		Group.Cleanup = "acf_gun"
	end

	if Group.MuzzleFlash then
		PrecacheParticleSystem(Group.MuzzleFlash)
	end

	return Group
end

function Weapons.RegisterItem(ID, ClassID, Data)
	local Class = Classes.AddGroupItem(ID, ClassID, Entries, Data)

	Class.Destiny = "Weapons"

	if Class.MuzzleFlash then
		PrecacheParticleSystem(Class.MuzzleFlash)
	end

	return Class
end

Classes.AddGroupedFunctions(Weapons, Entries)
