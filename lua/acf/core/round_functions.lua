local ACF      = ACF
local Classes  = ACF.Classes
local math     = math
local MM_TO_CM = ACF.MmToInch * ACF.InchToCm -- Millimeters to centimeters


--- Ceiling for ToolData.CaseScale: the widest a class lets a round's case neck out past its projectile
function ACF.GetMaxCaseScale(Class, Weapon)
	local Round = (Weapon and Weapon.Round) or (Class and Class.Round)

	return (Round and Round.CaseScale) or ACF.AmmoCaseScale
end

--- Case outer diameter in cm, off bore caliber -- a subcaliber penetrator doesn't narrow the case
function ACF.GetCaseDiameter(BulletData)
	return (BulletData.Caliber or 0) * (BulletData.CaseScale or 1)
end

local function GetWeaponSpecs(ToolData)
	local Source = Classes[ToolData.Destiny]
	local Class  = Classes.GetGroup(Source, ToolData.Weapon)

	if not Class then return end

	local Result = {
		Caliber     = true,
		MaxLength   = true,
		PropLength  = true,
		ProjLength  = true,
		FillerRatio = true,
	}

	if not Class.IsScalable then
		local Weapon = Source.GetItem(Class.ID, ToolData.Weapon)
		local Round  = Weapon.Round

		Result.Caliber      = Weapon.Caliber
		Result.MaxLength    = Round.MaxLength
		Result.PropLength   = Round.PropLength
		Result.ProjLength   = Round.ProjLength
		Result.Efficiency   = Round.Efficiency
		Result.MaxCaseScale = ACF.GetMaxCaseScale(Class, Weapon)
	else
		local Bounds  = Class.Caliber
		local Round   = Class.Round
		local Caliber = math.Clamp(ToolData.Caliber or Bounds.Base, Bounds.Min, Bounds.Max)
		local Scale   = Caliber / Bounds.Base
		local ProjLen = Round.ProjLength

		Result.Caliber      = Caliber
		Result.MaxLength    = Round.MaxLength * Scale
		Result.PropLength   = Round.PropLength * Scale
		Result.ProjLength   = ProjLen and ProjLen * Scale
		Result.Efficiency   = Round.Efficiency
		Result.MaxCaseScale = ACF.GetMaxCaseScale(Class)
	end

	return Result
end

function ACF.RoundBaseGunpowder(ToolData, Data)
	local Specs   = GetWeaponSpecs(ToolData)
	local GUIData = {}

	if not Specs then return Data, GUIData end

	local Length = math.Round(Specs.MaxLength * (Data.LengthAdj or 1), 2)
	local Radius = Specs.Caliber * MM_TO_CM * 0.5 -- Radius in cm

	Data.Caliber    = Specs.Caliber * MM_TO_CM -- Bullet caliber will have to stay in cm
	Data.Diameter   = Data.Caliber * (Data.ProjScale or 1) -- Real caliber of the projectile
	Data.ProjArea   = math.pi * (Radius * (Data.ProjScale or 1)) ^ 2
	Data.Efficiency = Specs.Efficiency or 1

	-- Un-necked case area; UpdateRoundSpecs scales it into PropArea, since only that re-runs per slider
	Data.PropAreaBase = math.pi * (Radius * (Data.PropScale or 1)) ^ 2
	Data.MaxCaseScale = Specs.MaxCaseScale or ACF.AmmoCaseScale

	GUIData.MaxRoundLength = Length
	GUIData.MinPropLength  = 0.01
	GUIData.MinProjLength  = math.Round(Data.Caliber * 1.5, 2)
	GUIData.MaxPropLength  = math.min(Specs.PropLength, Length - GUIData.MinProjLength)
	GUIData.MaxProjLength  = math.min(Specs.ProjLength or Length, Length - GUIData.MinPropLength)
	GUIData.MinCaseScale   = 1
	GUIData.MaxCaseScale   = Data.MaxCaseScale

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

	return Data, GUIData
end

