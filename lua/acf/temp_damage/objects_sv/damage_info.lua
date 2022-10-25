local ACF     = ACF
local Objects = ACF.TempDamage.Objects
local Meta    = {}

--- Create a new DamageInfo object with all its fields set to default values.
-- This is just a much more simplified version of Gmod's CTakeDamageInfo object.
-- @return The new DamageInfo object.
function Objects.DamageInfo()
	local Object = {
		Type      = "Unknown",
		Attacker  = NULL,
		Inflictor = NULL,
		HitGroup  = 0,
	}

	setmetatable(Object, Meta)

	return Object
end

AccessorFunc(Meta, "Type", "Type", FORCE_STRING)
AccessorFunc(Meta, "Attacker", "Attacker")
AccessorFunc(Meta, "Inflictor", "Inflictor")
AccessorFunc(Meta, "HitGroup", "HitGroup", FORCE_NUMBER)
