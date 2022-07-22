local ACF        = ACF
local Ballistics = ACF.Ballistics
local Clock      = ACF.Utilities.Clock

Ballistics.Bullets         = Ballistics.Bullets or {}
Ballistics.UnusedIndexes   = Ballistics.UnusedIndexes or {}
Ballistics.HighestIndex    = Ballistics.HighestIndex or 0
Ballistics.SkyboxGraceZone = 100

local Bullets      = Ballistics.Bullets
local Unused       = Ballistics.UnusedIndexes
local IndexLimit   = 2000
local SkyGraceZone = 100
local FlightRes    = {}
local FlightTr     = { start = true, endpos = true, filter = true, mask = true, output = FlightRes }
local GlobalFilter = ACF.GlobalFilter
local AmmoTypes    = ACF.Classes.AmmoTypes
local HookRun      = hook.Run


-- This will create, or update, the tracer effect on the clientside
function Ballistics.BulletClient(Bullet, Type, Hit, HitPos)
	if Bullet.NoEffect then return end -- No clientside effect will be created for this bullet

	local Effect = EffectData()
	Effect:SetDamageType(Bullet.Index)
	Effect:SetStart(Bullet.Flight * 0.1)
	Effect:SetAttachment(Bullet.Hide and 0 or 1)

	if Type == "Update" then
		if Hit > 0 then
			Effect:SetOrigin(HitPos)
		else
			Effect:SetOrigin(Bullet.Pos)
		end

		Effect:SetScale(Hit)
	else
		Effect:SetOrigin(Bullet.Pos)
		Effect:SetEntIndex(Bullet.Crate)
		Effect:SetScale(0)
	end

	util.Effect("ACF_Bullet_Effect", Effect, true, true)
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

	Ballistics.BulletClient(Bullet, "Update", 1, Bullet.Pos) -- Kills the bullet on the clientside

	if not next(Bullets) then
		hook.Remove("ACF_OnClock", "ACF Iterate Bullets")
	end
end

function Ballistics.CalcBulletFlight(Bullet)
	if Bullet.KillTime and Clock.CurTime > Bullet.KillTime then
		return Ballistics.RemoveBullet(Bullet)
	end

	if Bullet.PreCalcFlight then
		Bullet:PreCalcFlight()
	end

	local DeltaTime  = Clock.CurTime - Bullet.LastThink
	local Drag       = Bullet.Flight:GetNormalized() * (Bullet.DragCoef * Bullet.Flight:LengthSqr()) / ACF.DragDiv
	local Accel      = Bullet.Accel or ACF.Gravity
	local Correction = 0.5 * (Accel - Drag) * DeltaTime

	Bullet.NextPos   = Bullet.Pos + ACF.Scale * DeltaTime * (Bullet.Flight + Correction)
	Bullet.Flight    = Bullet.Flight + (Accel - Drag) * DeltaTime
	Bullet.LastThink = Clock.CurTime
	Bullet.DeltaTime = DeltaTime

	Ballistics.DoBulletsFlight(Bullet)

	if Bullet.PostCalcFlight then
		Bullet:PostCalcFlight()
	end

	Bullet.LastPos = Bullet.Pos
	Bullet.Pos = Bullet.NextPos
end

local function GetBulletIndex()
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

local function IterateBullets()
	for _, Bullet in pairs(Bullets) do
		if not Bullet.HandlesOwnIteration then
			Ballistics.CalcBulletFlight(Bullet)
		end
	end
end

function Ballistics.CreateBullet(BulletData)
	local Index = GetBulletIndex()

	if not Index then return end -- Too many bullets in the air

	local Bullet = table.Copy(BulletData)

	if not Bullet.Filter then
		Bullet.Filter = IsValid(Bullet.Gun) and { Bullet.Gun } or {}
	end

	Bullet.Index       = Index
	Bullet.LastThink   = Clock.CurTime
	Bullet.Fuze        = Bullet.Fuze and Bullet.Fuze + Clock.CurTime or nil -- Convert Fuze from fuze length to time of detonation
	Bullet.Mask        = MASK_SOLID -- Note: MASK_SHOT removed for smaller projectiles as it ignores armor
	Bullet.Ricochets   = 0
	Bullet.GroundRicos = 0
	Bullet.Color       = ColorRand(100, 255)

	-- TODO: Make bullets use a metatable instead
	function Bullet:GetPenetration()
		local Ammo = AmmoTypes.Get(Bullet.Type)

		return Ammo:GetPenetration(self)
	end

	if not next(Bullets) then
		hook.Add("ACF_OnClock", "ACF Iterate Bullets", IterateBullets)
	end

	Bullets[Index] = Bullet

	Ballistics.BulletClient(Bullet, "Init", 0)
	Ballistics.CalcBulletFlight(Bullet)

	return Bullet
end

local function GetImpactType(Trace, Entity)
	if Trace.HitWorld then return "World" end
	if Entity:IsPlayer() then return "Prop" end

	return IsValid(Entity:CPPIGetOwner()) and "Prop" or "World"
end

local function OnImpact(Bullet, Trace, Ammo, Type)
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

