local ACF     = ACF
local Classes = ACF.Classes

local function GetWeaponSpecs(ToolData)
	local Source = Classes[ToolData.Destiny]
	local Class = Source and ACF.GetClassGroup(Source, ToolData.Weapon)

	if not Class then return end

	if not Class.IsScalable then
		local Weapon = Class.Lookup[ToolData.Weapon]
		local Round  = Weapon.Round

		return Weapon.Caliber, Round.MaxLength, Round.PropMass
	end

	local Bounds  = Class.Caliber
	local Round   = Class.Round
	local Caliber = math.Clamp(ToolData.Caliber or Bounds.Base, Bounds.Min, Bounds.Max)
	local Scale   = Caliber / Bounds.Base

	return Caliber, Round.MaxLength * Scale, Round.PropMass * Scale
end

function ACF.RoundBaseGunpowder(ToolData, Data)
	local Caliber, MaxLength, PropMass = GetWeaponSpecs(ToolData)
	local GUIData = {}

	if not Caliber then return Data, GUIData end

	Data.Caliber = Caliber * 0.1 -- Bullet caliber will have to stay in cm
	Data.FrArea = 3.1416 * (Data.Caliber * 0.5) ^ 2

	GUIData.MaxRoundLength = math.Round(MaxLength * (Data.LengthAdj or 1), 2)
	GUIData.MinPropLength = 0.01
	GUIData.MinProjLength = math.Round(Data.Caliber * 1.5, 2)

	local DesiredProp = math.Round(PropMass * 1000 / ACF.PDensity / Data.FrArea, 2)
	local AllowedProp = GUIData.MaxRoundLength - GUIData.MinProjLength

	GUIData.MaxPropLength = math.min(DesiredProp, AllowedProp)
	GUIData.MaxProjLength = GUIData.MaxRoundLength - GUIData.MinPropLength

	ACF.UpdateRoundSpecs(ToolData, Data, GUIData)

	return Data, GUIData
end

function ACF.UpdateRoundSpecs(ToolData, Data, GUIData)
	GUIData = GUIData or Data

	Data.Priority = Data.Priority or "Projectile"
	Data.Tracer = ToolData.Tracer and math.Round(Data.Caliber * 0.15, 2) or 0

	local Projectile = math.Clamp(ToolData.Projectile + Data.Tracer, GUIData.MinProjLength, GUIData.MaxProjLength)
	local Propellant = math.Clamp(ToolData.Propellant, GUIData.MinPropLength, GUIData.MaxPropLength)

	if Data.Priority == "Projectile" then
		Propellant = math.min(Propellant, GUIData.MaxRoundLength - Projectile, GUIData.MaxPropLength)
	elseif Data.Priority == "Propellant" then
		Projectile = math.min(Projectile, GUIData.MaxRoundLength - Propellant, GUIData.MaxProjLength)
	end

	Data.ProjLength = math.Round(Projectile, 2) - Data.Tracer
	Data.PropLength = math.Round(Propellant, 2)
	Data.PropMass = Data.FrArea * ACF.AmmoCaseScale ^ 2 * (Data.PropLength * ACF.PDensity * 0.001) --Volume of the case as a cylinder * Powder density converted from g to kg
	Data.RoundVolume = Data.FrArea * ACF.AmmoCaseScale ^ 2 * (Data.ProjLength + Data.PropLength)

	GUIData.ProjVolume = Data.FrArea * Data.ProjLength
end

