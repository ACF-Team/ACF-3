local math   = math
local util   = util
local ACF    = ACF
local Damage = ACF.TempDamage
local Down   = Vector(0, 0, -1)

--- Returns the blast radius based on a given amount of filler mass
-- Note: Scaling law found on the net, based on 1PSI overpressure from 1 kg of TNT at 15m
-- @param Filler The amount of filler in kilograms.
-- @return The blast radius in inches.
function Damage.getBlastRadius(Filler)
	return Filler ^ 0.33 * 8 * 39.37
end

function Damage.explosionEffect(Position, Direction, Filler, Caliber)
	local Radius = math.max(1, Damage.getBlastRadius(Filler))

	local Effect = EffectData()
	Effect:SetOrigin(Position)
	Effect:SetNormal(Direction or Down)
	Effect:SetRadius(Caliber or 0)
	Effect:SetScale(Radius)

	util.Effect("ACF_Explosion", Effect)
end
