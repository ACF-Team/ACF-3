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
