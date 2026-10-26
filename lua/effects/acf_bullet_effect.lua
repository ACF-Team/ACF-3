
local ACF       = ACF
local Classes   = ACF.Classes
local Bullets   = ACF.BulletEffect
local Clock     = ACF.Utilities.Clock

local White = Vector(255, 255, 255)

-- Tracers burn at full brightness whatever the crate is painted, so only the hue is kept (black just burns white)
local function GetTracerColors(Color)
	local Max = math.max(Color.r, Color.g, Color.b)

	if Max < 8 then return White, White end

	local Glow = Vector(Color.r, Color.g, Color.b) * (255 / Max)

	return Glow, LerpVector(0.75, Glow, White) -- The core burns close to white
end

-- Control points are explained in the generator, acf_tracers.py
local function CreateTracer(Bullet, Pos, Color)
	local Effect = CreateParticleSystemNoEntity("acf_tracer", Pos)

	if not Effect then return end

	local Glow, Core = GetTracerColors(Color)

	Bullet.TracerSize = math.Clamp(Bullet.Caliber * 2.5, 3, 25)
	Bullet.TracerGlow = Glow
	Bullet.TracerCore = Core

	Effect:SetControlPoint(0, Pos)
	Effect:SetControlPoint(1, Pos)
	Effect:SetControlPoint(2, Vector(Bullet.TracerSize, 0, 0))
	Effect:SetControlPoint(3, Glow)
	Effect:SetControlPoint(4, Core)
	Effect:SetControlPoint(5, Glow)
	Effect:SetControlPoint(6, Core)
	Effect:SetControlPoint(7, Vector(1, 0, 0))

	return Effect
end

-- The round only moves once per tick, so the tracer is pushed ahead of it every frame to keep it smooth
local function UpdateTracer(Bullet)
	local Tracer = Bullet.Tracer

	if not Tracer or not Tracer:IsValid() then return end

	-- A predicted round that hit the map waits there for the server hidden, its tracer would lie on the ground otherwise
	local Draw = not Bullet.Stopped and Bullet.Effect.DrawEffect

	Tracer:SetShouldDraw(Draw)

	if not Draw then return end

	local Velocity = Bullet.SimFlight * ACF.Scale
	local Since    = math.min(CurTime() - Bullet.TracerTime, engine.TickInterval() * 2)
	local Head     = Bullet.SimPos + Velocity * Since
	local Length   = math.min(Bullet.TracerLength, Velocity:Length() * 0.004) -- Slow rounds don't streak as far

	Tracer:SetControlPoint(0, Head)
	Tracer:SetControlPoint(1, Head - Velocity:GetNormalized() * Length)

	-- How far away it looks, zooming in brings it closer
	local Distance = EyePos():Distance(Head) * math.tan(math.rad(LocalPlayer():GetFOV() * 0.5))

	-- Far away the streak fades out and the head grows so it stays a glowing dot instead of vanishing
	local Fade = 1 - math.Clamp((Distance - 2000) / 6000, 0, 0.85)
	local HeadScale = math.Clamp(Distance * 0.012 / (Bullet.TracerSize * 1.1), 1, 12)

	Tracer:SetControlPoint(3, Bullet.TracerGlow * Fade)
	Tracer:SetControlPoint(4, Bullet.TracerCore * Fade)
	Tracer:SetControlPoint(7, Vector(HeadScale, 0, 0))
end

local function RemoveTracer(Bullet)
	local Tracer = Bullet.Tracer

	if Tracer and Tracer:IsValid() then
		Tracer:StopEmissionAndDestroyImmediately()
	end

	Bullet.Tracer = nil
end

