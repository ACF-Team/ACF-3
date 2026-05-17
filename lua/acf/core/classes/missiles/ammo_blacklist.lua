local AmmoTypes   = ACF.Classes.AmmoTypes
local Blacklisted = {}

local function AddToBlacklist(Weapon, Ammo)
	local AmmoType  = AmmoTypes.Get(Ammo)
	local Blacklist = Blacklisted[Ammo]

	if Blacklist then
		Blacklist[Weapon] = true
	else
		Blacklisted[Ammo] = {
			[Weapon] = true,
		}
	end

	if AmmoType and AmmoType.Loaded then
		AmmoType.Blacklist[Weapon] = true
	end
end

hook.Add("ACF_OnCreateGroup", "ACF External Ammo Blacklist", function(ID, Group)
	if not Group.Blacklist then return end

	for _, Ammo in ipairs(Group.Blacklist) do
		AddToBlacklist(ID, Ammo)
	end
end)

hook.Add("ACF_OnLoadClass", "ACF External Ammo Blacklist", function(ID, Class)
	if not AmmoTypes.Get(ID) then return end
	if not Blacklisted[ID] then return end

	local Blacklist = Class.Blacklist

	for K in pairs(Blacklisted[ID]) do
		Blacklist[K] = true
	end
end)
