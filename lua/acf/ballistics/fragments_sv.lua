local ACF        = ACF
local Ballistics = ACF.Ballistics
local Damage     = ACF.Damage
local Classes    = ACF.Classes

local MaxPenetrations = 10 -- Layers a fragment can punch through before it's given up on
local MinSpeed        = 50 -- m/s, below this a fragment is assumed spent
local MaxRange        = 8000 -- Trace length used to find a fragment's next obstacle, in world units

--- A straight-line, non-ricocheting projectile resolved in one closed-form pass instead of per-tick iteration.
--- Data: Pos, Flight (world units/s), ProjMass, ProjArea, Diameter, DragCoef, Owner, Gun, Entity, Filter.
function Ballistics.CreateFragment(Data)
	local Ammo = Classes.GetSubtypeByName("ACF.Ammunition.BaseAmmo", "ACF.Ammunition.AP")

	local Fragment = {
		AmmoType = "ACF.Ammunition.AP",
		Owner    = Data.Owner,
		Gun      = Data.Gun,
		Entity   = Data.Entity,
		Pos      = Data.Pos,
		ProjMass = Data.ProjMass,
		ProjArea = Data.ProjArea,
		Diameter = Data.Diameter,
		DragCoef = Data.DragCoef,
		Filter   = table.Copy(Data.Filter or {}),
		Color    = ColorRand(100, 255),
		IsSpall  = true,
		Mode     = "Flight", -- Flight looks ahead with a trace, Penetration walks a frozen ray through armor
	}

	function Fragment:GetPenetration(Speed)
		return Ammo:GetPenetration(self, Speed)
	end

	local Dir   = Data.Flight:GetNormalized()
	local Speed = Data.Flight:Length() / ACF.Scale * ACF.InchToMeter -- m/s

	for _ = 1, MaxPenetrations do
		if Speed < MinSpeed then return end

		Fragment.Flight  = Dir * (Speed * ACF.Scale * ACF.MeterToInch)
		Fragment.TraceTo = Fragment.Pos + Dir * MaxRange

		local Trace, ConvexHit = Ballistics.ResolveNextObstacle(Fragment)

		if not Trace.Hit then
			debugoverlay.Line(Fragment.Pos, Fragment.TraceTo, 15, Fragment.Color, true)

			return -- Spent itself in open air
		end

		debugoverlay.Line(Fragment.Pos, Trace.HitPos, 15, Fragment.Color, true)

		Fragment.ConvexHit = ConvexHit

		local Distance = Fragment.Pos:Distance(Trace.HitPos) * ACF.InchToMeter
		local HitSpeed = ACF.GetRangedSpeed(Speed, Fragment.DragCoef, Distance)

		if HitSpeed <= 0 then return end -- Ran out of energy before reaching the obstacle

		Fragment.Flight = Dir * HitSpeed

		if not ACF.Check(Trace.Entity) then return end -- World geometry absorbs fragments outright

		local DmgResult, DmgInfo = Damage.getBulletDamage(Fragment, Trace)
		local HitRes = Damage.dealDamage(Trace.Entity, DmgResult, DmgInfo)

		if HitRes.Loss >= 1 then return end -- Stopped by the plate; fragments never ricochet

		if ConvexHit then
			-- Only this convex is spent, so a stack rebuilt later in this fragment's life still sees the rest.
			if HitRes.Overkill and HitRes.Overkill > 0 then
				Ballistics.FilterConvex(Fragment, Trace.Entity, ConvexHit.ConvexID)
			end
		else
			Fragment.Filter[#Fragment.Filter + 1] = Trace.Entity
		end

		local RemainingPen = Fragment:GetPenetration() * (1 - HitRes.Loss)

		Speed        = Ammo:CalcSpeed(Fragment, RemainingPen)
		Fragment.Pos = (ConvexHit and ConvexHit.ExitPos) or Trace.HitPos
	end
end
