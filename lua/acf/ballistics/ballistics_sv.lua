local hook       = hook
local ACF        = ACF
local Ballistics = ACF.Ballistics
local Damage     = ACF.Damage
local Clock      = ACF.Utilities.Clock
local Effects    = ACF.Utilities.Effects
local Debug		 = ACF.Debug

Ballistics.Bullets         = Ballistics.Bullets or {}
Ballistics.UnusedIndexes   = Ballistics.UnusedIndexes or {}
Ballistics.HighestIndex    = Ballistics.HighestIndex or 0
Ballistics.SkyboxGraceZone = 100

local Bullets      = Ballistics.Bullets
local Unused       = Ballistics.UnusedIndexes
local IndexLimit   = 2000
local SkyGraceZone = 100
local FlightTr     = { start = true, endpos = true, filter = true, mask = true }
local GlobalFilter = ACF.GlobalFilter
local AmmoTypes    = ACF.Classes.AmmoTypes

-- This will create, or update, the tracer effect on the clientside
function Ballistics.BulletClient(Bullet, Type, Hit, HitPos)
	if Bullet.NoEffect then return end -- No clientside effect will be created for this bullet

	local IsUpdate = Type == "Update"
	local EffectTable = {
		DamageType = Bullet.Index,
		Start = Bullet.Flight * 0.1,
		Attachment = Bullet.Hide and 0 or 1,
		Origin = (IsUpdate and Hit > 0) and HitPos or Bullet.Pos,
		Scale = (not Bullet.Hide and IsUpdate) and Hit or 0,
		EntIndex = not IsUpdate and Bullet.Crate or nil,
	}

	Effects.CreateEffect("ACF_Bullet_Effect", EffectTable, true, true)
end

function Ballistics.RemoveBullet(Bullet)
	if Bullet.Removed then return end

	local Index = Bullet.Index

	Bullets[Index] = nil
	Unused[Index]  = true

	if Bullet.OnRemoved then
		Bullet:OnRemoved()
	end

	Bullet.Removed = true

	if not next(Bullets) then
		hook.Remove("ACF_OnTick", "ACF Iterate Bullets")
	end
end

-- MARCH: I made quite a few ballistics changes to try to fix tracebug in the vast majority of cases.
-- What happens is the following. 
--     - The x is a trace start, the o is a trace end. The bullet always moves itself from X to O every think frame.
--     - The [|||] is a contraption moving in the opposite direction to the trace. [ is the start, | is internals, ] is the end.
--     - ThinkAllSystems() refers to IGameSystem::FrameUpdatePostEntityThinkAllSystems() (Source SDK method that runs physics simulation on the active physenv)
--[[
	[tick 1] ThinkAllSystems()   x                  [|||]
	[tick 1] GM:Think            x-------------o [|||]
	RESULT: Trace stopped at o. Did not hit anything.

	[tick 2] ThinkAllSystems()                 x [|||]
	[tick 2] GM:Think                         [x||]
											ZOOMED IN
									[||x----o!|||||||||||||||]
										(pretend o just hit something really important and everything else was dead air)
]]
-- The solution I've come up with is to perform a 2nd trace after our initial bullet flight trace. We mutate the bullet
-- to pretend like its going forward with the next iteration, and run DoBulletsFlight again with only evaluation on (ie. no changes
-- happen to the bullet). We then restore the bullet back. But we keep track of what happened in this 2nd trace... we keep the entity hit,
-- and the local position to the entity.
-- If we previously hit an entirely different entity than the one we hit now, then we'll use the previous 2nd trace info.
-- Otherwise, we'll use the current trace.

function Ballistics.CalculateBulletParameters(Bullet, ClockTime)
	local DeltaTime  = ClockTime - Bullet.LastThink
	local Flight     = Bullet.Flight
	local Drag       = Flight:GetNormalized() * (Bullet.DragCoef * Flight:LengthSqr()) / ACF.DragDiv
	local Accel      = Bullet.Accel or ACF.Gravity
	local Correction = 0.5 * (Accel - Drag) * DeltaTime

	return DeltaTime, Flight, Drag, Accel, Correction
