--[[*
	ACF Permission mode: Safe
		This mode completely disables damage upon everything.
//]]
-- the name for this mode used in commands and identification
local modename = modename or "safe"

if not ACF or not ACF.Permissions or not ACF.Permissions.RegisterMode then
	error("ACF: Tried to load the " .. modename .. " permission-mode before the permission-core has loaded!")
end

local perms = ACF.Permissions
-- a short description of what the mode does
local modedescription = "Completely disables damage upon everything."

--[[
	Defines the behaviour of ACF damage protection under this protection mode.
	This function is called every time an entity can be affected by potential ACF damage.
	Args;
		owner		Player:	The owner of the potentially-damaged entity
		attacker	Player:	The initiator of the ACF damage event
		ent			Entity:	The entity which may be damaged.
	Return: boolean
		true if the entity should be damaged, false if the entity should be protected from the damage.
//]]
local function modepermission()
	return false
end

perms.RegisterMode(modepermission, modename, modedescription, false, nil, false)