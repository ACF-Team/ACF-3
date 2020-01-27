-- init
ACF.Bullet = {} --when ACF is loaded, this table holds bullets
ACF.CurBulletIndex = 0 --used to track where to insert bullets
ACF.BulletIndexLimit = 1000 --The maximum number of bullets in flight at any one time. oldest existing bullets are overwritten if limit overflow
ACF.TraceFilter = { --entities that cause issue with acf and should be not be processed at all
	prop_vehicle_crane = true,
	prop_dynamic = true
}
ACF.SkyboxGraceZone = 100 --grace zone for the high angle fire

local TraceLine = util.TraceLine
local FlightRes = {}
local FlightTr  = { output = FlightRes }

local function HitClip(Ent, Pos)
	if not IsValid(Ent) or Ent.ClipData == nil or Ent:GetClass() ~= "prop_physics" or (Ent:GetPhysicsObject():GetVolume() == nil) then return false end -- makesphere

	local Clip
	local Normal
	local Origin

	for I = 1, #Ent.ClipData do
		Clip   = Ent.ClipData[I]
		Normal = Ent:LocalToWorldAngles(Clip.n):Forward()
		Origin = Ent:LocalToWorld(Ent:OBBCenter()) + Normal * Clip.d

		--debugoverlay.BoxAngles( origin, Vector(0,-24,-24), Vector(1,24,24), Ent:LocalToWorldAngles(Ent.ClipData[i]["n"]), 15, Color(255,0,0,32) )
		if Normal:Dot((Origin - Pos):GetNormalized()) > 0 then return true end
	end

	return false
end

