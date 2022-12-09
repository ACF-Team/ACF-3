local math    = math
local ACF     = ACF
local Objects = ACF.Damage.Objects
local Meta    = {}
local String  = "DamageResult [Area = %.2fcm2, Penetration = %.2fmm, Thickness = %.2fmm, Angle = %.2f°, Factor = %.2f, Count = %s times]"

--- Creates a new DamageResult object.
-- @param Area The damaged area in cm2. Leaving this blank will default it to 1.
-- @param Penetration The depth of the damage in mm. Leaving this blank will default it to 1.
-- @param Thickness The width of the damaged object in mm. Leaving this blank will default it to 1.
-- @param Angle The inclination at which the object was damaged in degrees. Leaving this blank will default it to 0.
-- @param Factor Usually, the ratio between Thickness and diameter of the penetrating object. Leaving this blank will default it to 1.
-- @param Count A simple multiplier for the damage. Leaving this blank will default it to 1.
-- @return The new DamageResult object.
function Objects.DamageResult(Area, Penetration, Thickness, Angle, Factor, Count)
	local Object = {
		Area        = Area or 1,
		Penetration = Penetration or 1,
		Thickness   = Thickness or 1,
		Angle       = Angle or 0,
		Factor      = Factor or 1,
		Count       = Count or 1
	}

	setmetatable(Object, Meta)

	return Object
end

--- Generates the damage result table based on the values stored on the object.
-- @return The damage result table, contains the Damage, Overkill, Loss and Kill fields.
function Meta:Compute()
	--local Factor      = math.Clamp(self.Factor, 0.1, 1)
	local Effective   = self.Thickness / math.abs(math.cos(math.rad(self.Angle)))
	local Penetration = self.Penetration
	local Ratio       = math.min(1, Penetration / Effective)
	local Count       = math.max(1, self.Count)
	local Damage      = isnumber(self.Damage) and self.Damage or self.Area * Ratio * Ratio -- <=== old - new  ===> Area * math.min(Penetration, Effective) * 10

	return {
		Damage   = Damage * Count,
		Overkill = math.max(0, Penetration - Effective),
		Loss     = math.min(1, Effective / math.max(1, Penetration)),
		Kill     = false,
	}
end

--- Returns a blank damage result table with all its values set to zero (false for Kill).
-- @return The blank damage result table.
function Meta:GetBlank()
	return {
		Damage   = 0,
		Overkill = 0,
		Loss     = 0,
		Kill     = false,
	}
end

function Meta:ToString()
	local Factor = math.Clamp(self.Factor, 0.1, 1)

	return String:format(self.Area, self.Penetration, self.Thickness, self.Angle, Factor, self.Count)
end

AccessorFunc(Meta, "Area", "Area", FORCE_NUMBER) -- cm2
AccessorFunc(Meta, "Penetration", "Penetration", FORCE_NUMBER) -- mm
AccessorFunc(Meta, "Thickness", "Thickness", FORCE_NUMBER) -- mm
AccessorFunc(Meta, "Angle", "Angle", FORCE_NUMBER) -- degrees
AccessorFunc(Meta, "Factor", "Factor", FORCE_NUMBER) -- thickness / caliber
AccessorFunc(Meta, "Count", "Count", FORCE_NUMBER) -- Number of hits
AccessorFunc(Meta, "Damage", "Damage") -- Custom damage, temporary workaround

Meta.__index    = Meta
Meta.__tostring = Meta.ToString
