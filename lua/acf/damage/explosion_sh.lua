local math    = math
local ACF     = ACF
local Damage  = ACF.Damage
local Effects = ACF.Utilities.Effects
local Down    = Vector(0, 0, -1)

--- Returns the blast radius based on a given amount of filler mass
-- Note: Scaling law found on the net, based on 1PSI overpressure from 1 kg of TNT at 15m
-- @param Filler The amount of filler in kilograms.
-- @return The blast radius in inches.
function Damage.getBlastRadius(Filler)
	return Filler ^ 0.33 * 8 * ACF.MeterToInch
end

--- Returns the fragmentation properties of an HE explosion.
-- Single source of truth shared by the damage code and the ammo menu graphs.
-- @param FillerMass The amount of HE filler in kilograms.
-- @param FragMass The total mass of the fragmenting casing in kilograms.
-- @return A table with the fragment Count, per-fragment Mass (kg), base Velocity, Area and Caliber (mm).
function Damage.getFragmentInfo(FillerMass, FragMass)
	local Power      = FillerMass * ACF.HEPower
	local Count      = math.max(math.floor(FillerMass / FragMass * ACF.HEFrag ^ 0.5), 2)
	local FragMassEa = FragMass / Count

	return {
		Count    = Count,
		Mass     = FragMassEa,
		Velocity = (Power * 50000 / FragMassEa / Count) ^ 0.5,
		Area     = (FragMassEa / 7.8) ^ 0.33,
		Caliber  = 20 * (FragMassEa / math.pi) ^ 0.5,
	}
end

--- Penetration of an HE explosion's fragments at a given distance from the detonation.
-- Mirrors the per-target fragment falloff in Damage.createExplosion. Distance and Radius must share units.
-- @param FillerMass The amount of HE filler in kilograms.
-- @param FragMass The total mass of the fragmenting casing in kilograms.
-- @param Radius The blast radius, at which fragment velocity reaches zero.
-- @param Distance The distance from the detonation to evaluate.
-- @return The fragment penetration in mm.
function Damage.getFragmentPenetration(FillerMass, FragMass, Radius, Distance)
	if FragMass <= 0 then return 0 end

	local Frag    = Damage.getFragmentInfo(FillerMass, FragMass)
	local Loss    = Radius > 0 and Frag.Velocity * Distance / Radius or Frag.Velocity
	local FragVel = math.max(Frag.Velocity - Loss, 0) * ACF.InchToMeter

	return ACF.Penetration(FragVel, Frag.Mass, Frag.Caliber)
end

--- Helper function to create the default ACF explosion effect.
-- @param Position The world position at which the effect will be created.
-- @param Direction A vector referencing the direction at which the explosion will move towards.
-- Leave this blank to create an upwards explosion effect.
-- @param Filler The filler mass of the explosive in kilograms.
-- You can leave this blank if no projectile was involved on the creation of this effect.
function Damage.explosionEffect(Position, Direction, Filler)
	local Radius = math.max(1, Damage.getBlastRadius(Filler))

	local EffectTable = {
		Origin = Position,
		Normal = Direction or Down,
		Scale  = Radius,
	}

	Effects.CreateEffect("ACF_Explosion", EffectTable)
end