--- Migrates ToolData length fields to the RoundLength/PropRatio representation. Supports plain
--- old-format ToolData (Projectile/Propellant lengths, from dupes/blueprints saved before that
--- representation was replaced) and the older RoundProjectile/RoundPropellant fallback below that.
--- No-ops once RoundLength/PropRatio are already present.
function ACF.VerifyRoundLengthData(ToolData)
	if isnumber(ToolData.RoundLength) and isnumber(ToolData.PropRatio) then return end

	local Projectile = isnumber(ToolData.Projectile) and ToolData.Projectile or ACF.CheckNumber(ToolData.RoundProjectile, 0)
	local Propellant = isnumber(ToolData.Propellant) and ToolData.Propellant or ACF.CheckNumber(ToolData.RoundPropellant, 0)
	local Total = Projectile + Propellant

	ToolData.RoundLength = Total
	ToolData.PropRatio   = Total > 0 and (Propellant / Total) or 0
end

--- Total round length (RoundLength) and the fraction of it taken up by the propellant (PropRatio,
--- 0-1) are the authoritative state -- ProjLength/PropLength below are derived from them, and are
--- the hook point for future mechanics (e.g. telescoping projectiles) that need ProjLength/PropLength
--- to diverge from a simple RoundLength*(1-PropRatio)/RoundLength*PropRatio split.
function ACF.UpdateRoundSpecs(ToolData, Data, GUIData, CanTelescope)
	GUIData = GUIData or Data

	Data.Tracer = ToolData.Tracer and math.Round(Data.Caliber * 0.15, 2) or 0
	Data.TwoPiece = ToolData.TwoPiece or false

	-- Defaults to 1 so pre-slider dupes aren't silently buffed, matching where AddSlider seeds the var
	local MaxCaseScale = Data.MaxCaseScale or ACF.AmmoCaseScale
	local CaseScale    = math.Clamp(ToolData.CaseScale or 1, 1, MaxCaseScale)

	Data.CaseScale = CaseScale -- Case diameter is Caliber * CaseScale: the widest point of the round

	-- Recomputed from the base, not scaled in place, so repeated slider updates don't compound
	if Data.PropAreaBase then
		Data.PropArea = Data.PropAreaBase * CaseScale * CaseScale
	end

	local MinLength   = GUIData.MinProjLength + GUIData.MinPropLength
	local RoundLength = math.Clamp(ToolData.RoundLength or 0, MinLength, GUIData.MaxRoundLength)

	-- RatioMax is measured against MaxRoundLength, not RoundLength, so the propellant fraction is a
	-- per-class constant rather than one that climbs as the round is shortened. Dividing the class's
	-- fixed MaxPropLength by a shrinking RoundLength let any sub-maximum round reach a ratio of 1,
	-- leaving a zero-length projectile and a zero ProjMass for MuzzleVelocity and DragCoef to divide by.
	local RatioMin = math.max(0, 1 - GUIData.MaxProjLength / RoundLength)
	local RatioMax = math.min(1, GUIData.MaxPropLength / GUIData.MaxRoundLength)
	local PropRatio = math.Clamp(ToolData.PropRatio or 0, RatioMin, RatioMax)

	local PropLength = math.Round(RoundLength * PropRatio, 2)

	-- TelescopeRatio lets the projectile bore into the propellant, gated by CanTelescope so a leftover value from APFSDS doesn't leak into other ammo types sharing this ToolData.
	local TelescopeRatio  = CanTelescope and math.Clamp(ToolData.TelescopeRatio or 0, 0, 1) or 0
	local BaseProjLength  = RoundLength * (1 - PropRatio)
	local TelescopeLength = math.Round(math.min(PropLength * TelescopeRatio, GUIData.MaxProjLength - BaseProjLength), 2)
	local ProjLength      = math.Round(BaseProjLength + TelescopeLength, 2)
	local ProjVolume      = Data.ProjArea * ProjLength
	local PropVolume      = math.max(0, Data.PropArea * PropLength - Data.ProjArea * TelescopeLength)

	Data.RoundLength     = RoundLength
	Data.PropRatio       = PropRatio
	Data.TelescopeRatio  = TelescopeRatio
	Data.TelescopeLength = TelescopeLength
	Data.ProjLength      = ProjLength
	Data.PropLength      = PropLength
	Data.PropMass    = PropVolume * ACF.PDensity * 0.001 -- Volume of the case (hollowed out by any telescoped rod) * Powder density converted from g to kg
	Data.RoundVolume = ProjVolume + PropVolume

	GUIData.ProjVolume = ProjVolume
