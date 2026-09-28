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
		Velocity = (Power * 10350 / FragMassEa / Count) ^ 0.5, -- Calibrated against measured TNTe-to-penetration data
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

	-- Bridges the formula's fixed FillerMass^0.225 scaling up to the measured ^0.46.
	local Calibration = FillerMass ^ 0.235

	return ACF.Penetration(FragVel, Frag.Mass, Frag.Caliber) * Calibration
end

--- Returns the penetration of a blast.
-- @param Energy The energy of the blast in KJ.
-- @param Area The area of the blast in cm2.
-- @return The penetration of the blast in RHA mm.
function Damage.getBlastPenetration(Energy, Area)
	return Energy / Area * 0.00125 -- Emperically derived
end

--- Clamped multiplier that prevents runaway exponential scaling for huge explosions.
-- @param Radius The blast radius in inches.
-- @return A multiplier applied to the blast area, clamped to [0.05, 5].
function Damage.getRadiusScale(Radius)
	local RadiusScale = math.exp((Radius / Damage.getBlastRadius(1) - 1) * 0.6)

	return math.Clamp(RadiusScale, 0.05, 5)
end

--- Penetration of an HE explosion's blast wave at a given distance from the detonation.
-- @param FillerMass The amount of HE filler in kilograms.
-- @param EntArea The target's surface area in cm2, as ACF.UpdateArea computes it.
-- @param Distance The distance from the detonation to evaluate, in inches.
-- @return The blast penetration in mm.
function Damage.getBlastPenetrationAtDistance(FillerMass, EntArea, Distance)
	local Power       = FillerMass * ACF.HEPower
	local Radius      = Damage.getBlastRadius(FillerMass)
	local RadiusScale = Damage.getRadiusScale(Radius)

	-- Fraction of the blast wavefront the target's surface subtends, capped at a hemisphere.
	local Sphere        = 4 * math.pi * (Distance * ACF.InchToCm) ^ 2
	local SolidAngle    = math.min(EntArea / Sphere, 0.5)
	local PowerFraction = Power * SolidAngle

	-- Hopkinson-Cranz cube-root scaling: blast impulse decays linearly out to the lethal radius.
	local Falloff   = 1 - math.min(Distance / Radius, 1)
	local BlastArea = EntArea * ACF.BlastAreaCoef * Falloff * RadiusScale

	return Damage.getBlastPenetration(PowerFraction * BlastArea, BlastArea)
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
