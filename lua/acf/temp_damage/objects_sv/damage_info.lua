local ACF     = ACF
local Objects = ACF.TempDamage.Objects
local Meta    = {}

function Objects.DamageInfo()
	local Object = {
		Attacker  = NULL,
		Inflictor = NULL,
		HitGroup  = 0,
	}

	setmetatable(Object, Meta)

	return Object
end

AccessorFunc(Meta, "Attacker", "Attacker")
AccessorFunc(Meta, "Inflictor", "Inflictor")
AccessorFunc(Meta, "HitGroup", "HitGroup", FORCE_NUMBER)