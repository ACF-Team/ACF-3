local ACF = ACF

ACF.Bullets          = ACF.Bullets or {}
ACF.UnusedIndexes    = ACF.UnusedIndexes or {}
ACF.HighestIndex     = ACF.HighestIndex or 0
ACF.IndexLimit       = 2000
ACF.SkyboxGraceZone  = 100

local Bullets       = ACF.Bullets
local Unused        = ACF.UnusedIndexes
local FlightTr  	= { start = true, endpos = true, filter = true, mask = true }
local BackRes 		= {}
local BackTrace 	= { start = true, endpos = true, filter = true, mask = true, output = BackRes }
local GlobalFilter 	= ACF.GlobalFilter
local AmmoTypes     = ACF.Classes.AmmoTypes
local Gravity       = Vector(0, 0, -GetConVar("sv_gravity"):GetInt())
local WORLD			= game.GetWorld()
local HookRun		= hook.Run

cvars.AddChangeCallback("sv_gravity", function(_, _, Value)
	Gravity.z = -Value
end, "ACF Bullet Gravity")

-- This will check a vector against all of the hitboxes stored on an entity
-- If the vector is inside a box, it will return true, the box name (organization I guess, can do an E2 function with all of this), and the hitbox itself
-- If the entity in question does not have hitboxes, it returns false
-- Finally, if it never hits a hitbox in its check, it also returns false
function ACF_CheckInsideHitbox(Ent, Vec)
	if not Ent.HitBoxes then return false end -- If theres no hitboxes, then don't worry about them

	for k,v in pairs(Ent.HitBoxes) do
		-- v is the box table

		-- Need to make sure the vector is local and LEVEL with the box, otherwise WithinAABox will be wildly wrong
		local LocalPos = WorldToLocal(Vec,Angle(0,0,0),Ent:LocalToWorld(v.Pos),Ent:LocalToWorldAngles(v.Angle))
		local CheckHitbox = LocalPos:WithinAABox(-v.Scale / 2,v.Scale / 2)

		if CheckHitbox == true then return Check,k,v end
	end

	return false
end

-- This performs ray-OBB intersection with all of the hitboxes on an entity
-- Ray is the TOTAL ray to check with, so vec(500,0,0) to check all 500u forward
-- It will return false if there are no hitboxes or it didn't hit anything
-- If it hits any hitboxes, it will put them all together and return (true,HitBoxes)
function ACF_CheckHitbox(Ent,RayStart,Ray)
	if not Ent.HitBoxes then return false end -- Once again, cancel if there are no hitboxes

	local AllHit = {}

	for k,v in pairs(Ent.HitBoxes) do

		local _,_,Frac = util.IntersectRayWithOBB(RayStart, Ray, Ent:LocalToWorld(v.Pos), Ent:LocalToWorldAngles(v.Angle), -v.Scale / 2, v.Scale / 2)

		if Frac ~= nil then
			AllHit[k] = v
		end
	end

	return next(AllHit) and true or false, AllHit
end

-- This will create, or update, the tracer effect on the clientside
function ACF.BulletClient(Bullet, Type, Hit, HitPos)
	if Bullet.NoEffect then return end -- No clientside effect will be created for this bullet

	local Effect = EffectData()
	Effect:SetHitBox(Bullet.Index)
	Effect:SetStart(Bullet.Flight * 0.1)

	if Type == "Update" then
		if Hit > 0 then
			Effect:SetOrigin(HitPos)
		else
			Effect:SetOrigin(Bullet.Pos)
		end

		Effect:SetScale(Hit)
	else
		Effect:SetOrigin(Bullet.Pos)
		Effect:SetEntity(Entity(Bullet.Crate))
		Effect:SetScale(0)
	end

	util.Effect("ACF_Bullet_Effect", Effect, true, true)
end

function ACF.RemoveBullet(Bullet)
	local Index  = Bullet.Index

	Bullets[Index] = nil
	Unused[Index] = true

	if Bullet and Bullet.OnRemoved then
		Bullet:OnRemoved()
	end

	if not next(Bullets) then
		hook.Remove("Tick", "IterateBullets")
	end
end

function ACF.CalcBulletFlight(Bullet)
	if not Bullet.LastThink then return ACF.RemoveBullet(Bullet) end

	if Bullet.PreCalcFlight then
		Bullet:PreCalcFlight()
	end

	local DeltaTime = ACF.CurTime - Bullet.LastThink
	local Drag      = Bullet.Flight:GetNormalized() * (Bullet.DragCoef * Bullet.Flight:LengthSqr()) / ACF.DragDiv
	local Accel     = Bullet.Accel or Gravity

	Bullet.NextPos   = Bullet.Pos + (Bullet.Flight * ACF.Scale * DeltaTime)
	Bullet.Flight    = Bullet.Flight + (Accel - Drag) * DeltaTime
	Bullet.LastThink = ACF.CurTime
	Bullet.DeltaTime = DeltaTime

	ACF.DoBulletsFlight(Bullet)

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

	local Index = ACF.HighestIndex + 1

	if Index > ACF.IndexLimit then return end

	ACF.HighestIndex = Index

	return Index
end

local CalcFlight = ACF.CalcBulletFlight
local function IterateBullets()
	for _, Bullet in pairs(Bullets) do
		if not Bullet.HandlesOwnIteration then
			CalcFlight(Bullet)
		end
	end
end

