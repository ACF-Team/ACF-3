local ACF = ACF
local Damage = ACF.TempDamage

--- Returns the blast radius based on a given amount of filler mass
-- Note: Scaling law found on the net, based on 1PSI overpressure from 1 kg of TNT at 15m
-- @param Filler The amount of filler in kilograms.
-- @return The blast radius in inches.
function Damage.getBlastRadius(Filler)
	return Filler ^ 0.33 * 8 * 39.37
end