local function Trace(TraceData)
	local T = TraceLine(TraceData)

	if T.HitNonWorld and HitClip(T.Entity, T.HitPos) then
		TraceData.filter[#TraceData.filter + 1] = T.Entity

		return Trace(TraceData)
	end

	--debugoverlay.Line(TraceData.start, T.HitPos, 30, ColorRand(100, 255), true)
	return T
end

-------------------------------------------------
ACF.Trace 		= Trace
ACF_CheckClips 	= HitClip
-------------------------------------------------

function ACF_CreateBullet(BulletData)
	ACF.CurBulletIndex = ACF.CurBulletIndex + 1 --Increment the index

	if ACF.CurBulletIndex > ACF.BulletIndexLimit then
		ACF.CurBulletIndex = 1
	end

	--Those are BulletData settings that are global and shouldn't change round to round
	local cvarGrav = GetConVar("sv_gravity")
	BulletData["Accel"] = Vector(0, 0, cvarGrav:GetInt() * -1)
	BulletData["LastThink"] = ACF.SysTime
	BulletData["FlightTime"] = 0
	BulletData["TraceBackComp"] = 0

	--BulletData.FiredTime = ACF.SysTime --same as fuse inittime, can combine when readding
	--BulletData.FiredPos = BulletData.Pos --when adding back in, update acfdamage roundimpact rico
	if type(BulletData["FuseLength"]) ~= "number" then
		BulletData["FuseLength"] = 0
	else
		--print("Has fuse")
		if BulletData["FuseLength"] > 0 then
			BulletData["InitTime"] = ACF.SysTime
		end
	end

	--Check the Gun's velocity and add a modifier to the flighttime so the traceback system doesn't hit the originating contraption if it's moving along the shell path
	if BulletData["Gun"]:IsValid() then
		BulletData["TraceBackComp"] = math.max(ACF_GetAncestor(BulletData["Gun"]):GetPhysicsObject():GetVelocity():Dot(BulletData["Flight"]:GetNormalized()), 0)

		--print(BulletData["TraceBackComp"])
	end

	BulletData["Filter"] = {BulletData["Gun"]}
	BulletData["Index"] = ACF.CurBulletIndex

	local Bullet = table.Copy(BulletData)

	ACF.Bullet[ACF.CurBulletIndex] = Bullet --Place the bullet at the current index pos
	ACF_BulletClient(ACF.CurBulletIndex, Bullet, "Init", 0)
	ACF_CalcBulletFlight(ACF.CurBulletIndex, Bullet)

	return Bullet
end

--global update function where acf updates ALL bullets at once--this runs once per tick, handling bullet physics for all bullets in table.
function ACF_ManageBullets()
	for Index, Bullet in pairs(ACF.Bullet) do
		if not Bullet.HandlesOwnIteration then
			ACF_CalcBulletFlight(Index, Bullet) --This is the bullet entry in the table, the Index var omnipresent refers to this
		end
	end
end

hook.Add("Tick", "ACF_ManageBullets", ACF_ManageBullets)

--removes the bullet from acf
function ACF_RemoveBullet(Index)
	local Bullet = ACF.Bullet[Index]
	ACF.Bullet[Index] = nil

	if Bullet and Bullet.OnRemoved then
		Bullet:OnRemoved()
	end
end

--handles non-terminal ballistics and fusing of bullets
function ACF_CalcBulletFlight(Index, Bullet, BackTraceOverride)
	-- perf concern: use direct function call stored on bullet over hook system.
	if Bullet.PreCalcFlight then
		Bullet:PreCalcFlight()
	end

	if not Bullet.LastThink then
		ACF_RemoveBullet(Index)
	end

	if BackTraceOverride then
		Bullet.FlightTime = 0
	end

	local DeltaTime = ACF.SysTime - Bullet.LastThink
	--actual motion of the bullet
	local Drag = Bullet.Flight:GetNormalized() * (Bullet.DragCoef * Bullet.Flight:LengthSqr()) / ACF.DragDiv
	Bullet.NextPos = Bullet.Pos + (Bullet.Flight * ACF.Scale * DeltaTime) --Calculates the next shell position
	Bullet.Flight = Bullet.Flight + (Bullet.Accel - Drag) * DeltaTime --Calculates the next shell vector
	Bullet.StartTrace = Bullet.Pos - Bullet.Flight:GetNormalized() * (math.min(ACF.PhysMaxVel * 0.025, Bullet.FlightTime * Bullet.Flight:Length() - Bullet.TraceBackComp * DeltaTime))
	--print(math.Round((Bullet.Pos-Bullet.StartTrace):Length(),1))
	--debugoverlay.Cross(Bullet.Pos,3,15,Color(255,255,255,32), true) --true start
	--debugoverlay.Box(Bullet.StartTrace,Vector(-2,-2,-2),Vector(2,2,2),15,Color(0,255,0,32), true) --backtrace start
	--debugoverlay.EntityTextAtPosition(Bullet.StartTrace, 0, "Tr", 15)
	--debugoverlay.EntityTextAtPosition(Bullet.Pos, 0, "Pos", 15)
	--debugoverlay.Line( Bullet.Pos+Vector(0,0,1), Bullet.StartTrace+Vector(0,0,1), 15, Color(0, 255, 255), true )
	--debugoverlay.Line( Bullet.NextPos+VectorRand(), Bullet.StartTrace+VectorRand(), 15, ColorRand(), true )
	--updating timestep timers
	Bullet.LastThink = ACF.SysTime
	Bullet.FlightTime = Bullet.FlightTime + DeltaTime
	ACF_DoBulletsFlight(Index, Bullet)

	-- perf concern: use direct function call stored on bullet over hook system.
	if Bullet.PostCalcFlight then
		Bullet:PostCalcFlight()
	end
end

--handles bullet terminal ballistics, fusing, and visclip checking
function ACF_DoBulletsFlight(Index, Bullet)
	local CanDo = hook.Run("ACF_BulletsFlight", Index, Bullet)
	if CanDo == false then return end

	if Bullet.FuseLength and Bullet.FuseLength > 0 then
		local Time = ACF.SysTime - Bullet.InitTime

		if Time > Bullet.FuseLength then
			--print("Explode")
			if not util.IsInWorld(Bullet.Pos) then
				ACF_RemoveBullet(Index)
			else
				-- nil was flightres, garbage data this early in code
				if Bullet.OnEndFlight then
					Bullet.OnEndFlight(Index, Bullet, nil)
				end

				ACF_BulletClient(Index, Bullet, "Update", 1, Bullet.Pos) -- defined at bottom
				ACF_BulletEndFlight = ACF.RoundTypes[Bullet.Type]["endflight"]
				ACF_BulletEndFlight(Index, Bullet, Bullet.Pos, Bullet.Flight:GetNormalized())
			end
		end
	end

	--if we're out of skybox, keep calculating position.  If we have too long out of skybox, remove bullet
	if Bullet.SkyLvL then
		--We don't want to calculate bullets that will never come back to map
		if (ACF.CurTime - Bullet.LifeTime) > 30 then
			ACF_RemoveBullet(Index)

			return
		end

		--We don't want rounds to hit the skybox top, but to pass through and come back down
		--add in a bit of grace zone
		if Bullet.NextPos.z + ACF.SkyboxGraceZone > Bullet.SkyLvL then
			Bullet.Pos = Bullet.NextPos
			--We do want rounds outside of the world but not skybox top to be deleted

			return
		elseif not util.IsInWorld(Bullet.NextPos) then
			ACF_RemoveBullet(Index)

			return
		else --We fall back to this default
			Bullet.SkyLvL = nil
			Bullet.LifeTime = nil
			Bullet.Pos = Bullet.NextPos
			Bullet.SkipNextHit = true

			return
		end
	end

	FlightTr.mask 	= Bullet.Caliber <= 0.3 and MASK_SHOT or MASK_SOLID -- cals 30mm and smaller will pass through things like chain link fences
	FlightTr.filter = Bullet.Filter -- any changes to bullet filter will be reflected in the trace
	FlightTr.start  = Bullet.StartTrace
	FlightTr.endpos = Bullet.NextPos + Bullet.Flight:GetNormalized() * (ACF.PhysMaxVel * 0.025)

	Trace(FlightTr)

	--bullet is told to ignore the next hit, so it does and resets flag
	if Bullet.SkipNextHit then
		if not FlightRes.StartSolid and not FlightRes.HitNoDraw then
			Bullet.SkipNextHit = nil
		end

		Bullet.Pos = Bullet.NextPos
		--bullet hit something that isn't world and is allowed to hit
	elseif FlightRes.HitNonWorld and not ACF.TraceFilter[FlightRes.Entity:GetClass()] then
		--don't process ACF.TraceFilter ents
		--If we hit stuff then send the resolution to the bullets damage function
		ACF_BulletPropImpact = ACF.RoundTypes[Bullet.Type]["propimpact"]
		local Retry = ACF_BulletPropImpact(Index, Bullet, FlightRes.Entity, FlightRes.HitNormal, FlightRes.HitPos, FlightRes.HitGroup)

		--If we should do the same trace again, then do so
		if Retry == "Penetrated" then
			if Bullet.OnPenetrated then
				Bullet.OnPenetrated(Index, Bullet, FlightRes)
			end

			ACF_BulletClient(Index, Bullet, "Update", 2, FlightRes.HitPos)
			ACF_DoBulletsFlight(Index, Bullet)
		elseif Retry == "Ricochet" then
			if Bullet.OnRicocheted then
				Bullet.OnRicocheted(Index, Bullet, FlightRes)
			end

			ACF_BulletClient(Index, Bullet, "Update", 3, FlightRes.HitPos)
			ACF_CalcBulletFlight(Index, Bullet, true)
		else --Else end the flight here
			if Bullet.OnEndFlight then
				Bullet.OnEndFlight(Index, Bullet, FlightRes)
			end

			ACF_BulletClient(Index, Bullet, "Update", 1, FlightRes.HitPos)
			ACF_BulletEndFlight = ACF.RoundTypes[Bullet.Type]["endflight"]
			ACF_BulletEndFlight(Index, Bullet, FlightRes.HitPos, FlightRes.HitNormal)
		end
	elseif FlightRes.HitWorld then
		--bullet hit the world
		--If we hit the world then try to see if it's thin enough to penetrate
		if not FlightRes.HitSky then
			ACF_BulletWorldImpact = ACF.RoundTypes[Bullet.Type]["worldimpact"]
			local Retry = ACF_BulletWorldImpact(Index, Bullet, FlightRes.HitPos, FlightRes.HitNormal)

			--if it is, we soldier on	
			if Retry == "Penetrated" then
				if Bullet.OnPenetrated then
					Bullet.OnPenetrated(Index, Bullet, FlightRes)
				end

				ACF_BulletClient(Index, Bullet, "Update", 2, FlightRes.HitPos)
				ACF_CalcBulletFlight(Index, Bullet, true) --The world ain't going to move, so we say True for the backtrace override
			elseif Retry == "Ricochet" then
				if Bullet.OnRicocheted then
					Bullet.OnRicocheted(Index, Bullet, FlightRes)
				end

				ACF_BulletClient(Index, Bullet, "Update", 3, FlightRes.HitPos)
				ACF_CalcBulletFlight(Index, Bullet, true)
			else --If not, end of the line, boyo
				if Bullet.OnEndFlight then
					Bullet.OnEndFlight(Index, Bullet, FlightRes)
				end

				ACF_BulletClient(Index, Bullet, "Update", 1, FlightRes.HitPos)
				ACF_BulletEndFlight = ACF.RoundTypes[Bullet.Type]["endflight"]
				ACF_BulletEndFlight(Index, Bullet, FlightRes.HitPos, FlightRes.HitNormal)
			end
		else --hit skybox
			--only if leaving top of skybox
			if FlightRes.HitNormal == Vector(0, 0, -1) then
				Bullet.SkyLvL = FlightRes.HitPos.z -- store the Z value where bullet left skybox, used to check world re-entry
				Bullet.LifeTime = ACF.CurTime
				Bullet.Pos = Bullet.NextPos
			else
				ACF_RemoveBullet(Index)
			end
		end
	else --bullet hit nothing, keep flying
		Bullet.Pos = Bullet.NextPos
	end
end

function ACF_BulletClient(Index, Bullet, Type, Hit, HitPos)
	if Type == "Update" then
		local Effect = EffectData()
		Effect:SetAttachment(Index) --Bulet Index
		Effect:SetStart(Bullet.Flight / 10) --Bullet Direction

		-- If there is a hit then set the effect pos to the impact pos instead of the retry pos
		if Hit > 0 then
			Effect:SetOrigin(HitPos) --Bullet Pos
		else
			Effect:SetOrigin(Bullet.Pos)
		end

		Effect:SetScale(Hit) --Hit Type 
		util.Effect("acf_bulleteffect", Effect, true, true)
	else
		local Effect = EffectData()

		Effect:SetAttachment(Index) --Bulet Index
		Effect:SetStart(Bullet.Flight / 10) --Bullet Direction
		Effect:SetOrigin(Bullet.Pos)
		Effect:SetEntity(Entity(Bullet["Crate"]))
		Effect:SetScale(0)
		util.Effect("acf_bulleteffect", Effect, true, true)
	end
end