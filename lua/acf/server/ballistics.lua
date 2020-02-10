ACF.Bullet 			 = {}
ACF.CurBulletIndex   = 0
ACF.BulletIndexLimit = 1000
ACF.SkyboxGraceZone  = 100

local TraceLine 	= util.TraceLine
local FlightRes 	= {}
local FlightTr  	= { output = FlightRes }
local GlobalFilter 	= ACF.GlobalFilter

local function HitClip(Ent, Pos)
	if not IsValid(Ent) or Ent.ClipData == nil or Ent:GetClass() ~= "prop_physics" or (Ent:GetPhysicsObject():GetVolume() == nil) then return false end
	local Clip
	local Normal
	local Origin

	for I = 1, #Ent.ClipData do
		Clip = Ent.ClipData[I]
		Normal = Ent:LocalToWorldAngles(Clip.n):Forward()
		Origin = Ent:LocalToWorld(Ent:OBBCenter()) + Normal * Clip.d
		if Normal:Dot((Origin - Pos):GetNormalized()) > 0 then return true end
	end

	return false
end

local function Trace(TraceData, Filter)
	if not Filter then
		Filter = TraceData.filter
		local NewFilter = {}

		for I = 1, #Filter do
			NewFilter[I] = Filter[I]
		end

		TraceData.filter = NewFilter
	end

	local T = TraceLine(TraceData)

	if T.HitNonWorld and HitClip(T.Entity, T.HitPos) then
		TraceData.filter[#TraceData.filter + 1] = T.Entity

		return Trace(TraceData, Filter)
	end

	if Filter and Filter ~= true then
		TraceData.filter = Filter
	end

	return T
end

ACF.Trace = Trace
ACF_CheckClips = HitClip

function ACF_CreateBullet(BulletData)
	ACF.CurBulletIndex = ACF.CurBulletIndex + 1
	if ACF.CurBulletIndex > ACF.BulletIndexLimit then ACF.CurBulletIndex = 1 end

	BulletData.Accel 		 = Vector(0, 0, GetConVar("sv_gravity"):GetInt() * -1)
	BulletData.LastThink 	 = ACF.SysTime
	BulletData.FlightTime 	 = 0
	BulletData.TraceBackComp = 0

	if type(BulletData.FuseLength) ~= "number" then
		BulletData.FuseLength = 0
	else
		if BulletData.FuseLength > 0 then
			BulletData.InitTime = ACF.SysTime
		end
	end

	if BulletData.Gun:IsValid() then
		BulletData.TraceBackComp = math.max(ACF_GetAncestor(BulletData.Gun):GetPhysicsObject():GetVelocity():Dot(BulletData.Flight:GetNormalized()), 0)
	end

	BulletData.Filter = {BulletData.Gun}
	BulletData.Index = ACF.CurBulletIndex
	local Bullet = table.Copy(BulletData)
	ACF.Bullet[ACF.CurBulletIndex] = Bullet
	ACF_BulletClient(ACF.CurBulletIndex, Bullet, "Init", 0)
	ACF_CalcBulletFlight(ACF.CurBulletIndex, Bullet)

	return Bullet
end

function ACF_ManageBullets()
	for Index, Bullet in pairs(ACF.Bullet) do
		if not Bullet.HandlesOwnIteration then
			ACF_CalcBulletFlight(Index, Bullet)
		end
	end
end

hook.Add("Tick", "ACF_ManageBullets", ACF_ManageBullets)

function ACF_RemoveBullet(Index)
	local Bullet = ACF.Bullet[Index]
	ACF.Bullet[Index] = nil

	if Bullet and Bullet.OnRemoved then
		Bullet:OnRemoved()
	end
end

function ACF_CalcBulletFlight(Index, Bullet, BackTraceOverride)
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
	local Drag = Bullet.Flight:GetNormalized() * (Bullet.DragCoef * Bullet.Flight:LengthSqr()) / ACF.DragDiv
	Bullet.NextPos = Bullet.Pos + (Bullet.Flight * ACF.Scale * DeltaTime)
	Bullet.Flight = Bullet.Flight + (Bullet.Accel - Drag) * DeltaTime
	Bullet.StartTrace = Bullet.Pos - Bullet.Flight:GetNormalized() * (math.min(ACF.PhysMaxVel * 0.025, Bullet.FlightTime * Bullet.Flight:Length() - Bullet.TraceBackComp * DeltaTime))
	Bullet.LastThink = ACF.SysTime
	Bullet.FlightTime = Bullet.FlightTime + DeltaTime
	ACF_DoBulletsFlight(Index, Bullet)

	if Bullet.PostCalcFlight then
		Bullet:PostCalcFlight()
	end
end

function ACF_DoBulletsFlight(Index, Bullet)
	local CanDo = hook.Run("ACF_BulletsFlight", Index, Bullet)
	if CanDo == false then return end

	if Bullet.FuseLength and Bullet.FuseLength > 0 then
		local Time = ACF.SysTime - Bullet.InitTime

		if Time > Bullet.FuseLength then
			if not util.IsInWorld(Bullet.Pos) then
				ACF_RemoveBullet(Index)
			else
				if Bullet.OnEndFlight then
					Bullet.OnEndFlight(Index, Bullet, nil)
				end

				ACF_BulletClient(Index, Bullet, "Update", 1, Bullet.Pos)
				ACF_BulletEndFlight = ACF.RoundTypes[Bullet.Type].endflight
				ACF_BulletEndFlight(Index, Bullet, Bullet.Pos, Bullet.Flight:GetNormalized())
			end
		end
	end

	if Bullet.SkyLvL then
		if (ACF.CurTime - Bullet.LifeTime) > 30 then
			ACF_RemoveBullet(Index)

			return
		end

		if Bullet.NextPos.z + ACF.SkyboxGraceZone > Bullet.SkyLvL then
			Bullet.Pos = Bullet.NextPos

			return
		elseif not util.IsInWorld(Bullet.NextPos) then
			ACF_RemoveBullet(Index)

			return
		else
			Bullet.SkyLvL = nil
			Bullet.LifeTime = nil
			Bullet.Pos = Bullet.NextPos
			Bullet.SkipNextHit = true

			return
		end
	end

	FlightTr.mask = Bullet.Caliber <= 0.3 and MASK_SHOT or MASK_SOLID
	FlightTr.filter = Bullet.Filter
	FlightTr.start = Bullet.StartTrace
	FlightTr.endpos = Bullet.NextPos + Bullet.Flight:GetNormalized() * (ACF.PhysMaxVel * 0.025)
	Trace(FlightTr, true)

	if Bullet.SkipNextHit then
		if not FlightRes.StartSolid and not FlightRes.HitNoDraw then
			Bullet.SkipNextHit = nil
		end

		Bullet.Pos = Bullet.NextPos
	elseif FlightRes.HitNonWorld and not GlobalFilter[FlightRes.Entity:GetClass()] then
		ACF_BulletPropImpact = ACF.RoundTypes[Bullet.Type].propimpact
		local Retry = ACF_BulletPropImpact(Index, Bullet, FlightRes.Entity, FlightRes.HitNormal, FlightRes.HitPos, FlightRes.HitGroup)

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
		else
			if Bullet.OnEndFlight then
				Bullet.OnEndFlight(Index, Bullet, FlightRes)
			end

			ACF_BulletClient(Index, Bullet, "Update", 1, FlightRes.HitPos)
			ACF_BulletEndFlight = ACF.RoundTypes[Bullet.Type].endflight
			ACF_BulletEndFlight(Index, Bullet, FlightRes.HitPos, FlightRes.HitNormal)
		end
	elseif FlightRes.HitWorld then
		if not FlightRes.HitSky then
			ACF_BulletWorldImpact = ACF.RoundTypes[Bullet.Type].worldimpact
			local Retry = ACF_BulletWorldImpact(Index, Bullet, FlightRes.HitPos, FlightRes.HitNormal)

			if Retry == "Penetrated" then
				if Bullet.OnPenetrated then
					Bullet.OnPenetrated(Index, Bullet, FlightRes)
				end

				ACF_BulletClient(Index, Bullet, "Update", 2, FlightRes.HitPos)
				ACF_CalcBulletFlight(Index, Bullet, true)
			elseif Retry == "Ricochet" then
				if Bullet.OnRicocheted then
					Bullet.OnRicocheted(Index, Bullet, FlightRes)
				end

				ACF_BulletClient(Index, Bullet, "Update", 3, FlightRes.HitPos)
				ACF_CalcBulletFlight(Index, Bullet, true)
			else
				if Bullet.OnEndFlight then
					Bullet.OnEndFlight(Index, Bullet, FlightRes)
				end

				ACF_BulletClient(Index, Bullet, "Update", 1, FlightRes.HitPos)
				ACF_BulletEndFlight = ACF.RoundTypes[Bullet.Type].endflight
				ACF_BulletEndFlight(Index, Bullet, FlightRes.HitPos, FlightRes.HitNormal)
			end
		else
			if FlightRes.HitNormal == Vector(0, 0, -1) then
				Bullet.SkyLvL = FlightRes.HitPos.z
				Bullet.LifeTime = ACF.CurTime
				Bullet.Pos = Bullet.NextPos
			else
				ACF_RemoveBullet(Index)
			end
		end
	else
		Bullet.Pos = Bullet.NextPos
	end
end

function ACF_BulletClient(Index, Bullet, Type, Hit, HitPos)
	local Effect = EffectData()
	Effect:SetAttachment(Index)
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