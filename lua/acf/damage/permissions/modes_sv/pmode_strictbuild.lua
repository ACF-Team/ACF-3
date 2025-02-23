--[[
	ACF Permission mode: Strict Build
		This mode blocks all damage to entities without the owner's permission.
		Owners can permit damage from specific players.
		Players and NPCs are also protected in this mode.
		This mode requires a CPPI-compatible prop-protector to function properly.
]]
-- the name for this mode used in commands and identification
local modename = "strictbuild"

local perms = ACF.Permissions
-- a short description of what the mode does
local modedescription = "Disables all ACF damage unless the owner permits it. PvP is disallowed."
-- if the attacker or victim can't be identified, what should we do? true allows damage, false blocks it.
local DefaultPermission = false

--[[
	Defines the behaviour of ACF damage protection under this protection mode.
	This function is called every time an entity can be affected by potential ACF damage.
	Args;
		owner		Player:	The owner of the potentially-damaged entity
		attacker	Player:	The initiator of the ACF damage event
		ent			Entity:	The entity which may be damaged.
	Return: boolean
		true if the entity should be damaged, false if the entity should be protected from the damage.
]]
local function modepermission(owner, attacker)
	if not (owner.SteamID or attacker.SteamID) then return DefaultPermission end

	local ownerid = owner:SteamID()
	local attackerid = attacker:SteamID()
	local ownerperms = perms.GetDamagePermissions(ownerid)
	if ownerperms[attackerid] then return end

	return false
end

perms.RegisterMode(modepermission, modename, modedescription, false, nil, DefaultPermission)