function EFFECT:Init(Data)
	self.Index = Data:GetDamageType()

	self:SetModel("models/acf/munitions/projectile.mdl")

	if not self.Index then
		self.Kill = true

		return
	end

	self.CreateTime = Clock.CurTime

	local CanDraw = Data:GetAttachment() > 0
	local Bullet  = Bullets[self.Index]
	local Flight  = Data:GetStart() * 10
	local Origin  = Data:GetOrigin()
	local Hit     = Data:GetScale()

	-- Scale encodes the hit type, so if it's 0 it's a new bullet, else it's an update so we need to remove the effect
	if Bullet and not Bullet.Removed and Hit > 0 then
		-- Our own predicted bullet already showed this hit and moved on, see ballistics_cl.lua
		if ACF.Ballistics.MatchPrediction(Bullet, Hit, Origin) then
			if Hit == 1 then Bullet.Effect.Kill = true end

			self:Remove()

			return
		end

		local RoundData = Classes.GetSubtypeByName("ACF.Ammunition.BaseAmmo", Bullet.AmmoType)

		-- Updating old effect with new values
		Bullet.Effect.DrawEffect = CanDraw
		Bullet.SimFlight = Flight
		Bullet.SimPos = Origin
		Bullet.Stopped = nil -- A predicted bullet waiting at a wall carries on from here

		if Hit == 1 then
			-- Bullet has reached end of flight, remove old effect
			RoundData:ImpactEffect(Bullet.Effect, Bullet)

			Bullet.Effect.Kill = true
		elseif Hit == 2 then
			-- Bullet penetrated, don't remove old effect
			RoundData:PenetrationEffect(Bullet.Effect, Bullet)
		elseif Hit == 3 then
			-- Bullet ricocheted, don't remove old effect
			RoundData:RicochetEffect(Bullet.Effect, Bullet)
		end

		-- We don't need this new effect, so we just remove it
		self:Remove()
	else
		local Crate = Data:GetEntity()

		--TODO: Check if it is actually a crate
		if not IsValid(Crate) then
			self.Kill = true

			return
		end

		-- TODO: Force crates to network and store this information on the client when they're created
		local Tracer  = Crate:GetNW2Float("Tracer") > 0
		local Caliber = Crate:GetNW2Float("Caliber", 10)
		local BulletData = {
			Index         = self.Index,
			Crate         = Crate,
			SimFlight     = Flight,
			SimPos        = Origin,
			SimPosLast    = Origin,
			Caliber       = Caliber,
			RoundMass     = Crate:GetNW2Float("ProjMass", 10),
			FillerMass    = Crate:GetNW2Float("FillerMass"),
			WPMass        = Crate:GetNW2Float("WPMass"),
			DragCoef      = Crate:GetNW2Float("DragCoef", 1),
			AmmoType      = Crate:GetNW2String("AmmoType", "ACF.Ammunition.AP"),
			TracerTime    = CurTime(),
			TracerLength  = math.Clamp(Caliber * 40, 60, 250),
			Color         = Tracer and Crate:GetColor() or nil,
			Accel         = Crate:GetNW2Vector("Accel", ACF.Gravity),
			LastThink     = Clock.CurTime,
			Effect        = self,
		}

		if Tracer then
			BulletData.Tracer = CreateTracer(BulletData, Origin, BulletData.Color)
		end

		-- The index can be reused before we're told the old bullet is gone, so its tracer has to go with it
		if Bullet then
			RemoveTracer(Bullet)
		end

		--Add all that data to the bullet table, overwriting if needed
		Bullets[self.Index] = BulletData
		self.Bullet = BulletData

		-- Set model and bodygroup based on ammo type
		local FlightModel = Crate:GetNW2String("FlightModel", "")
		if FlightModel ~= "" then
			self:SetModel(FlightModel)
			self:SetBodygroup(0, Crate:GetNW2Int("FlightBodygroup", 0))
		end

		self:SetPos(Origin)
		self:SetAngles(Flight:Angle())
		self:SetModelScale(Caliber * 0.1, 0)

		self.DrawEffect = CanDraw

		hook.Run("ACF_OnCreateBulletEffect", self, BulletData)
	end
end

function EFFECT:Think()
	local Bullet = self.Bullet

	if Bullet and not self.Kill and Bullets[self.Index] == Bullet and self.CreateTime > Clock.CurTime - 45 then
		UpdateTracer(Bullet)

		return true
	end

	if Bullet then
		RemoveTracer(Bullet)

		Bullet.Removed = true

		if Bullets[self.Index] == Bullet then
			Bullets[self.Index] = nil
		end
	end

	return false
end

function EFFECT:OnRemove()
	if self.Bullet then
		RemoveTracer(self.Bullet)
	end
end

function EFFECT:ApplyMovement(Bullet)
	local Position = Bullet.SimPos
	if math.abs(Position.x) > 16380 or math.abs(Position.y) > 16380 or Position.z < -16380 then
		self.Kill = true
		return
	end

	--Moving the effect to the calculated position
	if Position.z < 16380 then
		self:SetPos(Position)
		self:SetAngles(Bullet.SimFlight:Angle())
	end

	local Tracer = Bullet.Tracer

	if Tracer and Tracer:IsValid() then
		Bullet.TracerTime = CurTime()

		Tracer:SetShouldDraw(self.DrawEffect)
		UpdateTracer(Bullet)
	end
end

function EFFECT:Render()
	if not self.DrawEffect then return end

	self:DrawModel()
end