end

-- Using Simplified Garzke and Dulin Empirical Formula
-- See: http://www.navweaps.com/index_tech/tech-109.pdf
-- Speed in m/s, Mass in kg, Caliber in mm
-- Returns penetration in mm
function ACF.Penetration(Speed, Mass, Caliber)
	local Constant = 0.0004689 -- The constant is actually called "s"

	Mass    = Mass * 2.20462 -- From kg to lb
	Speed   = Speed * 3.28084 -- From m/s to ft/s
	Caliber = Caliber * ACF.MmToInch

	return Constant * Mass ^ 0.55 * Caliber ^ -0.65 * Speed ^ 1.1 * ACF.InchToMm
end

-- Inverse of ACF.Penetration, solved for Speed (Penetration in mm, Mass in kg, Caliber in mm, returns speed in m/s)
function ACF.CalcSpeed(Penetration, Mass, Caliber)
	local Constant = 0.0004689

	Mass        = Mass * 2.20462 -- From kg to lb
	Caliber     = Caliber * ACF.MmToInch
	Penetration = Penetration * ACF.MmToInch

	local Speed = (Penetration / (Constant * Mass ^ 0.55 * Caliber ^ -0.65)) ^ (1 / 1.1)

	return Speed / 3.28084 -- From ft/s to m/s
end

function ACF.MuzzleVelocity(PropMass, ProjMass, Efficiency)
	local Energy = PropMass * ACF.PropImpetus * (Efficiency or 1) * 1000 -- In joules

	return (2 * Energy / ProjMass) ^ 0.5
end

function ACF.Kinetic(Speed, Mass)
	Speed = Speed * ACF.InchToMeter -- From in/s to m/s

	return {
		Kinetic = Mass * 0.5 * Speed ^ 2 * 0.001, --Energy in KiloJoules
		Momentum = Speed * Mass,
	}
end

local Weaponry = {
	Piledrivers = Classes.Piledrivers,
	Missiles    = Classes.Missiles,
	Weapons     = Classes.Weapons,
}

-- In case you might want to add more
function ACF.AddWeaponrySource(Class)
	if not Class then return end
	if not Classes[Class] then return end

	Weaponry[Class] = Classes[Class]
end

function ACF.GetWeaponrySources()
	local Result = {}

	for K, V in pairs(Weaponry) do
		Result[K] = V
	end

	return Result
end

function ACF.FindWeaponrySource(ID)
	if not ID then return end

	for Key, Source in pairs(Weaponry) do
		if Classes.GetGroup(Source, ID) then
			return Key, Source
		end
	end
end

function ACF.GetWeaponBlacklist(Whitelist)
	local Result = {}

	for _, Source in pairs(Weaponry) do
		for ID in pairs(Source.GetEntries()) do
			if not Whitelist[ID] then
				Result[ID] = true
			end
		end
	end

	return Result
end

function ACF.RoundShellCapacity(PropMass, ProjArea, Caliber, ProjLength)
	local PropEnergy = ACF.PropImpetus * PropMass
	local MinWall = 0.2 + ((PropEnergy / ProjArea) ^ 0.7) * 0.035 --The minimal shell wall thickness required to survive firing at the current energy level
	local Length = math.max(ProjLength - MinWall, 0)
	local Radius = math.max((Caliber * 0.5) - MinWall, 0)
	local Volume = math.pi * Radius ^ 2 * Length

	return Volume, Length, Radius --Returning the cavity volume and the minimum wall thickness
end

