local ACF    = ACF
ACF.BulletEffect = ACF.BulletEffect or {}
ACF.Ballistics   = ACF.Ballistics or {}

local Ballistics = ACF.Ballistics
local Bullets    = ACF.BulletEffect
local Classes    = ACF.Classes

-- Bullets this client fired and predicted, by PredictionID, until the server tells us which index it gave them
Ballistics.PendingPredictions = Ballistics.PendingPredictions or {}

local Pending        = Ballistics.PendingPredictions
local LocalIndex     = 0
local LocalIndexBase = 100000 -- Far past the server's index limit, so a predicted bullet never takes a real index
local WallTrace      = { start = true, endpos = true, mask = MASK_SOLID_BRUSHONLY }

local function SpawnBulletEffect(Index, Crate, Pos, Flight, Hide)
	local Effect = EffectData()
	Effect:SetDamageType(Index)
	Effect:SetStart(Flight * 0.1)
	Effect:SetAttachment(Hide and 0 or 1)
	Effect:SetOrigin(Pos)
	Effect:SetScale(0)
	Effect:SetEntity(Crate)

	util.Effect("ACF_Bullet_Effect", Effect, true, true)

	return Bullets[Index]
end

-- Starts a bullet on this client right away instead of waiting for the server's, call it from predicted code
-- when IsFirstTimePredicted. The server's bullet needs the same PredictionID and Bullet.Predictable set
-- Round is the server's bullet data (ProjMass, Diameter, Ricochet), without it the bullet only stops at the map
function Ballistics.CreatePredictedBullet(PredictionID, Crate, Pos, Flight, Round)
	LocalIndex = LocalIndex % 10000 + 1

	local Bullet = SpawnBulletEffect(LocalIndexBase + LocalIndex, Crate, Pos, Flight)
	if not Bullet then return end

	Bullet.Predicted    = true
	Bullet.PredictionID = PredictionID
	Bullet.PredictedAt  = CurTime()
	Bullet.Round        = Round

	Pending[PredictionID] = Bullet

	return Bullet
end

-- Impacts, penetrations and ricochets of our predicted bullets, played the same way the server's effect would
local function UpdateBullet(Index)
	local Effect = EffectData()
	Effect:SetDamageType(Index)
	Effect:SetScale(net.ReadUInt(2))
	Effect:SetAttachment(net.ReadUInt(1))
	Effect:SetOrigin(net.ReadVector())
	Effect:SetStart(net.ReadVector() * 0.1)

	util.Effect("ACF_Bullet_Effect", Effect, true, true)
end

-- The server fired it too, so the predicted bullet takes its index and gets its impacts from now on
net.Receive("ACF_PredictedBullet", function()
	local IsUpdate = net.ReadBool()
	local Index    = net.ReadUInt(16)

	if IsUpdate then return UpdateBullet(Index) end

	local PredictionID = net.ReadDouble()
	local Crate        = Entity(net.ReadUInt(16))
	local Hide         = net.ReadBool()
	local Pos          = net.ReadVector()
	local Flight       = net.ReadVector()
	local Bullet       = Pending[PredictionID]

	Pending[PredictionID] = nil

	-- We didn't predict this one, so it's made the way the server's effect would have
	if not Bullet or Bullet.Removed or not IsValid(Bullet.Effect) then
		SpawnBulletEffect(Index, Crate, Pos, Flight, Hide)

		return
	end

	-- The server can reuse an index before we hear the old bullet is gone
	-- Its effect is cut loose from the index first, its Think would take our bullet down with it otherwise
	local Old = Bullets[Index]

	if Old and Old ~= Bullet then
		if IsValid(Old.Tracer) then Old.Tracer:Finish() end

		Old.Removed = true

		if IsValid(Old.Effect) then
			Old.Effect.Index = nil
			Old.Effect.Kill  = true
		end
	end

	Bullets[Bullet.Index] = nil

	Bullet.Index        = Index
	Bullet.Effect.Index = Index
	Bullets[Index]      = Bullet
end)

-- Shots the server never confirmed (it refused them, or hit a player instantly) are dropped
local function ExpirePredictions()
	if not next(Pending) then return end

	local Timeout = math.max(1, LocalPlayer():Ping() * 0.002 + 0.5)
	local Now     = CurTime()

	for PredictionID, Bullet in pairs(Pending) do
		if Now - Bullet.PredictedAt > Timeout then
			if IsValid(Bullet.Effect) then Bullet.Effect.Kill = true end

			Pending[PredictionID] = nil
		end
	end
end

-- Rounds that dig through or ricochet off the map like AP does on the server (CLASS:WorldImpact in ap.lua)
-- Other rounds just end where they hit the map
local PredictsMapHits = {
	["ACF.Ammunition.AP"]   = true,
	["ACF.Ammunition.APDS"] = true,
}

local HitEnd, HitPenetrated, HitRicochet = 1, 2, 3 -- Same as the server's bullet updates
local MatchDistance = 64 ^ 2 -- How close the server's hit has to be to count as the one we predicted

