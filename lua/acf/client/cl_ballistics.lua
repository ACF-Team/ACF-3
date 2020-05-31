ACF.BulletEffect = ACF.BulletEffect or {}

local TraceLine = util.TraceLine

local function HitClip(Ent, Pos)
	if not IsValid(Ent) then return false end
	if Ent.ClipData == nil then return false end -- Doesn't have clips
	if Ent:GetClass() ~= "prop_physics" then return false end -- Only care about props

	local Center = Ent:LocalToWorld(Ent:OBBCenter())

	for I = 1, #Ent.ClipData do
		local Clip 	 = Ent.ClipData[I]
		local Normal = Ent:LocalToWorldAngles(Clip[1]):Forward()
		local Origin = Center + Normal * Clip[2]

		if Normal:Dot((Origin - Pos):GetNormalized()) > 0 then return true end
	end

	return false
end

local function Trace(TraceData, Filter) -- Pass true on filter to have Trace make it's own copy of TraceData.filter to modify
	if Filter == true then
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

	if Filter then
		TraceData.filter = Filter
	end

	return T
end

local function BulletFlight(Bullet)
	local DeltaTime = CurTime() - Bullet.LastThink
	local Drag = Bullet.SimFlight:GetNormalized() *  (Bullet.DragCoef * Bullet.SimFlight:Length() ^ 2 ) / ACF.DragDiv

	Bullet.SimPosLast = Bullet.SimPos
	Bullet.SimPos = Bullet.SimPos + (Bullet.SimFlight * ACF.Scale * DeltaTime)		--Calculates the next shell position
	Bullet.SimFlight = Bullet.SimFlight + (Bullet.Accel - Drag) * DeltaTime			--Calculates the next shell vector

	if IsValid(Bullet.Effect) then
		Bullet.Effect:ApplyMovement(Bullet)
	end

	--debugoverlay.Line(Bullet.SimPosLast, Bullet.SimPos, 15, Color(255, 255, 0))
	Bullet.LastThink = CurTime()
end

hook.Add("Think", "ACF_ManageBulletEffects", function()
	for Index, Bullet in pairs(ACF.BulletEffect) do
		--This is the bullet entry in the table, the omnipresent Index var refers to this
		BulletFlight(Bullet, Index)
	end
end)

ACF_SimBulletFlight = BulletFlight
ACF_CheckClips = HitClip
ACF.Trace = Trace
