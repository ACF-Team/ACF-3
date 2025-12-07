local math    = math
local ACF     = ACF
local Damage  = ACF.Damage
local Effects = ACF.Utilities.Effects
local Down    = Vector(0, 0, -1)
local Threshold  = ACF.Threshold

--- Returns the blast radius based on a given amount of filler mass
-- Note: Scaling law found on the net, based on 1PSI overpressure from 1 kg of TNT at 15m
-- @param Filler The amount of filler in kilograms.
-- @return The blast radius in inches.
function Damage.getBlastRadius(Filler)
	return Filler ^ 0.33 * 8 * ACF.MeterToInch
end

--- Returns the penetration of a blast.
-- @param Energy The energy of the blast in KJ.
-- @param Area The area of the blast in cm2.
-- @return The penetration of the blast in RHA mm.
function Damage.getBlastPenetration(Energy, Area)
	return Energy / Area * 0.25 -- NOTE: 0.25 is what ACF.KEtoRHA used to be set at.
end

--- Returns the fragmentation penetration at a given distance
--- WARNING: NOT USED BY THE EXPLOSION CODE. THIS SHOULD BE UPDATED MANUALLY.
function Damage.getFragPenetrationSimple(FillerMass, FragMass, Distance)
	local Power       = FillerMass * ACF.HEPower -- Power in KJ of the filler mass of TNT
	local Radius      = Damage.getBlastRadius(FillerMass)
	local Fragments   = math.max(math.floor(FillerMass / FragMass * ACF.HEFrag ^ 0.5), 2)
	local FragMass    = FragMass / Fragments
	local BaseFragV   = (Power * 50000 / FragMass / Fragments) ^ 0.5
	local FragCaliber = 20 * (FragMass / math.pi) ^ 0.5 --mm
	local Loss      = BaseFragV * Distance / Radius
	local FragVel   = math.max(BaseFragV - Loss, 0) * ACF.InchToMeter
	local FragPen   = ACF.Penetration(FragVel, FragMass, FragCaliber)
	return FragPen
end

--- Returns the blast penetration at a given distance, with a reference prop.
--- WARNING: NOT USED BY THE EXPLOSION CODE. THIS SHOULD BE UPDATED MANUALLY.
function Damage.getBlastPenetrationSimple(FillerMass, EntArea, Distance)
	local Power       = FillerMass * ACF.HEPower
	local Radius      = Damage.getBlastRadius(FillerMass)
	local Feathering  = 1 - math.min(0.99, Distance / Radius) ^ 0.5
	local BlastArea   = EntArea / Threshold * Feathering
	local MaxSphere    = 4 * math.pi * (Radius * ACF.InchToCm) ^ 2
	local Sphere        = math.max(4 * math.pi * (Distance * ACF.InchToCm) ^ 2, 1)
	local Area          = math.min(EntArea / Sphere, 0.5) * MaxSphere
	local AreaFraction  = Area / MaxSphere
	local PowerFraction = Power * AreaFraction
	local BlastEnergy = PowerFraction ^ 0.3 * BlastArea
	local BlastPen    = Damage.getBlastPenetration(BlastEnergy, BlastArea)
	return BlastPen
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