function ACF.CreateBullet(BulletData)
	local Index = GetBulletIndex()

	if not Index then return end -- Too many bullets in the air

	local Bullet = table.Copy(BulletData)

	if not Bullet.Filter then
		Bullet.Filter = IsValid(Bullet.Gun) and { Bullet.Gun } or {}
	end

	Bullet.Index       = Index
	Bullet.LastThink   = ACF.CurTime
	Bullet.Fuze        = Bullet.Fuze and Bullet.Fuze + ACF.CurTime or nil -- Convert Fuze from fuze length to time of detonation
	Bullet.Mask        = MASK_SOLID -- Note: MASK_SHOT removed for smaller projectiles as it ignores armor
	Bullet.Ricochets   = 0
	Bullet.GroundRicos = 0
	Bullet.Color       = ColorRand(100, 255)

	if not next(Bullets) then
		hook.Add("Tick", "IterateBullets", IterateBullets)
	end

	Bullets[Index] = Bullet

	ACF.BulletClient(Bullet, "Init", 0)
	ACF.CalcBulletFlight(Bullet)

	return Bullet
end

local function OnImpact(Bullet, Trace, Type)
	local Data  = AmmoTypes[Bullet.Type]
	local Func  = Type == "World" and Data.WorldImpact or Data.PropImpact
	local Retry = Func(Data, Bullet, Trace)

	if Retry == "Penetrated" then
		if Bullet.OnPenetrated then
			Bullet.OnPenetrated(Bullet, Trace)
		end

		ACF.BulletClient(Bullet, "Update", 2, Trace.HitPos)
		ACF.DoBulletsFlight(Bullet)
	elseif Retry == "Ricochet" then
		if Bullet.OnRicocheted then
			Bullet.OnRicocheted(Bullet, Trace)
		end

		ACF.BulletClient(Bullet, "Update", 3, Trace.HitPos)
	else
		if Bullet.OnEndFlight then
			Bullet.OnEndFlight(Bullet, Trace)
		end

		ACF.BulletClient(Bullet, "Update", 1, Trace.HitPos)

		Data:OnFlightEnd(Bullet, Trace)
	end
end

function ACF.DoBulletsFlight(Bullet)
	if HookRun("ACF Bullet Flight", Bullet) == false then return end

	if Bullet.SkyLvL then
		if ACF.CurTime - Bullet.LifeTime > 30 then
			return ACF.RemoveBullet(Bullet)
		end

		if Bullet.NextPos.z + ACF.SkyboxGraceZone > Bullet.SkyLvL then
			if Bullet.Fuze and Bullet.Fuze <= ACF.CurTime then -- Fuze detonated outside map
				ACF.RemoveBullet(Bullet)
			end

			return
		elseif not util.IsInWorld(Bullet.NextPos) then
			return ACF.RemoveBullet(Bullet)
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

	local FlightRes, Filter = ACF.TraceF(FlightTr) -- Does not modify the bullet's original filter

	debugoverlay.Line(Bullet.Pos, FlightRes.HitPos, 15, Bullet.Color)
	-- Something was hit, let's make sure we're not phasing through armor
	if Bullet.LastPos and IsValid(FlightRes.Entity) and not GlobalFilter[FlightRes.Entity:GetClass()] then
		BackTrace.start  = Bullet.LastPos
		BackTrace.endpos = Bullet.Pos
		BackTrace.mask   = Bullet.Mask
		BackTrace.filter = Bullet.Filter

		ACF.TraceF(BackTrace) -- Does not modify the bullet's original filter

		-- There's something behind our trace, go back one tick
		if IsValid(BackRes.Entity) and not GlobalFilter[BackRes.Entity:GetClass()] then
			Bullet.NextPos = Bullet.Pos
			Bullet.Pos = Bullet.LastPos
			Bullet.LastPos = nil

			FlightTr.start 	= Bullet.Pos
			FlightTr.endpos = Bullet.NextPos

			FlightRes = ACF.Trace(FlightTr)
		else
			Bullet.Filter = Filter
		end
	else
		Bullet.Filter = Filter
	end

	if Bullet.Fuze and Bullet.Fuze <= ACF.CurTime then
		if not util.IsInWorld(Bullet.Pos) then -- Outside world, just delete
			return ACF.RemoveBullet(Bullet.Index)
		else
			if Bullet.OnEndFlight then
				Bullet.OnEndFlight(Bullet, nil)
			end

			local DeltaTime = Bullet.DeltaTime
			local DeltaFuze = ACF.CurTime - Bullet.Fuze
			local Lerp = DeltaFuze / DeltaTime
			--print(DeltaTime, DeltaFuze, Lerp)
			if FlightRes.Hit and Lerp < FlightRes.Fraction or true then -- Fuze went off before running into something
				local Pos = LerpVector(DeltaFuze / DeltaTime, Bullet.Pos, Bullet.NextPos)

				debugoverlay.Line(Bullet.Pos, Bullet.NextPos, 5, Color( 0, 255, 0 ))

				ACF.BulletClient(Bullet, "Update", 1, Pos)

				AmmoTypes[Bullet.Type]:OnFlightEnd(Bullet, Pos, Bullet.Flight:GetNormalized())
			end
		end
	end

	if FlightRes.Hit then
		if FlightRes.HitSky then
			if FlightRes.HitNormal == Vector(0, 0, -1) then
				Bullet.SkyLvL = FlightRes.HitPos.z
				Bullet.LifeTime = ACF.CurTime
			else
				ACF.RemoveBullet(Bullet)
			end
		else
			local Type = (FlightRes.HitWorld or FlightRes.Entity:CPPIGetOwner() == WORLD) and "World" or "Prop"

			OnImpact(Bullet, FlightRes, Type)
		end
	end
end

-- Backwards compatibility
ACF_BulletClient = ACF.BulletClient
ACF_CalcBulletFlight = ACF.CalcBulletFlight
ACF_DoBulletsFlight = ACF.DoBulletsFlight
ACF_RemoveBullet = ACF.RemoveBullet
ACF_CreateBullet = ACF.CreateBullet
