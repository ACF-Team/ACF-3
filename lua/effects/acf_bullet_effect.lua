
local ACF       = ACF
local AmmoTypes = ACF.Classes.AmmoTypes
local Bullets   = ACF.BulletEffect
local Clock     = ACF.Utilities.Clock

function EFFECT:Init(Data)
	self.Index = Data:GetDamageType()

	self:SetModel("models/munitions/round_100mm_shot.mdl")

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
		local RoundData = AmmoTypes.Get(Bullet.AmmoType)

		-- Updating old effect with new values
		Bullet.Effect.DrawEffect = CanDraw
		Bullet.SimFlight = Flight
		Bullet.SimPos = Origin

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
		local Tracer = Crate:GetNW2Float("Tracer") > 0
		local BulletData = {
			Index      = self.Index,
			Crate      = Crate,
			SimFlight  = Flight,
			SimPos     = Origin,
			SimPosLast = Origin,
			Caliber    = Crate:GetNW2Float("Caliber", 10),
			RoundMass  = Crate:GetNW2Float("ProjMass", 10),
			FillerMass = Crate:GetNW2Float("FillerMass"),
			WPMass     = Crate:GetNW2Float("WPMass"),
			DragCoef   = Crate:GetNW2Float("DragCoef", 1),
			AmmoType   = Crate:GetNW2String("AmmoType", "AP"),
			Tracer     = Tracer and ParticleEmitter(Origin) or nil,
			Color      = Tracer and Crate:GetColor() or nil,
			Accel      = Crate:GetNW2Vector("Accel", ACF.Gravity),
			LastThink  = Clock.CurTime,
			Effect     = self,
		}

		--Add all that data to the bullet table, overwriting if needed
		Bullets[self.Index] = BulletData

		self:SetPos(Origin)
		self:SetAngles(Flight:Angle())
		self:SetModelScale(BulletData.Caliber * 0.1, 0)

		self.DrawEffect = CanDraw

		local CustomEffect = hook.Run("ACF_BulletEffect", BulletData.AmmoType)

		if CustomEffect then
			self.ApplyMovement = CustomEffect
		end
	end
end

function EFFECT:Think()
	local Bullet = Bullets[self.Index]

	if Bullet and not self.Kill and self.CreateTime > Clock.CurTime - 45 then return true end

	if Bullet then
		if IsValid(Bullet.Tracer) then
			Bullet.Tracer:Finish()
		end

		Bullet.Removed = true

		Bullets[self.Index] = nil
	end

	return false
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

	if not self.DrawEffect then return end

	if Bullet.Tracer and IsValid(Bullet.Tracer) then
		local DeltaPos = Position - Bullet.SimPosLast
		local Length = math.max(DeltaPos:Length() * 2, 1)
		local MaxSprites = 2
		local Light = Bullet.Tracer:Add("sprites/acf_tracer.vmt", Position)

		if Light then
			local Color = Bullet.Color

			Light:SetAngles(Bullet.SimFlight:Angle())
			Light:SetVelocity(Bullet.SimFlight:GetNormalized())
			Light:SetColor(Color.r, Color.g, Color.b)
			Light:SetDieTime(0.075)
			Light:SetStartAlpha(255)
			Light:SetEndAlpha(0)
			Light:SetStartSize(Bullet.Caliber * 15)
			Light:SetEndSize(Bullet.Caliber * 15)
			Light:SetStartLength(Length)
			Light:SetEndLength(Length)
		end

		for i = 1, MaxSprites do
			local Smoke = Bullet.Tracer:Add("particle/smokesprites_000" .. math.random(1, 9), Position - (DeltaPos * i / MaxSprites))

			if Smoke then
				Smoke:SetAngles(Bullet.SimFlight:Angle())
				Smoke:SetVelocity(Bullet.SimFlight * 0.05)
				Smoke:SetColor(200, 200, 200)
				Smoke:SetDieTime(0.6)
				Smoke:SetStartAlpha(10)
				Smoke:SetEndAlpha(0)
				Smoke:SetStartSize(1)
				Smoke:SetEndSize(Length * Bullet.Caliber * 0.0025)
				Smoke:SetRollDelta(0.1)
				Smoke:SetAirResistance(150)
				Smoke:SetGravity(Vector(0, 0, 20))
			end
		end
	end
end

function EFFECT:Render()
	if not self.DrawEffect then return end

	self:DrawModel()
end