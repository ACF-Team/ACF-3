local ACF     = ACF
local Objects = ACF.TempDamage.Objects
local Meta    = {}

Meta.__index = Meta

--- Create a new DamageInfo object.
-- This is just a much more simplified version of Gmod's CTakeDamageInfo object.
-- @param Type The type of damage this object will carry. Leaving this blank will default it to "Unknown".
-- @param Attacker The entity that caused the damage. Leaving this blank will default it to NULL.
-- @param Inflictor The entity that was used to deal damage. Leaving this blank will default it to NULL.
-- @param HitGroup The hitgroup that received the damage. Leaving this blank will default it to 0.
-- @return The new DamageInfo object.
function Objects.DamageInfo(Type, Attacker, Inflictor, HitGroup)
	local Object = {
		Type      = Type or "Unknown",
		Attacker  = Attacker or NULL,
		Inflictor = Inflictor or NULL,
		HitGroup  = HitGroup or 0,
	}

	setmetatable(Object, Meta)

	return Object
end

AccessorFunc(Meta, "Type", "Type", FORCE_STRING)
AccessorFunc(Meta, "Attacker", "Attacker")
AccessorFunc(Meta, "Inflictor", "Inflictor")
AccessorFunc(Meta, "HitGroup", "HitGroup", FORCE_NUMBER)
