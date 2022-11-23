local game    = game
local ACF     = ACF
local Objects = ACF.Damage.Objects
local Meta    = {}
local String  = "DamageInfo [Attacker = %s, Inflictor = %s, Type = %s, Origin = %s, HitPos = %s, HitGroup = %s]"

--- Create a new DamageInfo object.
-- This is just a much more simplified version of Gmod's CTakeDamageInfo object.
-- @param Attacker The entity that caused the damage. Leaving this blank will default it to the world entity.
-- @param Inflictor The entity that was used to deal damage. Leaving this blank will default it to the world entity.
-- @param Type The type of damage this object will carry. Leaving this blank will default it to DMG_GENERIC.
-- @param Origin The world position where the damage was originated from. Leaving this blank will default it to a zero vector.
-- @param HitPos The world position where the damage was dealt. Leaving this blank will default it to a zero vector.
-- @param HitGroup The hitgroup that received the damage. Leaving this blank will default it to 0.
-- @return The new DamageInfo object.
function Objects.DamageInfo(Attacker, Inflictor, Type, Origin, HitPos, HitGroup)
	local Object = {
		Attacker  = Attacker or game.GetWorld(),
		Inflictor = Inflictor or game.GetWorld(),
		Type      = Type or DMG_GENERIC,
		Origin    = Origin or Vector(),
		HitPos    = HitPos or Vector(),
		HitGroup  = HitGroup or 0,
	}

	setmetatable(Object, Meta)

	return Object
end

function Meta:ToString()
	return String:format(self.Attacker, self.Inflictor, self.Type, self.Origin, self.HitPos, self.HitGroup)
end

AccessorFunc(Meta, "Attacker", "Attacker")
AccessorFunc(Meta, "Inflictor", "Inflictor")
AccessorFunc(Meta, "Type", "Type", FORCE_NUMBER)
AccessorFunc(Meta, "Origin", "Origin")
AccessorFunc(Meta, "HitPos", "HitPos")
AccessorFunc(Meta, "HitGroup", "HitGroup", FORCE_NUMBER)

Meta.__index    = Meta
Meta.__tostring = Meta.ToString
