local ACF             = ACF
local Countermeasures = ACF.Classes.Countermeasures
local Bullets         = ACF.Ballistics.Bullets
local Missiles        = ACF.ActiveMissiles

local Flares = {}
local FlareUID = 0

local function OnFlareSpawn(BulletData)
	local FlareObj = BulletData.FlareObj
	local Affected = FlareObj:ApplyToAll()

	for Missile in pairs(Affected) do
		Missile.GuidanceData.Override = FlareObj
	end
end

function Countermeasures.RegisterFlare(BulletData)
	local Flare    = Countermeasures.Get("Flare")
	local FlareObj = Flare()

	BulletData.FlareUID = FlareUID

	Flares[BulletData.Index] = FlareUID
	FlareUID = FlareUID + 1

	FlareObj:Configure(BulletData)

	BulletData.FlareObj = FlareObj

	OnFlareSpawn(BulletData)
end

function Countermeasures.UnregisterFlare(BulletData)
	local FlareObj = BulletData.FlareObj

	if FlareObj then
		FlareObj.Flare = nil
	end

	Flares[BulletData.Index] = nil
end

function Countermeasures.GetFlaresInCone(Position, Direction, Degrees)
	local Result = {}

	for Index, UID in pairs(Flares) do
		local Flare = Bullets[Index]

		if not (Flare and Flare.FlareUID and Flare.FlareUID == UID) then
			continue
		end

		if Countermeasures.ConeContainsPos(Position, Direction, Degrees, Flare.Pos) then
			Result[Flare] = true
		end
	end

	return Result
end

function Countermeasures.GetAnyFlareInCone(Position, Direction, Degrees)
	for Index, UID in pairs(Flares) do
		local Flare = Bullets[Index]

		if not (Flare and Flare.FlareUID and Flare.FlareUID == UID) then
			continue
		end

		if Countermeasures.ConeContainsPos(Position, Direction, Degrees, Flare.Pos) then
			return Flare
		end
	end
end

function Countermeasures.GetMissilesInCone(Position, Direction, Degrees)
	local Result = {}

	for Missile in pairs(Missiles) do
		if not IsValid(Missile) then
			continue
		end

		if Countermeasures.ConeContainsPos(Position, Direction, Degrees, Missile:GetPos()) then
			Result[Missile] = true
		end

	end

	return Result
end

function Countermeasures.GetMissilesInSphere(Position, Radius)
	local Result = {}
	local RadiusSqr = Radius * Radius

	for Missile in pairs(Missiles) do
		if not IsValid(Missile) then
			continue
		end

		if Position:DistToSqr(Missile:GetPos()) <= RadiusSqr then
			Result[Missile] = true
		end
	end

	return Result
end

-- Tests flare distraction effect upon all undistracted missiles, but does not perform the effect itself.  Returns a list of potentially affected missiles.
-- argument is the bullet in the acf bullet table which represents the flare - not the cm_flare object!
function Countermeasures.GetAllMissilesWhichCanSee(Position)
	local Result = {}

	for Missile in pairs(Missiles) do
		local Guidance = Missile.GuidanceData

		if not Guidance or Guidance.Override or not Guidance.ViewCone then
			continue
		end

		if Countermeasures.ConeContainsPos(Missile:GetPos(), Missile:GetForward(), Guidance.ViewCone, Position) then
			Result[Missile] = true
		end
	end

	return Result
end

function Countermeasures.ConeContainsPos(ConePos, ConeDir, Degrees, Position)
	local MinimumDot = math.cos(math.rad(Degrees))
	local Direction = (Position - ConePos):GetNormalized()

	return ConeDir:Dot(Direction) >= MinimumDot
end

local function ApplyCountermeasure(Missile, Guidance, CounterMeasure)
	if not CounterMeasure.AppliesTo[Guidance.Name] then return end

	local Override = CounterMeasure.ApplyAll(Missile, Guidance)

	if Override then
		Guidance.Override = Override
		return true
	end
end

function Countermeasures.ApplyCountermeasures(Missile, Guidance)
	if Guidance.Override then return end

	local List = Countermeasures.GetList()

	for _, CounterMeasure in ipairs(List) do
		if not CounterMeasure.ApplyContinuous then
			continue
		end

		if ApplyCountermeasure(Missile, Guidance, CounterMeasure) then
			break
		end
	end
end

function Countermeasures.ApplySpawnCountermeasures(Missile, Guidance)
	if Guidance.Override then return end

	local List = Countermeasures.GetList()

	for _, CounterMeasure in ipairs(List) do
		if CounterMeasure.ApplyContinuous then
			continue
		end

		if ApplyCountermeasure(Missile, Guidance, CounterMeasure) then
			break
		end
	end
end