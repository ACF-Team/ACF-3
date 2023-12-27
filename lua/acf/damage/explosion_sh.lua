local math   = math
local util   = util
local ACF    = ACF
local Damage = ACF.Damage
local Down   = Vector(0, 0, -1)

--- Returns the blast radius based on a given amount of filler mass
-- Note: Scaling law found on the net, based on 1PSI overpressure from 1 kg of TNT at 15m
-- @param Filler The amount of filler in kilograms.
-- @return The blast radius in inches.
function Damage.getBlastRadius(Filler)
	return Filler ^ 0.33 * 8 * 39.37
end

--- Helper function to create the default ACF explosion effect.
-- @param Position The world position at which the effect will be created.
-- @param Direction A vector referencing the direction at which the explosion will move towards.
-- Leave this blank to create an upwards explosion effect.
-- @param Filler The filler mass of the explosive in kilograms.
-- You can leave this blank if no projectile was involved on the creation of this effect.
function Damage.explosionEffect(Position, Direction, Filler)
	local Radius = math.max(1, Damage.getBlastRadius(Filler))

	local Effect = EffectData()
	Effect:SetOrigin(Position)
	Effect:SetNormal(Direction or Down)
	Effect:SetScale(Radius)

	util.Effect("ACF_Explosion", Effect)
end
