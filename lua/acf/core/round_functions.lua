local ACF     = ACF
local Classes = ACF.Classes
local math    = math

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
	local Radius    = Specs.Caliber * 0.05 -- Radius in cm
	local CaseScale = ToolData.CasingScale or ACF.AmmoCaseScale

	Data.Caliber    = Specs.Caliber * 0.1 -- Bullet caliber will have to stay in cm
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

	local Projectile = math.Clamp(ToolData.Projectile + Data.Tracer, GUIData.MinProjLength, GUIData.MaxProjLength)
	local Propellant = math.Clamp(ToolData.Propellant, GUIData.MinPropLength, GUIData.MaxPropLength)

	if Data.Priority == "Projectile" then
		Propellant = math.min(Propellant, GUIData.MaxRoundLength - Projectile, GUIData.MaxPropLength)
	elseif Data.Priority == "Propellant" then
		Projectile = math.min(Projectile, GUIData.MaxRoundLength - Propellant, GUIData.MaxProjLength)
	end

	local ProjLength = math.Round(Projectile, 2) - Data.Tracer
	local PropLength = math.Round(Propellant, 2)
	local ProjVolume = Data.ProjArea * ProjLength
	local PropVolume = Data.PropArea * PropLength

	Data.ProjLength  = ProjLength
	Data.PropLength  = PropLength
	Data.PropMass    = Data.PropArea * (Data.PropLength * ACF.PDensity * 0.001) --Volume of the case as a cylinder * Powder density converted from g to kg
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
	Caliber = Caliber * 0.0393701 -- From mm to in

	return Constant * Mass ^ 0.55 * Caliber ^ -0.65 * Speed ^ 1.1 * 25.4 -- 25.4 because converting from in to mm
end

function ACF.MuzzleVelocity(PropMass, ProjMass, Efficiency)
	local Energy = PropMass * ACF.PropImpetus * (Efficiency or 1) * 1000 -- In joules

	return (2 * Energy / ProjMass) ^ 0.5
end