function ACF.RicoProbability(Rico, Speed)
	local MinAngle = math.min(Rico - Speed * 0.066, 89)

	return {
		Min = math.Round(math.max(MinAngle, 0.01), 2),
		Mean = math.Round(math.max(MinAngle + (90 - MinAngle) / 2, 0.01), 2),
		Max = 90
	}
end

-- Formula from https://mathscinotes.wordpress.com/2013/10/03/parameter-determination-for-pejsa-velocity-model/
-- not terribly accurate for acf, particularly small caliber (7.62mm off by 120 m/s at 800m), but is good enough for quick indicator
-- Speed in m/s, Range in m
-- Result in in/s
function ACF.GetRangedSpeed(Speed, DragCoef, Range)
	local V0    = Speed * ACF.MeterToInch * ACF.Scale --initial velocity
	local D0    = DragCoef * V0 ^ 2 / ACF.DragDiv --initial drag
	local K1    = (D0 / (V0 ^ 1.5)) ^ -1 --estimated drag coefficient
	local Limit = 200 * K1 * V0 ^ 0.5 / 3937 -- Maximum possible range

	if Range >= Limit then return 0 end

	return (V0 ^ 0.5 - ((Range * ACF.MeterToInch) / (2 * K1))) ^ 2
end

function ACF.GetWeaponValue(Key, Caliber, Class, Weapon)
	if not isstring(Key) then return end

	if istable(Weapon) and Weapon[Key] then
		return Weapon[Key]
	end

	if not istable(Class) then return end

	local Values = Class[Key]

	if not Values then return end
	if not istable(Values) then return Values end
	if not isnumber(Caliber) then return end

	local Bounds  = Class.Caliber
	local Percent = (Caliber - Bounds.Min) / (Bounds.Max - Bounds.Min)

	return Lerp(Percent, Values.Min, Values.Max)
end