end

local TICK_INTERVAL = engine.TickInterval()

function Ballistics.CalcBulletFlight(Bullet)
	local ClockTime = Clock.CurTime

	if Bullet.KillTime and ClockTime > Bullet.KillTime then
		return Ballistics.RemoveBullet(Bullet)
	end

	if Bullet.PreCalcFlight then
		Bullet:PreCalcFlight()
	end

	local DeltaTime, Flight, Drag, Accel, Correction = Ballistics.CalculateBulletParameters(Bullet, ClockTime)

	Bullet.NextPos   = Bullet.Pos + ACF.Scale * DeltaTime * (Flight + Correction)
	Bullet.Flight    = Flight + (Accel - Drag) * DeltaTime
	Bullet.LastThink = ClockTime
	Bullet.DeltaTime = DeltaTime

	local TraceInfo = Ballistics.DoBulletsFlight(Bullet)

	if Bullet.PostCalcFlight then
		Bullet:PostCalcFlight()
	end

	Bullet.Iterations = Bullet.Iterations + 1
	Bullet.Pos = Bullet.NextPos

	if Bullet.NextPredictedHit then
		local NowEnt, ThenEnt = TraceInfo.NextPredictedHitEntity, Bullet.NextPredictedHitEntity
		local NowValid, ThenValid = IsValid(NowEnt), IsValid(ThenEnt)

		if not TraceInfo.Hit or NowValid ~= ThenValid or NowEnt ~= ThenEnt then
			-- Something changed in what we hit. Try the old trace.
			TraceInfo.Hit = true
			TraceInfo.Entity = ThenEnt
			if ThenValid then
				TraceInfo.HitPos = ThenEnt:LocalToWorld(Bullet.NextPredictedHitPosLocal)
			else
				TraceInfo.HitPos = Bullet.NextPredictedHitPos
			end
			Ballistics.TestHit(Bullet, TraceInfo)
		end
	end

	local _, NextFlight, NextDrag, NextAccel, NextCorrection = Ballistics.CalculateBulletParameters(Bullet, ClockTime)
	local PrevNextPos, PrevFlight, PrevLastThink, PrevDeltaTime = Bullet.NextPos, Bullet.Flight, Bullet.LastThink, Bullet.DeltaTime

	Bullet.NextPos   = Bullet.Pos + ACF.Scale * TICK_INTERVAL * (NextFlight + NextCorrection)
	Bullet.Flight    = NextFlight + (NextAccel - NextDrag) * TICK_INTERVAL
	Bullet.LastThink = ClockTime + TICK_INTERVAL
	Bullet.DeltaTime = TICK_INTERVAL

	local NextTraceInfo = Ballistics.DoBulletsFlight(Bullet, true)

	Bullet.NextPos = PrevNextPos
	Bullet.Flight = PrevFlight
	Bullet.LastThink = PrevLastThink
	Bullet.DeltaTime = PrevDeltaTime

	if NextTraceInfo.Hit then
		Bullet.NextPredictedHit = true
		Bullet.NextPredictedHitEntity = NextTraceInfo.Entity
		if IsValid(NextTraceInfo.Entity) then
			Bullet.NextPredictedHitPosLocal = NextTraceInfo.Entity:WorldToLocal(NextTraceInfo.HitPos)
		else
			Bullet.NextPredictedHitPos = NextTraceInfo.HitPos
		end
	else
		Bullet.NextPredictedHit = false
		Bullet.NextPredictedHitEntity = nil
		Bullet.NextPredictedHitPosLocal = nil
	end
end

function Ballistics.GetBulletIndex()
	if next(Unused) then
		local Index = next(Unused)

		Unused[Index] = nil

		return Index
	end

	local Index = Ballistics.HighestIndex + 1

	if Index > IndexLimit then return end

	Ballistics.HighestIndex = Index

	return Index
end

function Ballistics.IterateBullets()
	for _, Bullet in pairs(Bullets) do
		if not Bullet.HandlesOwnIteration then
			Ballistics.CalcBulletFlight(Bullet)
		end
	end
end