-- Runs the server's map hit code (world_pen_sh.lua) on a stand-in for the bullet, which has the round data it needs
-- Same rolls as the server's, since both come from the PredictionID
local function PredictMapHit(Bullet, Trace, RoundData)
	local Round = Bullet.Round
	if not Round or not PredictsMapHits[Bullet.AmmoType] then return false end

	local Proxy = {
		PredictionID = Bullet.PredictionID,
		WorldHits    = Bullet.WorldHits,
		GroundRicos  = Bullet.GroundRicos or 0,
		Flight       = Bullet.SimFlight,
		Ricochet     = Round.Ricochet,
		ProjMass     = Round.ProjMass,
		Diameter     = Round.Diameter,
		Filter       = {},
	}

	function Proxy:GetPenetration()
		return RoundData:GetPenetration(self)
	end

	local Result

	if ACF.Check(Trace.Entity) then
		Result = Ballistics.PenetrateMapEntity(Proxy, Trace)
	else
		Result = Ballistics.PenetrateGround(Proxy, Trace)
	end

	Bullet.WorldHits   = Proxy.WorldHits
	Bullet.GroundRicos = Proxy.GroundRicos

	return Result, Proxy
end

-- A predicted bullet runs ahead of the server's, so it would fly through walls until the server's update arrives
-- It works out the hit itself instead and shows it right away. Ending its flight, it waits where it hit for the server
-- The server's updates are matched against these afterwards, see Ballistics.MatchPrediction
local function HitMap(Bullet)
	WallTrace.start  = Bullet.SimPosLast
	WallTrace.endpos = Bullet.SimPos

	local Trace = util.TraceLine(WallTrace)
	if not Trace.Hit then return end

	local Effect = Bullet.Effect
	if not IsValid(Effect) then return end

	Bullet.SimPos = Trace.HitPos

	-- The server lets rounds leave through the sky, they just wait for it out of sight
	if Trace.HitSky then
		Bullet.Stopped    = true
		Effect.DrawEffect = false

		return
	end

	local RoundData = Classes.GetSubtypeByName("ACF.Ammunition.BaseAmmo", Bullet.AmmoType)
	if not RoundData then return end

	local Result, Proxy = PredictMapHit(Bullet, Trace, RoundData)
	local Predictions   = Bullet.Predictions or {}

	Bullet.Predictions = Predictions

	if Result == "Ricochet" then
		Bullet.SimFlight = Proxy.Flight

		RoundData:RicochetEffect(Effect, Bullet)

		Predictions[#Predictions + 1] = { Hit = HitRicochet, Pos = Trace.HitPos }
	elseif Result == "Penetrated" then
		Bullet.SimFlight = Proxy.Flight

		RoundData:PenetrationEffect(Effect, Bullet)

		Bullet.SimPos = Proxy.Pos or Proxy.NextPos or Trace.HitPos -- Out the other side

		Predictions[#Predictions + 1] = { Hit = HitPenetrated, Pos = Trace.HitPos }
	else
		Bullet.Stopped    = true
		Effect.DrawEffect = false -- Hides the round, and the tracer stops leaving sprites

		Effect:SetPos(Trace.HitPos)
		RoundData:ImpactEffect(Effect, Bullet)

		Predictions[#Predictions + 1] = { Hit = HitEnd, Pos = Trace.HitPos }
	end
end

-- Called by the bullet effect for each of the server's updates on our bullet, in order
-- True if it's the hit we predicted next, so the update has already been shown and our bullet already moved on
-- Once one doesn't match, the server's bullet went somewhere else (a prop, a player, a different roll) and its
-- updates take over the bullet for the rest of its flight
function Ballistics.MatchPrediction(Bullet, Hit, Origin)
	local Predictions = Bullet.Predictions
	if not Predictions then return false end

	local Next = table.remove(Predictions, 1)

	if Next and Next.Hit == Hit and Next.Pos:DistToSqr(Origin) < MatchDistance then return true end

	Bullet.Predictions = nil
	Bullet.Predicted   = nil -- No more map hits of its own, it's behind the server's bullet from here

	return false
end

local function BulletFlight(Bullet, DeltaTime)
	if Bullet.Stopped then return end

	local Drag       = Bullet.SimFlight:GetNormalized() *  (Bullet.DragCoef * Bullet.SimFlight:LengthSqr()) / ACF.DragDiv
	local Correction = 0.5 * (Bullet.Accel - Drag) * DeltaTime -- Double integrates constant acceleration for better positional accuracy

	Bullet.SimPosLast = Bullet.SimPos
	Bullet.SimPos     = Bullet.SimPos + ACF.Scale * DeltaTime * (Bullet.SimFlight + Correction) -- Calculates the next shell position
	Bullet.SimFlight  = Bullet.SimFlight + (Bullet.Accel - Drag) * DeltaTime -- Calculates the next shell vector

	if Bullet.Predicted then
		HitMap(Bullet)

		if Bullet.Stopped then return end
	end

	if IsValid(Bullet.Effect) then
		Bullet.Effect:ApplyMovement(Bullet)
	end
end

hook.Add("ACF_OnTick", "ACF_ManageBulletEffects", function(_, DeltaTime)
	ExpirePredictions()

	for _, Bullet in pairs(Bullets) do
		BulletFlight(Bullet, DeltaTime)
	end
end)
