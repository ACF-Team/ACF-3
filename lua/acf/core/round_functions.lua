local ACF     = ACF
local Classes = ACF.Classes
local math    = math
local MM_TO_CM = ACF.MmToInch * ACF.InchToCm -- Millimeters to centimeters


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

		Result.Caliber    = Weapon.Caliber
		Result.MaxLength  = Round.MaxLength
		Result.PropLength = Round.PropLength
		Result.ProjLength = Round.ProjLength
		Result.Efficiency = Round.Efficiency
	else
		local Bounds  = Class.Caliber
		local Round   = Class.Round
		local Caliber = math.Clamp(ToolData.Caliber or Bounds.Base, Bounds.Min, Bounds.Max)
		local Scale   = Caliber / Bounds.Base
		local ProjLen = Round.ProjLength

		Result.Caliber    = Caliber
		Result.MaxLength  = Round.MaxLength * Scale
		Result.PropLength = Round.PropLength * Scale
		Result.ProjLength = ProjLen and ProjLen * Scale
		Result.Efficiency = Round.Efficiency
	end

	return Result
end

function ACF.RoundBaseGunpowder(ToolData, Data)
	local Specs   = GetWeaponSpecs(ToolData)
	local GUIData = {}

	if not Specs then return Data, GUIData end

	local Length    = math.Round(Specs.MaxLength * (Data.LengthAdj or 1), 2)
	local Radius    = Specs.Caliber * MM_TO_CM * 0.5 -- Radius in cm
	local CaseScale = ToolData.CasingScale or ACF.AmmoCaseScale

	Data.Caliber    = Specs.Caliber * MM_TO_CM -- Bullet caliber will have to stay in cm
	Data.Diameter   = Data.Caliber * (Data.ProjScale or 1) -- Real caliber of the projectile
	Data.ProjArea   = math.pi * (Radius * (Data.ProjScale or 1)) ^ 2
	Data.PropArea   = math.pi * (Radius * (Data.PropScale or 1) * CaseScale) ^ 2
	Data.Efficiency = Specs.Efficiency or 1

	GUIData.MaxRoundLength = Length
	GUIData.MinPropLength  = 0.01
	GUIData.MinProjLength  = math.Round(Data.Caliber * 1.5, 2)
	GUIData.MaxPropLength  = math.min(Specs.PropLength, Length - GUIData.MinProjLength)
	GUIData.MaxProjLength  = math.min(Specs.ProjLength or Length, Length - GUIData.MinPropLength)

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

	return Data, GUIData
end

function ACF.UpdateRoundSpecs(ToolData, Data, GUIData)
	GUIData = GUIData or Data

	Data.Priority = Data.Priority or "Projectile"
	Data.Tracer   = ToolData.Tracer and math.Round(Data.Caliber * 0.15, 2) or 0

	local Projectile = math.Clamp(ToolData.Projectile, GUIData.MinProjLength, GUIData.MaxProjLength)
	local Propellant = math.Clamp(ToolData.Propellant, GUIData.MinPropLength, GUIData.MaxPropLength)

	if Data.Priority == "Projectile" then
		Propellant = math.min(Propellant, GUIData.MaxRoundLength - Projectile, GUIData.MaxPropLength)
	elseif Data.Priority == "Propellant" then
		Projectile = math.min(Projectile, GUIData.MaxRoundLength - Propellant, GUIData.MaxProjLength)
	end

	local ProjLength = math.Round(Projectile, 2)
	local PropLength = math.Round(Propellant, 2)
	local ProjVolume = Data.ProjArea * ProjLength
	local PropVolume = Data.PropArea * PropLength

	Data.ProjLength  = ProjLength
	Data.PropLength  = PropLength
	Data.PropMass    = Data.PropArea * (Data.PropLength * ACF.PDensity * 0.001) -- Volume of the case as a cylinder * Powder density converted from g to kg
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

-- changes here will be automatically reflected in the armor properties tool
function ACF.CalcArmor(Area, Ductility, Mass)
	return (Mass * 1000 / Area / 0.78) / (1 + Ductility) ^ 0.5 * ACF.ArmorMod
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

