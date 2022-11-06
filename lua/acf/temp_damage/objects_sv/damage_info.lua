local game    = game
local ACF     = ACF
local Objects = ACF.TempDamage.Objects
local Meta    = {}
local String  = "DamageInfo [Attacker = %s, Inflictor = %s, Type = %s, HitGroup = %s]"

--- Create a new DamageInfo object.
-- This is just a much more simplified version of Gmod's CTakeDamageInfo object.
-- @param Attacker The entity that caused the damage. Leaving this blank will default it to the world entity.
-- @param Inflictor The entity that was used to deal damage. Leaving this blank will default it to the world entity.
-- @param Type The type of damage this object will carry. Leaving this blank will default it to "Unknown".
-- @param HitGroup The hitgroup that received the damage. Leaving this blank will default it to 0.
-- @return The new DamageInfo object.
function Objects.DamageInfo(Attacker, Inflictor, Type, HitGroup)
	local Object = {
		Attacker  = Attacker or game.GetWorld(),
		Inflictor = Inflictor or game.GetWorld(),
		Type      = Type or "Unknown",
		HitGroup  = HitGroup or 0,
	}

	setmetatable(Object, Meta)

	return Object
end

function Meta:ToString()
	return String:format(self.Attacker, self.Inflictor, self.Type, self.HitGroup)
end

AccessorFunc(Meta, "Type", "Type", FORCE_STRING)
AccessorFunc(Meta, "Attacker", "Attacker")
AccessorFunc(Meta, "Inflictor", "Inflictor")
AccessorFunc(Meta, "HitGroup", "HitGroup", FORCE_NUMBER)

Meta.__index    = Meta
Meta.__tostring = Meta.ToString