local Weaponry = {
	Piledrivers = Classes.Piledrivers,
	Missiles = Classes.Missiles,
	Weapons = Classes.Weapons,
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
		if ACF.GetClassGroup(Source, ID) then
			return Key, Source
		end
	end
end

function ACF.GetWeaponBlacklist(Whitelist)
	local Result = {}

	for _, Source in pairs(Weaponry) do
		for ID in pairs(Source) do
			if not Whitelist[ID] then
				Result[ID] = true
			end
		end
	end

	return Result
end

function ACF.RoundShellCapacity(Momentum, FrArea, Caliber, ProjLength)
	local MinWall = 0.2 + ((Momentum / FrArea) ^ 0.7) * 0.02 --The minimal shell wall thickness required to survive firing at the current energy level	
	local Length = math.max(ProjLength - MinWall, 0)
	local Radius = math.max((Caliber * 0.5) - MinWall, 0)
	local Volume = 3.1416 * Radius ^ 2 * Length

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

--Formula from https://mathscinotes.wordpress.com/2013/10/03/parameter-determination-for-pejsa-velocity-model/
--not terribly accurate for acf, particularly small caliber (7.62mm off by 120 m/s at 800m), but is good enough for quick indicator
--range in m, vel is m/s
function ACF.PenRanging(MuzzleVel, DragCoef, ProjMass, PenArea, LimitVel, Range)
	local V0 = MuzzleVel * 39.37 * ACF.Scale --initial velocity
	local D0 = DragCoef * V0 ^ 2 / ACF.DragDiv --initial drag
	local K1 = (D0 / (V0 ^ 1.5)) ^ -1 --estimated drag coefficient
	local Vel = (math.sqrt(V0) - ((Range * 39.37) / (2 * K1))) ^ 2
	local Pen = ACF_Kinetic(Vel, ProjMass, LimitVel).Penetration / PenArea * ACF.KEtoRHA

	return math.Round(Vel * 0.0254, 2), math.Round(Pen, 2)
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

	-- BoxSize is just OBBMaxs-OBBMins
	-- Removed caliber and round length inputs, uses GunData and BulletData now
	-- AddSpacing is just extra spacing (directly reduces storage, but can later make it harder to detonate)
	-- AddArmor is literally just extra armor on the ammo crate, but inside (also directly reduces storage)
	-- For missiles/bombs, they MUST have ActualLength and ActualWidth (of the model in cm, and in the round table) to use this, otherwise it will fall back to the original calculations
	-- Made by LiddulBOFH :)
	function ACF.GetAmmoCrateCapacity(BoxSize, GunData, BulletData, AddSpacing, AddArmor)
		-- gives a nice number of rounds per refill box
		if BulletData.Type == "Refill" then return math.ceil(BoxSize.x * BoxSize.y * BoxSize.z * 0.01) end

		local GunCaliber   = GunData.Caliber * 0.1 -- mm to cm
		local RoundCaliber = GunCaliber * ACF.AmmoCaseScale
		local RoundLength  = BulletData.PropLength + BulletData.ProjLength + (BulletData.Tracer or 0)
		local ExtraData    = {}

		-- Filters for missiles, and sets up data
		if GunData.Round.ActualWidth then
			RoundCaliber = GunData.Round.ActualWidth
			RoundLength = GunData.Round.ActualLength
			ExtraData.IsRacked = true
		elseif GunData.Class.Entity == "acf_rack" then
			local Efficiency = 0.1576 * ACF.AmmoMod
			local Volume     = math.floor(BoxSize.x * BoxSize.y * BoxSize.z) * Efficiency
			local CapMul     = (Volume > 40250) and ((math.log(Volume * 0.00066) / math.log(2) - 4) * 0.15 + 1) or 1

			return math.floor(CapMul * Volume * 16.38 / BulletData.RoundVolume) -- Fallback to old capacity
		end

		local Rounds  = 0
		local Spacing = math.max(AddSpacing, 0) + 0.125
		local MagSize = GunData.MagSize or 1
		local IsBoxed = GunData.Class.IsBoxed
		local Rotate

		-- Converting everything to source units
		local Length = RoundLength * 0.3937 -- cm to inches
		local Width  = RoundCaliber * 0.3937 -- cm to inches
		local Height = Width

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

		if AddArmor then
			-- Converting millimeters to inches then multiplying by two since the armor is on both sides
			local BoxArmor = AddArmor * 0.039 * 2
			local X = math.max(BoxSize.x - BoxArmor, 0)
			local Y = math.max(BoxSize.y - BoxArmor, 0)
			local Z = math.max(BoxSize.z - BoxArmor, 0)

			BoxSize = Vector(X, Y, Z)
		end

		local ShortestFit = ShortestSize(Length, Width, Height, Spacing, BoxSize, ExtraData)

		-- If ShortestFit is nil, that means the round isn't able to fit at all in the box
		-- If its a racked munition that doesn't fit, it will go ahead and try to fit 2-pice
		-- Otherwise, checks if the caliber is over 100mm before trying 2-piece ammunition
		-- It will flatout not do anything if its boxed and not fitting
		if not ShortestFit and not ExtraData.IsBoxed and (GunCaliber >= 10 or ExtraData.IsRacked) then
			Length = Length * 0.5 -- Not exactly accurate, but cuts the round in two
			Width = Width * 2 -- two pieces wide

			ExtraData.IsTwoPiece = true

			local ShortestFit1, Count1 = ShortestSize(Length, Width, Height, Spacing, BoxSize, ExtraData, true)
			local ShortestFit2, Count2 = ShortestSize(Length, Height, Width, Spacing, BoxSize, ExtraData, true)

			if Count1 > Count2 then
				ShortestFit = ShortestFit1
			else
				ShortestFit = ShortestFit2
				Rotate = true
			end
		end

		-- If it still doesn't fit the box, then it's just too small
		if ShortestFit then
			local SizeX, SizeY, SizeZ, LocalAng = GetBoxDimensions(ShortestFit, BoxSize)

			ExtraData.LocalAng = LocalAng
			ExtraData.RoundSize = Vector(Length, Width, Height)

			-- In case the round was cut and needs to be rotated, then we do some minor changes
			if Rotate then
				local OldY = SizeY

				SizeY = SizeZ
				SizeZ = OldY

				ExtraData.LocalAng = ExtraData.LocalAng + Angle(0, 0, 90)
			end

			local RoundsX, RoundsY, RoundsZ = GetRoundsPerAxis(SizeX, SizeY, SizeZ, Length, Width, Height, Spacing)

			ExtraData.FitPerAxis = Vector(RoundsX, RoundsY, RoundsZ)

			Rounds = RoundsX * RoundsY * RoundsZ * MagSize
		end

		return Rounds, ExtraData
	end
end