do -- Ammo crate capacity calculation

	-- Packing constants
	local HEX_SPACING = 0.866 -- sqrt(3)/2 for hexagonal packing Y-axis spacing
	local HEX_OFFSET  = 0.5   -- Z-axis offset for alternating rows

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
		local Diameter = math.max(Size.y, Size.z)
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

		Diameter = Caliber * ACF.AmmoCaseScale * MM_TO_CM
		Length = BulletData.PropLength + BulletData.ProjLength

		return Vector(Length, Diameter, Diameter) / ACF.InchToCm
	end

	-- Returns true if hex packing uses less space than square packing
	local function ShouldUseHexPacking(countY, countZ)
		if countY <= 1 or countZ <= 1 then return false end

		local squareArea = countY * countZ
		local hexArea    = ((countY - 1) * HEX_SPACING + 1) * (countZ + HEX_OFFSET)

		return hexArea < squareArea
	end

	-- Hex packing given a count and round size
	local function HexDimY(count, size) return (count - 1) * size * HEX_SPACING + size end
	local function HexDimZ(count, size) return count * size + size * HEX_OFFSET end

	-- Inverse: how many fit in a given dimension
	local function HexCountY(dim, size) return math.floor((dim - size) / (size * HEX_SPACING) + 1) end
	local function HexCountZ(dim, size) return math.floor((dim - size * HEX_OFFSET) / size) end

	function ACF.GetCrateDimensions(arrangement, roundSize)
		if ShouldUseHexPacking(arrangement.y, arrangement.z) then
			local dimensions = Vector(
				arrangement.x * roundSize.x,
				HexDimY(arrangement.y, roundSize.y),
				HexDimZ(arrangement.z, roundSize.z)
			)

			return dimensions, true
		end

		return Vector(arrangement.x, arrangement.y, arrangement.z) * roundSize, false
	end

	function ACF.GetRoundOffset(x, y, z, roundSize, arrangement)
		local localX = (x - 1) * roundSize.x

		if ShouldUseHexPacking(arrangement.y, arrangement.z) then
			return Vector(
				localX,
				(y - 1) * roundSize.y * HEX_SPACING,
				(z - 1) * roundSize.z + ((y - 1) % 2) * roundSize.z * HEX_OFFSET
			)
		end

		return Vector(localX, (y - 1) * roundSize.y, (z - 1) * roundSize.z)
	end

	function ACF.GetCrateSizeFromProjectileCounts(CountX, CountY, CountZ, Class, ToolData, BulletData)
		local roundSize = GetRoundProperties(Class, ToolData, BulletData)

		return ACF.GetCrateDimensions(Vector(CountX, CountY, CountZ), roundSize)
	end

	function ACF.GetMaxCounts(roundSize, maxLength, maxWidth, currentY, currentZ)
		local maxX       = math.max(1, math.floor(maxLength / roundSize.x))
		local maxYSquare = math.floor(maxWidth / roundSize.y)
		local maxZSquare = math.floor(maxWidth / roundSize.z)
		local maxYHex    = HexCountY(maxWidth, roundSize.y)
		local maxZHex    = HexCountZ(maxWidth, roundSize.z)

		local maxY = ShouldUseHexPacking(maxYHex, currentZ) and maxYHex or maxYSquare
		local maxZ = ShouldUseHexPacking(currentY, maxZHex) and maxZHex or maxZSquare

		return maxX, math.max(1, maxY), math.max(1, maxZ)
	end

	function ACF.GetProjectileCountsFromCrateSize(Size, Class, ToolData, BulletData)
		local roundSize = GetRoundProperties(Class, ToolData, BulletData)
		local countX    = math.max(1, math.floor(Size.x / roundSize.x))
		local sqY, sqZ  = math.floor(Size.y / roundSize.y), math.floor(Size.z / roundSize.z)
		local hexY      = HexCountY(Size.y, roundSize.y)
		local hexZ      = HexCountZ(Size.z, roundSize.z)

		if ShouldUseHexPacking(hexY, hexZ) then
			return countX, math.max(1, hexY), math.max(1, hexZ)
		end

		return countX, math.max(1, sqY), math.max(1, sqZ)
	end

end
