local ACF        = ACF
local Classes    = ACF.Classes
local AmmoTypes  = Classes.AmmoTypes
local Ballistics = ACF.Ballistics

local function ResetDefault(BulletData)
	if not BulletData.MuzzleVel then return end

	BulletData.Flight:Normalize()
	BulletData.Flight = BulletData.Flight * (BulletData.MuzzleVel * ACF.MeterToInch)
end

local function ResetHEAT(BulletData)
	if not BulletData.Detonated then return ResetDefault(BulletData) end
	if not BulletData.MuzzleVel then return end

	local PenMul = BulletData.PenMul or ACF.GetGunValue(BulletData, "PenMul") or 1

	if not BulletData.SlugMV then -- heat needs to calculate slug mv on the fly
		local Ammo = AmmoTypes.Get("HEAT")

		BulletData.SlugMV = Ammo:CalcSlugMV(BulletData, BulletData.FillerMass)
	end

	BulletData.Flight:Normalize()
	BulletData.Flight = BulletData.Flight * (BulletData.SlugMV * PenMul) * ACF.MeterToInch
	BulletData.NotFirstPen = false
end

-- Resets the velocity of the bullet based on its current state on the serverside only.
-- This will de-sync the clientside effect!
function ACF.ResetBulletVelocity(BulletData)
	if BulletData.Type == "HEAT" then
		return ResetHEAT(BulletData)
	end

	ResetDefault(BulletData)
end

function ACF.DoReplicatedPropHit(Entity, Bullet)
	local EntRes = not table.HasValue(Bullet.Filter, Entity) and Entity or nil -- Don't pass the entity if it's supposed to be filtered out
	local FlightRes = { Entity = EntRes, HitNormal = Bullet.Flight, HitPos = Bullet.Pos, HitGroup = 0 }
	local Ammo  = AmmoTypes.Get(Bullet.Type)
	local Retry = Ammo:PropImpact(Bullet, FlightRes)

	if Retry == "Penetrated" then
		if Bullet.OnPenetrated then Bullet:OnPenetrated(FlightRes) end

		Ballistics.BulletClient(Bullet, "Update", 2, FlightRes.HitPos)
		Ballistics.CalcBulletFlight(Bullet)
	elseif Retry == "Ricochet" then
		if Bullet.OnRicocheted then Bullet:OnRicocheted(FlightRes) end

		Ballistics.BulletClient(Bullet, "Update", 3, FlightRes.HitPos)
		Ballistics.CalcBulletFlight(Bullet)
	else
		if Bullet.OnEndFlight then Bullet:OnEndFlight(FlightRes) end

		Ballistics.BulletClient(Bullet, "Update", 1, FlightRes.HitPos)

		Ammo:OnFlightEnd(Bullet, FlightRes)
	end
end
