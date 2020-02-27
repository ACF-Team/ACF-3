function ACF.RoundBaseGunpowder(ToolData, Data)
	local ClassData = ACF.Classes.Weapons[ToolData.WeaponClass]
	local WeaponData = ClassData and ClassData.Lookup[ToolData.Weapon]

	if not WeaponData then return Data, {} end

	local RoundData = WeaponData.Round
	local Projectile = ToolData.Projectile
	local Propellant = ToolData.Propellant
	local GUIData = {}

	Data.Caliber = WeaponData.Caliber
	Data.FrArea = 3.1416 * (Data.Caliber * 0.05) ^ 2
	Data.Tracer = ToolData.Tracer and math.min(50 / Data.Caliber, 2.5) or 0

	GUIData.MaxTotalLength = RoundData.MaxLength * (Data.LengthAdj or 1)

	local PropMax = RoundData.PropMass * 1000 / ACF.PDensity / Data.FrArea --Current casing absolute max propellant capacity
	local CurLength = Projectile + math.min(Propellant, PropMax) + Data.Tracer

	GUIData.MinPropLength = 0.01
	GUIData.MaxPropLength = math.max(math.min(GUIData.MaxTotalLength - CurLength + Propellant, PropMax), GUIData.MinPropLength) --Check if the desired prop lenght fits in the case and doesn't exceed the gun max
	GUIData.MinProjLength = Data.Caliber * 0.15
	GUIData.MaxProjLength = math.max(GUIData.MaxTotalLength - CurLength + Projectile, GUIData.MinProjLength) --Check if the desired proj lenght fits in the case

	local Ratio = math.min((GUIData.MaxTotalLength - Data.Tracer) / (Projectile + math.min(Propellant, PropMax)), 1)

	Data.ProjLength = math.Clamp(Projectile * Ratio, GUIData.MinProjLength, GUIData.MaxProjLength)
	Data.PropLength = math.Clamp(Propellant * Ratio, GUIData.MinPropLength, GUIData.MaxPropLength)
	Data.PropMass = Data.FrArea * (Data.PropLength * ACF.PDensity / 1000) --Volume of the case as a cylinder * Powder density converted from g to kg
	Data.RoundVolume = Data.FrArea * (Data.ProjLength + Data.PropLength)

	GUIData.ProjVolume = Data.FrArea * Data.ProjLength

	return Data, GUIData
end

local Classes = ACF.Classes
local Ignore = {
	-- Old
	GunClass = true,
	Radar = true,
	Rack = true,
	-- New/upcoming
	Components = true,
	AmmoTypes = true,
	FuelTanks = true,
	Gearboxes = true,
	Guidances = true,
	Engines = true,
	Sensors = true,
	Crates = true,
	Racks = true,
	Fuzes = true,
}

function ACF.GetWeaponBlacklist(Whitelist)
	local Result = {}

	for K, V in pairs(Classes) do
		if Ignore[K] then continue end

		for ID in pairs(V) do
			if Whitelist[ID] then continue end

			Result[ID] = true
		end
	end

	return Result
end

function ACF.RoundShellCapacity(Momentum, FrArea, Caliber, ProjLength)
	local MinWall = 0.2 + ((Momentum / FrArea) ^ 0.7) * 0.02 --The minimal shell wall thickness required to survive firing at the current energy level	
	local Length = math.max(ProjLength - MinWall, 0)
	local Radius = math.max((Caliber * 0.05) - MinWall, 0)
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

	return Vel * 0.0254, Pen
end