local RequiredBulletDataProperties = {"Pos", "Flight"}
function Ballistics.CreateBullet(BulletData)
	local Index = Ballistics.GetBulletIndex()
	if not Index then return end -- Too many bullets in the air

	-- Validate BulletData, so we can catch these problems easier

	for _, RequiredProp in ipairs(RequiredBulletDataProperties) do
		if not BulletData[RequiredProp] then
			error(("Ballistics.CreateBullet: Expected '%s' to be present in BulletData, got nil!"):format(RequiredProp))
		end
	end

	local Bullet = table.Copy(BulletData)

	if not Bullet.Filter then
		Bullet.Filter = IsValid(Bullet.Gun) and { Bullet.Gun } or {}
	end

	Bullet.Index       = Index
	Bullet.LastThink   = Clock.CurTime
	Bullet.Iterations  = 0
	Bullet.Fuze        = Bullet.Fuze and Bullet.Fuze + Clock.CurTime or nil -- Convert Fuze from fuze length to time of detonation
	if Bullet.Caliber then
		Bullet.Mask		= (Bullet.Caliber < 3 and bit.band(MASK_SOLID, MASK_SHOT) or MASK_SOLID) -- I hope CONTENTS_AUX isn't used for anything important? I can't find any references outside of the wiki to it so hopefully I can use this
	else
		Bullet.Mask		= MASK_SOLID
	end

	Bullet.Ricochets   = Bullet.Ricochets or 0
	Bullet.GroundRicos = Bullet.GroundRicos or 0
	Bullet.Color       = ColorRand(100, 255)

	-- Purely to allow someone to shoot out of a seat without hitting themselves and dying
	if IsValid(Bullet.Owner) and Bullet.Owner:IsPlayer() and Bullet.Owner:InVehicle() and (Bullet.Gun and Bullet.Gun:GetClass() ~= "acf_gun") then
		Bullet.Filter[#Bullet.Filter + 1] = Bullet.Owner:GetVehicle()
	end

	-- TODO: Make bullets use a metatable instead
	function Bullet:GetPenetration()
		local Ammo = AmmoTypes.Get(Bullet.Type)

		return Ammo:GetPenetration(self)
	end

	if not next(Bullets) then
		hook.Add("ACF_OnTick", "ACF Iterate Bullets", Ballistics.IterateBullets)
	end

	Bullets[Index] = Bullet

	Ballistics.BulletClient(Bullet, "Init", 0)
	Ballistics.CalcBulletFlight(Bullet)

	return Bullet
end

function Ballistics.GetImpactType(Trace, Entity)
	if Trace.HitWorld then return "World" end
	if Entity:IsPlayer() or Entity:IsNPC() then return "Prop" end

	return IsValid(Entity:CPPIGetOwner()) and "Prop" or "World"
end

function Ballistics.OnImpact(Bullet, Trace, Ammo, Type)
	local Func  = Type == "World" and Ammo.WorldImpact or Ammo.PropImpact
	local Retry = Func(Ammo, Bullet, Trace)

	if Retry == "Penetrated" then
		if Bullet.OnPenetrated then
			Bullet.OnPenetrated(Bullet, Trace)
		end

		Ballistics.BulletClient(Bullet, "Update", 2, Trace.HitPos)
		Ballistics.DoBulletsFlight(Bullet)
	elseif Retry == "Ricochet" then
		if Bullet.OnRicocheted then
			Bullet.OnRicocheted(Bullet, Trace)
		end

		Ballistics.BulletClient(Bullet, "Update", 3, Trace.HitPos)
		Ballistics.DoBulletsFlight(Bullet)
	else
		if Bullet.OnEndFlight then
			Bullet.OnEndFlight(Bullet, Trace)
		end

		Ballistics.BulletClient(Bullet, "Update", 1, Trace.HitPos)

		Ammo:OnFlightEnd(Bullet, Trace)
	end
end

function Ballistics.TestFilter(Entity, Bullet)
	if not IsValid(Entity) then return true end

	if GlobalFilter[Entity:GetClass()] then return false end

	if not hook.Run("ACF_OnFilterBullet", Entity, Bullet) then return false end

	local EntTbl = Entity:GetTable()

	if EntTbl._IsSpherical then return false end -- TODO: Remove when damage changes make props unable to be destroyed, as physical props can have friction reduced (good for wheels)
	if EntTbl.ACF_InvisibleToBallistics then return false end
	if EntTbl.ACF_KillableButIndestructible then
		local EntACF = EntTbl.ACF
	    if EntACF and EntACF.Health <= 0 then return false end
	end
	if EntTbl.ACF_TestFilter then return EntTbl.ACF_TestFilter(Entity, Bullet) end

	return true
end

function Ballistics.DoBulletsFlight(Bullet, OnlyEvaluate)
	local CanFly = hook.Run("ACF_PreBulletFlight", Bullet)

	if not CanFly then return end

	if Bullet.SkyLvL then
		if Clock.CurTime - Bullet.LifeTime > 30 then
			return Ballistics.RemoveBullet(Bullet)
		end

		if Bullet.NextPos.z + SkyGraceZone > Bullet.SkyLvL then
			if Bullet.Fuze and Bullet.Fuze <= Clock.CurTime then -- Fuze detonated outside map
				Ballistics.RemoveBullet(Bullet)
			end

			return
		elseif not util.IsInWorld(Bullet.NextPos) then
			return Ballistics.RemoveBullet(Bullet)
		else
			Bullet.SkyLvL = nil
			Bullet.LifeTime = nil

			return
		end
	end

	FlightTr.mask 	= Bullet.Mask
	FlightTr.filter = Bullet.Filter
	FlightTr.start 	= Bullet.Pos
	FlightTr.endpos = Bullet.NextPos

	local traceRes = ACF.trace(FlightTr) -- Does not modify the bullet's original filter

	if OnlyEvaluate then
		return traceRes
	end

	Debug.Cross(Bullet.Pos, 4, 30, Bullet.Color, true)
	-- Debug.Line(Bullet.Pos, traceRes.HitPos, 30, Bullet.Color)

	if Bullet.Fuze and Bullet.Fuze <= Clock.CurTime then
		if not util.IsInWorld(Bullet.Pos) then -- Outside world, just delete
			Ballistics.RemoveBullet(Bullet)
			return traceRes
		else
			local DeltaTime = Bullet.DeltaTime
			local DeltaFuze = Clock.CurTime - Bullet.Fuze
			local Lerp = DeltaFuze / DeltaTime

			if (not traceRes.Hit or Lerp < traceRes.Fraction) then -- Fuze went off before running into something
				Bullet.Pos       = LerpVector(Lerp, Bullet.Pos, Bullet.NextPos)
				Bullet.DetByFuze = true

				if Bullet.OnEndFlight then
					Bullet.OnEndFlight(Bullet, traceRes)
				end

				Ballistics.BulletClient(Bullet, "Update", 1, Bullet.Pos)

				AmmoTypes.Get(Bullet.Type):OnFlightEnd(Bullet, traceRes)

				return traceRes
			end
		end
	end

	Ballistics.TestHit(Bullet, traceRes)
	return traceRes
end

function Ballistics.TestHit(Bullet, traceRes)
	if traceRes.Hit then
		if traceRes.HitSky then
			if traceRes.HitNormal == -vector_up then
				Bullet.SkyLvL = traceRes.HitPos.z
				Bullet.LifeTime = Clock.CurTime
			else
				Ballistics.RemoveBullet(Bullet)
			end
		else
			local Entity = traceRes.Entity

			if not Ballistics.TestFilter(Entity, Bullet) then
				table.insert(Bullet.Filter, Entity)
				timer.Simple(0, function()
					Ballistics.DoBulletsFlight(Bullet) -- Retries the same trace after adding the entity to the filter; important in case something is embedded in something that shouldn't be hit
				end)

				return
			end

			local Type = Ballistics.GetImpactType(traceRes, Entity)

			Ballistics.OnImpact(Bullet, traceRes, AmmoTypes.Get(Bullet.Type), Type)
		end
	end
end

do -- Terminal ballistics --------------------------
	function Ballistics.GetRicochetVector(Flight, HitNormal)
		local Normal = Flight:GetNormalized()

		return Normal - (2 * Normal:Dot(HitNormal)) * HitNormal
	end

	function Ballistics.CalculateRicochet(Bullet, Trace)
		local HitAngle = ACF.GetHitAngle(Trace, Bullet.Flight)
		-- Ricochet distribution center
		local sigmoidCenter = Bullet.DetonatorAngle or (Bullet.Ricochet - math.abs(Bullet.Speed / ACF.MeterToInch - Bullet.LimitVel) / 100)

		-- Ricochet probability (sigmoid distribution); up to 5% minimal ricochet probability for projectiles with caliber < 20 mm
		local ricoProb = math.Clamp(1 / (1 + math.exp((HitAngle - sigmoidCenter) / -4)), math.max(-0.05 * (Bullet.Caliber - 2) / 2, 0), 1)

		-- Checking for ricochet
		local Ricochet = 0
		local Loss     = 0
		if ricoProb > math.random() and HitAngle < 90 then
			Ricochet = math.Clamp(HitAngle / 90, 0.05, 1) -- atleast 5% of energy is kept
			Loss     = 0.25 - Ricochet
		end
		return Ricochet, Loss
	end

	function Ballistics.DoRoundImpact(Bullet, Trace)
		local DmgResult, DmgInfo = Damage.getBulletDamage(Bullet, Trace)
		local Speed    = Bullet.Speed
		local Energy   = Bullet.Energy
		local Entity   = Trace.Entity
		local HitRes   = Damage.dealDamage(Entity, DmgResult, DmgInfo)
		local Ricochet = 0

		Debug.Cross(Trace.HitPos, 6, 30, Bullet.Color, true)

		if HitRes.Loss == 1 then
			-- If the there's more armor than penetration, the bullet ricochets
			Ricochet, HitRes.Loss = Ballistics.CalculateRicochet(Bullet, Trace)
		else
			-- If there's less armor than penetration, spalling happens
			if not Bullet.IsSpall and not Bullet.IsCookOff then
				Ballistics.DoSpall(Bullet, Trace, HitRes, Bullet.Flight:Length())
			end
		end

		-- Transfer bullet momentum into target
		if ACF.KEPush then
			ACF.KEShove(
				Entity,
				Trace.HitPos,
				Bullet.Flight:GetNormalized(),
				Energy.Kinetic * HitRes.Loss * 1000 * Bullet.ShovePower
			)
		end

		-- If the entity should be killed, kill it
		if HitRes.Kill and IsValid(Entity) then
			ACF.APKill(Entity, Bullet.Flight:GetNormalized(), Energy.Kinetic, DmgInfo)
		end

		HitRes.Ricochet = false

		-- Apply the ricochet for the next bullet iteration if needed
		if Ricochet > 0 and Bullet.Ricochets < 3 then
			local Direction = Ballistics.GetRicochetVector(Bullet.Flight, Trace.HitNormal) + VectorRand() * 0.025
			local Flight    = Direction:GetNormalized() * Speed * Ricochet * ACF.Scale
			local Position  = Trace.HitPos

			Bullet.Ricochets = Bullet.Ricochets + 1
			Bullet.Flight    = Flight
			Bullet.Pos       = Position
			Bullet.NextPos   = Position + Flight * Bullet.DeltaTime

			HitRes.Ricochet = true
		end

		return HitRes
	end

	function Ballistics.DoRicochet(Bullet, Trace)
		local HitAngle = ACF.GetHitAngle(Trace, Bullet.Flight)
		local Speed    = Bullet.Flight:Length() / ACF.Scale
		local MinAngle = math.min(Bullet.Ricochet - Speed / ACF.MeterToInch / 30 + 20, 89.9) -- Making the chance of a ricochet get higher as the speeds increase
		local Ricochet = 0

		if HitAngle < 89.9 and HitAngle > math.random(MinAngle, 90) then -- Checking for ricochet
			Ricochet = HitAngle / 90 * 0.75
		end

		if Ricochet > 0 and Bullet.GroundRicos < 2 then
			local Direction = Ballistics.GetRicochetVector(Bullet.Flight, Trace.HitNormal) + VectorRand() * 0.05
			local DeltaTime = engine.TickInterval()

			Bullet.GroundRicos = Bullet.GroundRicos + 1
			Bullet.Flight      = Direction:GetNormalized() * Speed * ACF.Scale * Ricochet
			Bullet.Pos         = Trace.HitPos
			Bullet.NextPos     = Bullet.Pos + Bullet.Flight * DeltaTime

			return "Ricochet"
		end

		return false
	end

	function Ballistics.DoSpall(Bullet, Trace, HitRes, Speed)
		-- Only ever called during overpenetration
		local Energy = Bullet.Energy.Kinetic -- Energy the projectile carries (J)

		local RemovedMass = HitRes.Damage * ACF.RHADensity -- Damage is used as a proxy for volume (cm^3) and RHA density is in kg/cm^3
		local RemovedArea = Bullet.ProjArea -- Area of the spall (cm^2)

		local FragFormEnergy = 100 -- Energy needed to form a fragment (J) (Might depend on the material?)
		local FragTotalEnergy = Energy * 0.33 -- 25% of energy is used to form fragments (J) (Might depend on the material?)
		local FragCount = math.floor(FragTotalEnergy / FragFormEnergy) -- Number of fragments formed
		FragCount = math.Clamp(FragCount, 1, 30) -- Atleast 1, up to 30 fragments (let's not kill the server)

		if FragCount < 1 then return end -- No fragments formed

		-- Test values
		local FragSize = RemovedArea / FragCount 	-- Area of the fragments (cm^2)
		local FragMass = RemovedMass / FragCount 	-- Mass of the fragments (kg)
		local FragSpeed = Speed * 0.25 				-- Speed of the fragments (u/s) (50% of the original speed)

		local BaseCone = 10 * math.pow(FragSize, 1 / 3) -- Half angle of the spall cone (degrees) (Might depend on the material?)
		local FragPos = Trace.HitPos
		local FragDirInit = Bullet.Flight:GetNormalized()

		-- Filter what the bullet has travelled through + the hit entity itself if applicable
		local Filter = table.Copy(Bullet.Filter)
		if Trace.Entity:IsValid() then Filter[#Filter + 1] = Trace.Entity end

		-- Define a plane for the spread
		local Right = FragDirInit:Cross(Vector(0, 0, 1)):GetNormalized()
		local Up = FragDirInit:Cross(Right):GetNormalized()
		local ConeTan = math.tan(math.rad(BaseCone)) -- "Width" of cone on the plane

		-- Copied from AP ammotype definition
		local ProjArea = math.pi * (FragSize / 2) ^ 2
		local DragCoef = ProjArea * 0.0001 / FragMass

		-- Create the fragments
		for _ = 1, FragCount do
			-- Uniform sampling of points on a circle defined by the cone on the plane
			local SpreadRadius = ConeTan * math.sqrt(math.random())
			local SpreadAngle = math.random() * 2 * math.pi
			local SpreadDir = Up * SpreadRadius * math.cos(SpreadAngle) + Right * SpreadRadius * math.sin(SpreadAngle)
			local FragDir = (FragDirInit + SpreadDir):GetNormalized()

			Ballistics.CreateBullet({
				Caliber    = FragSize,
				Diameter   = FragSize,
				-- Id         = Bullet.Id,
				Type       = "AP",
				Owner      = Bullet.Owner,
				Entity     = Bullet.Entity,
				-- Crate      = Bullet.Crate,
				Gun        = Bullet.Gun,
				Pos        = FragPos,
				ProjArea   = ProjArea,
				ProjMass   = FragMass,
				DragCoef = DragCoef,
				-- Tracer     = Bullet.Tracer,
				LimitVel   = 800,
				Ricochet   = 60,
				ShovePower = 0.2,
				Flight = FragDir * FragSpeed,
				Filter = Filter,
				Hide = true,
				IsSpall = true,
			})
		end
	end
end
