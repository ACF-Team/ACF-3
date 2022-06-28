local Classes = ACF.Classes
local Weapons = Classes.Weapons
local Entries = {}


function Weapons.RegisterGroup(ID, Data)
	local Group = Classes.AddClassGroup(ID, Entries, Data)

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

function Weapons.Register(ID, ClassID, Data)
	local Class = Classes.AddGrouped(ID, ClassID, Entries, Data)

	Class.Destiny = "Weapons"

	if Class.MuzzleFlash then
		PrecacheParticleSystem(Class.MuzzleFlash)
	end

	return Class
end

Classes.AddGroupedFunctions(Weapons, Entries)

do -- Discontinued functions
	function ACF_defineGunClass(ID)
		print("Attempted to register weapon class " .. ID .. " with a discontinued function. Use ACF.RegisterWeaponClass instead.")
	end

	function ACF_defineGun(ID)
		print("Attempted to register weapon " .. ID .. " with a discontinued function. Use ACF.RegisterWeapon instead.")
	end
end