do -- MARK: Ammo capacity

	-- Packing constants
	local HEX_SPACING = 0.866 -- sqrt(3)/2 for hexagonal packing Y-axis spacing
	local HEX_OFFSET  = 0.5   -- Z-axis offset for alternating rows

	-- Math functions
	local floor = math.floor
	local max   = math.max
	local cos   = math.cos
	local sin   = math.sin
	local rad   = math.rad
	local deg   = math.deg
	local atan2 = math.atan2
	local pi    = math.pi

	local function GetModelDimensions(Round)
		local ModelPath = (not Round.IgnoreRackModel and Round.RackModel) or Round.Model

		-- Use ActualLength and ActualWidth if provided
		if Round.ActualLength and Round.ActualWidth then
			local ModelData = ACF.ModelData.GetModelData(ModelPath)
			local Offset    = ModelData and ModelData.Center and Vector(-ModelData.Center.x, 0, 0) or Vector()

			return Round.ActualLength, Round.ActualWidth, ModelPath, Offset
		end

		-- Use the dimensions of the actual model otherwise
		local ModelData = ACF.ModelData.GetModelData(ModelPath)

		if not ModelData or not ModelData.Size then
			return nil
		end

		local Size     = ModelData.Size
		local Center   = ModelData.Center
		local Length   = Size.x
		local Diameter = max(Size.y, Size.z)
		local Offset   = Vector(-Center.x, 0, 0)

		return Length, Diameter, ModelPath, Offset
	end

	ACF.GetModelDimensions = GetModelDimensions

	local function GetRoundProperties(Class, ToolData, BulletData)
		local Weapon  = Class.Lookup and Class.Lookup[ToolData.Weapon]
		local Caliber = Weapon and Weapon.Caliber or ToolData.Caliber
		local Round   = Weapon and Weapon.Round or Class.Round
		local Length, Diameter = GetModelDimensions(Round)

		if Length then
			return Vector(Length, Diameter, Diameter)
		end

		-- The case, not the projectile, sizes the cylinder the crate has to find room for
		Diameter = Caliber * (BulletData.CaseScale or ACF.GetMaxCaseScale(Class, Weapon)) * MM_TO_CM
		-- RoundLength, not PropLength + ProjLength -- ProjLength already includes any telescoped
		-- overlap into the propellant, so summing them would double-count that overlap.
		Length   = BulletData.RoundLength or (BulletData.PropLength + BulletData.ProjLength)

		-- Two-piece ammo stores each piece separately, so the stored unit is half the round's length.
		if BulletData.TwoPiece then Length = Length * 0.5 end

		return Vector(Length, Diameter, Diameter) / ACF.InchToCm
	end

	ACF.GetRoundProperties = GetRoundProperties

	do -- MARK: Box Ammo Crate Functions

		-- Hex packing given a count and round size
		local function HexDimY(count, size) return (count - 1) * size * HEX_SPACING + size end
		local function HexDimZ(count, size) return count * size + size * HEX_OFFSET end

		-- Inverse: how many fit in a given dimension
		local function HexCountY(dim, size) return floor((dim - size) / (size * HEX_SPACING) + 1) end
		local function HexCountZ(dim, size) return floor((dim - size * HEX_OFFSET) / size) end

		function ACF.GetCrateDimensions(arrangement, roundSize, hexPack)
			if hexPack then
				local dimensions = Vector(
					arrangement.x * roundSize.x,
					HexDimY(arrangement.y, roundSize.y),
					HexDimZ(arrangement.z, roundSize.z)
				)

				return dimensions, true
			end

			return Vector(arrangement.x, arrangement.y, arrangement.z) * roundSize, false
		end

		function ACF.GetRoundOffset(x, y, z, roundSize, hexPack)
			local localX = (x - 1) * roundSize.x

			if hexPack then
				return Vector(
					localX,
					(y - 1) * roundSize.y * HEX_SPACING,
					(z - 1) * roundSize.z + ((y - 1) % 2) * roundSize.z * HEX_OFFSET
				)
			end

			return Vector(localX, (y - 1) * roundSize.y, (z - 1) * roundSize.z)
		end

		function ACF.GetCrateSizeFromProjectileCounts(CountX, CountY, CountZ, Class, ToolData, BulletData, hexPack)
			local roundSize = GetRoundProperties(Class, ToolData, BulletData)

			return ACF.GetCrateDimensions(Vector(CountX, CountY, CountZ), roundSize, hexPack)
		end

		function ACF.GetMaxCounts(roundSize, maxLength, maxWidth, hexPack)
			local maxX = max(1, floor(maxLength / roundSize.x))
			local maxY = hexPack and HexCountY(maxWidth, roundSize.y) or floor(maxWidth / roundSize.y)
			local maxZ = hexPack and HexCountZ(maxWidth, roundSize.z) or floor(maxWidth / roundSize.z)

			return maxX, max(1, maxY), max(1, maxZ)
		end

		function ACF.GetProjectileCountsFromCrateSize(Size, Class, ToolData, BulletData, hexPack)
			local roundSize = GetRoundProperties(Class, ToolData, BulletData)
			local countX    = max(1, floor(Size.x / roundSize.x))
			local countY    = hexPack and HexCountY(Size.y, roundSize.y) or floor(Size.y / roundSize.y)
			local countZ    = hexPack and HexCountZ(Size.z, roundSize.z) or floor(Size.z / roundSize.z)

			return countX, max(1, countY), max(1, countZ)
		end
	end

	do -- MARK: Drums
		---------------------------------------------------------------------------
		-- Drum geometry:
		-- - Rounds are arranged in rings around a central axis (the drum's Z axis)
		-- - roundSize: x = length, y = diameter, z = diameter (rounds are cylindrical)
		-- - The inner radius is where the innermost faces of a ring meet
		--
		-- Two layouts exist, one per container shape. They differ in how a round sits,
		-- which decides what round length pays for -- and so in what the primary count
		-- (the X slider) even means. The locals stay named for the round orientation,
		-- which is the actual geometric distinction; the player-facing name is in Name:
		-- - Horizontal ("Cylinder", shown as "Carousel"): rounds lie flat pointing inward,
		--   the way a T-72's autoloader holds them, so LENGTH sets the diameter. X is
		--   ROUNDS PER RING; layers stack along Z a DIAMETER apart.
		-- - Vertical ("CylinderVertical", shown as "Drum"): rounds stand on end like
		--   cartridges in a drum magazine, so LENGTH sets the height of each stack. X is
		--   the NUMBER OF HEX RINGS filling the disk; stacks are a LENGTH apart.
		--
		-- Every layout exposes the same interface so callers never branch on shape:
		--   MinPrimary, PrimaryLabel, SecondaryLabel  (fields)
		--   GetMaxPrimary(roundSize, maxDiameter, hexPack)
		--   GetMaxStacks(roundSize, maxHeight, hexPack)
		--   GetPerDisk(primary)   -- rounds in one disk, which is NOT always the primary
		--   GetDimensions(primary, numStacks, roundSize, hexPack)
		--   GetRoundOffset(index, primary, numStacks, roundSize, hexPack)
		--   GetTier(index, primary)
		--   GetRenderTransform(localPos, ringAngle, modelAngle, boxAngle, roundSize, needsRotation)
		--
		-- Capacity is always GetPerDisk(primary) * numStacks.
		---------------------------------------------------------------------------

		local MIN_ROUNDS_PER_RING = 6
		local AXIS_Z              = Vector(0, 0, 1)

		-- Calculate inner radius from rounds per ring and round diameter
		local function GetInnerRadius(roundsPerRing, roundDiameter)
			return (roundsPerRing * roundDiameter) / (2 * pi)
		end

		local Horizontal = {
			Name            = "Carousel",
			MinPrimary      = MIN_ROUNDS_PER_RING,
			PrimaryLabel    = "Projectiles (Per Ring)",
			SecondaryLabel  = "Projectiles (Layers)"
		}

		-- Calculate drum height from layers and round diameter
		local function GetDrumHeight(numLayers, roundDiameter, hexPack)
			if numLayers <= 1 then return roundDiameter end

			return roundDiameter + (numLayers - 1) * roundDiameter * (hexPack and HEX_SPACING or 1)
		end

		function Horizontal.GetMaxPrimary(roundSize, maxDiameter)
			local availableForInner = maxDiameter - 2 * roundSize.x

			if availableForInner <= 0 then return MIN_ROUNDS_PER_RING end

			local maxRounds = floor(availableForInner * pi / roundSize.y)

			return max(MIN_ROUNDS_PER_RING, maxRounds)
		end

		--- A layer is exactly its ring; rounds meet tip to tip so there is no room inside it.
		function Horizontal.GetPerDisk(roundsPerRing)
			return roundsPerRing
		end

		function Horizontal.GetMaxStacks(roundSize, maxHeight, hexPack)
			local roundDiameter = roundSize.y

			if maxHeight < roundDiameter then return 1 end

			return max(1, floor((maxHeight - roundDiameter) / (roundDiameter * (hexPack and HEX_SPACING or 1)) + 1))
		end

		function Horizontal.GetDimensions(roundsPerRing, numLayers, roundSize, hexPack)
			local roundDiameter = roundSize.y
			local innerRadius   = GetInnerRadius(roundsPerRing, roundDiameter)
			local drumDiameter  = (innerRadius + roundSize.x) * 2

			return Vector(drumDiameter, drumDiameter, GetDrumHeight(numLayers, roundDiameter, hexPack))
		end

		function Horizontal.GetRoundOffset(index, roundsPerRing, numLayers, roundSize, hexPack)
			local roundLength   = roundSize.x
			local roundDiameter = roundSize.y

			local ringIndex  = (index - 1) % roundsPerRing
			local layerIndex = floor((index - 1) / roundsPerRing)

			local innerRadius    = GetInnerRadius(roundsPerRing, roundDiameter)
			local positionRadius = innerRadius + roundLength / 2

			-- Base angle with hex offset for alternating layers
			local baseAngle = (ringIndex / roundsPerRing) * 360
			local angle     = baseAngle + (hexPack and layerIndex % 2 == 1 and 180 / roundsPerRing or 0)

			-- XY position (drum axis is Z)
			local angleRad = rad(angle)
			local x        = cos(angleRad) * positionRadius
			local y        = sin(angleRad) * positionRadius

			-- Z position
			local z = 0

			if numLayers > 1 then
				local drumHeight = GetDrumHeight(numLayers, roundDiameter, hexPack)
				z = -drumHeight / 2 + roundDiameter / 2 + layerIndex * roundDiameter * (hexPack and HEX_SPACING or 1)
			end

			-- Round points inward: yaw = angle + 180
			return Vector(x, y, z), Angle(0, angle + 180, 0)
		end

		--- Two-piece rounds pair along the layer axis: charge below, projectile above.
		function Horizontal.GetTier(index, roundsPerRing)
			return floor((index - 1) / roundsPerRing)
		end

		function Horizontal.GetRenderTransform(localPos, ringAngle, modelAngle, boxAngle, roundSize, needsRotation)
			local outModel = Angle(modelAngle)
			local outBox   = Angle(boxAngle)

			outModel:RotateAroundAxis(AXIS_Z, ringAngle)
			outBox:RotateAroundAxis(AXIS_Z, ringAngle)

			-- Base-origin models extend along their forward (inward), so push out half a length to centre them
			local modelPos = localPos

			if needsRotation then
				modelPos = localPos + Vector(localPos.x, localPos.y, 0):GetNormalized() * roundSize.x * 0.5
			end

			return modelPos, outModel, outBox
		end

		---------------------------------------------------------------------------
		-- Vertical drums pack each disk as a hexagonal lattice, the densest arrangement
		-- of equal circles. The primary count is the number of RINGS, and every ring is
		-- filled completely, so a disk is always a whole hexagon rather than a ring with
		-- a gap in it:
		--   1 ring  = 1                 3 rings = 1 + 6 + 12 = 19
		--   2 rings = 1 + 6 = 7         4 rings = 1 + 6 + 12 + 18 = 37
		-- Ring r (counting the lone centre round as ring 0) holds 6r rounds, giving the
		-- centred hexagonal numbers, and its furthest rounds sit r diameters out.
		---------------------------------------------------------------------------

		local Vertical = {
			Name            = "Drum",
			MinPrimary      = 1,
			PrimaryLabel    = "Projectiles (Rings)",
			SecondaryLabel  = "Projectiles (Stack)"
		}

		-- Rounds stand on end, so a stack of them is exactly that many round lengths tall
		local function GetStackHeight(numStacks, roundLength)
			return max(1, numStacks) * roundLength
		end

		--- Centred hexagonal number: how many rounds a disk of `numRings` rings holds.
		function Vertical.GetPerDisk(numRings)
			local rings = max(1, numRings)

			return 3 * rings * (rings - 1) + 1
		end

		--- Places a zero-based slot on the hex lattice, in units of round diameters.
		-- Ring r has six corners r out at 60 degree steps, with r-1 rounds evenly spaced
		-- along each edge between them -- those land on lattice points because a hexagon's
		-- side equals its circumradius.
		local function HexLatticePosition(slot)
			if slot <= 0 then return 0, 0 end

			-- Walk out to the ring holding this slot
			local ring  = 1
			local first = 1

			while slot >= first + 6 * ring do
				first = first + 6 * ring
				ring  = ring + 1
			end

			local offset = slot - first
			local corner = floor(offset / ring) -- which of the six edges, 0-5
			local step   = offset % ring        -- how far along that edge

			local fromAngle = rad(corner * 60)
			local toAngle   = rad((corner + 1) * 60)
			local along     = step / ring

			local x = ring * (cos(fromAngle) + (cos(toAngle) - cos(fromAngle)) * along)
			local y = ring * (sin(fromAngle) + (sin(toAngle) - sin(fromAngle)) * along)

			return x, y
		end

		--- The outermost rounds sit (numRings - 1) diameters out, plus their own radius
		local function GetDiskRadius(numRings, roundDiameter)
			return (max(1, numRings) - 0.5) * roundDiameter
		end

		function Vertical.GetMaxPrimary(roundSize, maxDiameter)
			-- Solving GetDiskRadius(n, d) <= maxDiameter / 2 for n
			return max(1, floor(maxDiameter / (2 * roundSize.y) + 0.5))
		end

		function Vertical.GetMaxStacks(roundSize, maxHeight)
			return max(1, floor(maxHeight / roundSize.x))
		end

		function Vertical.GetDimensions(numRings, numStacks, roundSize)
			local drumDiameter = GetDiskRadius(numRings, roundSize.y) * 2

			return Vector(drumDiameter, drumDiameter, GetStackHeight(numStacks, roundSize.x))
		end

		function Vertical.GetRoundOffset(index, numRings, numStacks, roundSize)
			local roundLength   = roundSize.x
			local roundDiameter = roundSize.y

			local perDisk    = Vertical.GetPerDisk(numRings)
			local stackIndex = floor((index - 1) / perDisk)
			local x, y       = HexLatticePosition((index - 1) % perDisk)

			-- The lattice is in diameters; scale it out to real units
			x = x * roundDiameter
			y = y * roundDiameter

			-- Stacked bottom-up along Z, one round length per level. The disk is already the
			-- densest arrangement there is, so hex packing has nothing left to buy here.
			local stackHeight = GetStackHeight(numStacks, roundLength)
			local z           = -stackHeight / 2 + roundLength / 2 + stackIndex * roundLength

			-- Cylinders have no meaningful facing; yaw outward so the drum still reads as a ring
			local angle = (x == 0 and y == 0) and 0 or deg(atan2(y, x))

			return Vector(x, y, z), Angle(0, angle, 0)
		end

		--- Two-piece rounds pair along the stack: charge below, projectile above.
		function Vertical.GetTier(index, numRings)
			return floor((index - 1) / Vertical.GetPerDisk(numRings))
		end

		function Vertical.GetRenderTransform(localPos, ringAngle, _, boxAngle, roundSize, needsRotation)
			-- Cartridge models run along their own Z, which is already this drum's stacking axis, so
			-- they need no pitch correction here -- the reverse of the horizontal drum. Models whose
			-- length runs along X still have to be stood up.
			local outModel = Angle(boxAngle)

			if not needsRotation then
				outModel:RotateAroundAxis(outModel:Right(), -90)
			end

			-- The box is in crate space (x = length), so it always stands up to match the round
			local outBox = Angle(boxAngle)
			outBox:RotateAroundAxis(outBox:Right(), -90)

			outModel:RotateAroundAxis(AXIS_Z, ringAngle)
			outBox:RotateAroundAxis(AXIS_Z, ringAngle)

			-- Base-origin models grow up the stacking axis from their origin, so drop half a length to centre them
			local modelPos = localPos

			if needsRotation then
				modelPos = localPos - Vector(0, 0, roundSize.x * 0.5)
			end

			return modelPos, outModel, outBox
		end

		--- Drum layouts, keyed by the container shape that uses them.
		ACF.DrumLayouts = {
			Cylinder         = Horizontal,
			CylinderVertical = Vertical,
		}

		--- True if the given ammo shape is a drum of any orientation.
		function ACF.IsDrumShape(Shape)
			return ACF.DrumLayouts[Shape] ~= nil
		end

		--- Returns the drum layout for an ammo shape, or nil for non-drum shapes.
		function ACF.GetDrumLayout(Shape)
			return ACF.DrumLayouts[Shape]
		end

		function ACF.GetDrumCrateSizeFromProjectileCounts(primary, numStacks, Class, ToolData, BulletData, hexPack, Shape)
			local roundSize = GetRoundProperties(Class, ToolData, BulletData)
			local Layout    = ACF.DrumLayouts[Shape] or Horizontal

			return Layout.GetDimensions(primary, numStacks, roundSize, hexPack)
		end
	end
end