function ACF.Kinetic(Speed, Mass)
	Speed = Speed * 0.0254 -- From in/s to m/s

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
	local V0    = Speed * 39.37 * ACF.Scale --initial velocity
	local D0    = DragCoef * V0 ^ 2 / ACF.DragDiv --initial drag
	local K1    = (D0 / (V0 ^ 1.5)) ^ -1 --estimated drag coefficient
	local Limit = 200 * K1 * V0 ^ 0.5 / 3937 -- Maximum possible range

	if Range >= Limit then return 0 end

	return (V0 ^ 0.5 - ((Range * 39.37) / (2 * K1))) ^ 2
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
	local Axises = {
		x = { Y = "y", Z = "z", Ang = Angle() },
		y = { Y = "x", Z = "z", Ang = Angle(0, 90) },
		z = { Y = "x", Z = "y", Ang = Angle(90, 90) }
	}

	local function GetBoxDimensions(Axis, Size)
		local AxisInfo = Axises[Axis]
		local Y = Size[AxisInfo.Y]
		local Z = Size[AxisInfo.Z]

		return Size[Axis], Y, Z, AxisInfo.Ang
	end

	local function GetRoundsPerAxis(SizeX, SizeY, SizeZ, Length, Width, Height, Spacing)
		-- Omitting spacing for the axises with just one round
		if math.floor(SizeX / Length) > 1 then Length = Length + Spacing end
		if math.floor(SizeY / Width) > 1 then Width = Width + Spacing end
		if math.floor(SizeZ / Height) > 1 then Height = Height + Spacing end

		local RoundsX = math.floor(SizeX / Length)
		local RoundsY = math.floor(SizeY / Width)
		local RoundsZ = math.floor(SizeZ / Height)

		return RoundsX, RoundsY, RoundsZ
	end

	-- Split this off from the original function,
	-- All this does is compare a distance against a table of distances with string indexes for the shortest fitting size
	-- It returns the string index of the dimension, or nil if it fails to fit
	local function ShortestSize(Length, Width, Height, Spacing, Dimensions, ExtraData, IsIrregular)
		local BestCount = 0
		local BestAxis

		for Axis in pairs(Axises) do
			local X, Y, Z = GetBoxDimensions(Axis, Dimensions)
			local Multiplier = 1

			if not IsIrregular then
				local MagSize = ExtraData.MagSize

				if MagSize and MagSize > 0 then
					Multiplier = MagSize
				end
			end

			local RoundsX, RoundsY, RoundsZ = GetRoundsPerAxis(X, Y, Z, Length, Width, Height, Spacing)
			local Count = RoundsX * RoundsY * RoundsZ * Multiplier

			if Count > BestCount then
				BestAxis = Axis
				BestCount = Count
			end
		end

		return BestAxis, BestCount
	end

	-- Made by LiddulBOFH :)
	function ACF.GetAmmoCrateCapacity(Size, WeaponClass, ToolData, BulletData)
		if BulletData.Type == "Refill" then -- Gives a nice number of rounds per refill box
			return math.ceil(Size.x * Size.y * Size.z * 0.01)
		end

		local Weapon    = WeaponClass.Lookup[ToolData.Weapon]
		local Caliber   = Weapon and Weapon.Caliber or ToolData.Caliber
		local Round     = Weapon and Weapon.Round or WeaponClass.Round
		local Width     = Caliber * ACF.AmmoCaseScale * 0.1 -- mm to cm
		local Length    = BulletData.PropLength + BulletData.ProjLength + BulletData.Tracer
		local MagSize   = math.floor(ACF.GetWeaponValue("MagSize", Caliber, WeaponClass, Weapon) or 1)
		local Spacing   = math.max(0, ToolData.AmmoPadding or ACF.AmmoPadding) * Width * 0.1 + 0.125
		local IsBoxed   = WeaponClass.IsBoxed
		local Rounds    = 0
		local ExtraData = {}
		local BoxSize, Height, Rotate

		-- Weapons are able to define the size of their ammo inside crates
		if Round.ActualWidth then
			local Scale = Weapon and 1 or Caliber / Class.Caliber.Base

			Width  = Round.ActualWidth * Scale -- This was made before the big measurement change throughout, where I measured shit in actual source units
			Length = Round.ActualLength * Scale -- as such, this corrects all missiles to the correct size

			ExtraData.IsRacked = true
		end

		do -- Defining the actual boxsize
			local Armor = math.max(0, ToolData.AmmoArmor or ACF.AmmoArmor) * 0.039 * 2
			local X     = math.max(Size.x - Armor, 0)
			local Y     = math.max(Size.y - Armor, 0)
			local Z     = math.max(Size.z - Armor, 0)

			BoxSize = Vector(X, Y, Z)
		end

		do -- Converting everything to source units
			Length = Length * 0.3937 -- cm to in
			Width  = Width * 0.3937 -- cm to in
			Height = Width
		end

		ExtraData.Spacing = Spacing

		-- This block alters the stored round size, making it more like a container of the rounds
		-- This cuts a little bit of ammo storage out
		if MagSize > 1 then
			if IsBoxed and not ExtraData.IsRacked then
				-- Makes certain automatic ammo stored by boxes
				Width = Width * math.sqrt(MagSize)
				Height = Width

				ExtraData.MagSize = MagSize
				ExtraData.IsBoxed = true
			else
				MagSize = 1
			end
		end

		local ShortestFit = ShortestSize(Length, Width, Height, Spacing, BoxSize, ExtraData)

		-- If ShortestFit is nil, that means the round isn't able to fit at all in the box
		-- If its a racked munition that doesn't fit, it will go ahead and try to fit 2-pice
		-- Otherwise, checks if the caliber is over 100mm before trying 2-piece ammunition
		-- It will flatout not do anything if its boxed and not fitting
		if not ShortestFit and not ExtraData.IsBoxed and (ExtraData.IsRacked or Caliber >= 100) then
			Length = Length * 0.5 -- Not exactly accurate, but cuts the round in two
			Width = Width * 2 -- two pieces wide

			ExtraData.IsTwoPiece = true

			local ShortestFit1, Count1 = ShortestSize(Length, Width, Height, Spacing, BoxSize, ExtraData, true)
			local ShortestFit2, Count2 = ShortestSize(Length, Height, Width, Spacing, BoxSize, ExtraData, true)

			Rotate      = Count1 <= Count2
			ShortestFit = Either(Rotate, ShortestFit2, ShortestFit1) -- ShortestFitX values could be nil, a ternary won't work here
		end

		-- If it still doesn't fit the box, then it's just too small
		if ShortestFit then
			local SizeX, SizeY, SizeZ, LocalAng = GetBoxDimensions(ShortestFit, BoxSize)

			ExtraData.LocalAng = LocalAng
			ExtraData.RoundSize = Vector(Length, Width, Height)

			-- In case the round was cut and needs to be rotated, then we do some minor changes
			if Rotate then
				SizeY, SizeZ = SizeZ, SizeY -- Interchanging the values

				ExtraData.LocalAng = ExtraData.LocalAng + Angle(0, 0, 90)
			end

			local RoundsX, RoundsY, RoundsZ = GetRoundsPerAxis(SizeX, SizeY, SizeZ, Length, Width, Height, Spacing)

			ExtraData.FitPerAxis = Vector(RoundsX, RoundsY, RoundsZ)

			Rounds = RoundsX * RoundsY * RoundsZ * MagSize
		end

		return Rounds, ExtraData
	end
end