function Ballistics.DoBulletsFlight(Bullet)
	if HookRun("ACF Bullet Flight", Bullet) == false then return end

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

	ACF.TraceF(FlightTr) -- Does not modify the bullet's original filter

	debugoverlay.Line(Bullet.Pos, FlightRes.HitPos, 15, Bullet.Color)

	if Bullet.Fuze and Bullet.Fuze <= Clock.CurTime then
		if not util.IsInWorld(Bullet.Pos) then -- Outside world, just delete
			return Ballistics.RemoveBullet(Bullet)
		else
			local DeltaTime = Bullet.DeltaTime
			local DeltaFuze = Clock.CurTime - Bullet.Fuze
			local Lerp = DeltaFuze / DeltaTime

			if not FlightRes.Hit or Lerp < FlightRes.Fraction then -- Fuze went off before running into something
				Bullet.Pos       = LerpVector(Lerp, Bullet.Pos, Bullet.NextPos)
				Bullet.DetByFuze = true

				if Bullet.OnEndFlight then
					Bullet.OnEndFlight(Bullet, FlightRes)
				end

				Ballistics.BulletClient(Bullet, "Update", 1, Bullet.Pos)

				AmmoTypes.Get(Bullet.Type):OnFlightEnd(Bullet, FlightRes)

				return
			end
		end
	end

	if FlightRes.Hit then
		if FlightRes.HitSky then
			if FlightRes.HitNormal == Vector(0, 0, -1) then
				Bullet.SkyLvL = FlightRes.HitPos.z
				Bullet.LifeTime = Clock.CurTime
			else
				Ballistics.RemoveBullet(Bullet)
			end
		else
			local Entity = FlightRes.Entity

			if GlobalFilter[Entity:GetClass()] then return end

			local Type = GetImpactType(FlightRes, Entity)

			OnImpact(Bullet, FlightRes, AmmoTypes.Get(Bullet.Type), Type)
		end
	end
end

do -- Terminal ballistics --------------------------
	function Ballistics.GetRicochetVector(Flight, HitNormal)
		local Normal = Flight:GetNormalized()

		return Normal - (2 * Normal:Dot(HitNormal)) * HitNormal
	end

	-- TODO: Move to damage_sv.lua and use the proper namespace
	function ACF_VolumeDamage(Bullet, Trace, Volume)
		local HitRes = ACF.Damage(Bullet, Trace, Volume)

		if HitRes.Kill then
			local Debris = ACF_APKill(Trace.Entity, Bullet.Flight:GetNormalized(), 0)
			table.insert(Bullet.Filter , Debris)
		end
	end

	function Ballistics.CalculateRicochet(Bullet, Trace)
		local HitAngle = ACF.GetHitAngle(Trace.HitNormal, Bullet.Flight)
		-- Ricochet distribution center
		local sigmoidCenter = Bullet.DetonatorAngle or (Bullet.Ricochet - math.abs(Bullet.Speed / 39.37 - Bullet.LimitVel) / 100)

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
		local Speed    = Bullet.Speed
		local Energy   = Bullet.Energy
		local HitRes   = ACF.Damage(Bullet, Trace)
		local Ricochet = 0

		if HitRes.Loss == 1 then
			Ricochet, HitRes.Loss = Ballistics.CalculateRicochet(Bullet, Trace)
		end

		if ACF.KEPush then
			ACF.KEShove(
				Trace.Entity,
				Trace.HitPos,
				Bullet.Flight:GetNormalized(),
				Energy.Kinetic * HitRes.Loss * 1000 * Bullet.ShovePower
			)
		end

		if HitRes.Kill then
			local Debris = ACF_APKill(Trace.Entity, Bullet.Flight:GetNormalized() , Energy.Kinetic)

			table.insert(Bullet.Filter , Debris)
		end

		HitRes.Ricochet = false

		if Ricochet > 0 and Bullet.Ricochets < 3 then
			local Direction = Ballistics.GetRicochetVector(Bullet.Flight, Trace.HitNormal) + VectorRand() * 0.025

			Bullet.Ricochets = Bullet.Ricochets + 1
			Bullet.NextPos = Trace.HitPos
			Bullet.Flight = Direction:GetNormalized() * Speed * Ricochet

			HitRes.Ricochet = true
		end

		return HitRes
	end

	function Ballistics.DoRicochet(Bullet, Trace)
		local HitAngle = ACF.GetHitAngle(Trace.HitNormal, Bullet.Flight)
		local Speed    = Bullet.Flight:Length() / ACF.Scale
		local MinAngle = math.min(Bullet.Ricochet - Speed / 39.37 / 30 + 20,89.9) -- Making the chance of a ricochet get higher as the speeds increase
		local Ricochet = 0

		if HitAngle < 89.9 and HitAngle > math.random(MinAngle, 90) then -- Checking for ricochet
			Ricochet = HitAngle / 90 * 0.75
		end

		if Ricochet > 0 and Bullet.GroundRicos < 2 then
			local Direction = Ballistics.GetRicochetVector(Bullet.Flight, Trace.HitNormal) + VectorRand() * 0.05
			local DeltaTime = engine.TickInterval()

			Bullet.GroundRicos = Bullet.GroundRicos + 1
			Bullet.Flight      = Direction:GetNormalized() * Speed * ACF.Scale * Ricochet
			Bullet.LastPos     = nil
			Bullet.Pos         = Trace.HitPos
			Bullet.NextPos     = Bullet.Pos + Bullet.Flight * DeltaTime

			return "Ricochet"
		end

		return false
	end
end
