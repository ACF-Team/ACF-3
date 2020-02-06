function EFFECT:Init(Data)
	self.Index = Data:GetAttachment()

	self:SetModel("models/munitions/round_100mm_shot.mdl")

	if not self.Index then
		self.Kill = true

		return
	end

	self.CreateTime = CurTime()

	local Bullet = ACF.BulletEffect[self.Index]
	local Flight = Data:GetStart() * 10
	local Origin = Data:GetOrigin()
	local Hit = Data:GetScale()

	-- Scale encodes the hit type, so if it's 0 it's a new bullet, else it's an update so we need to remove the effect
	if Bullet and Hit > 0 then
		local RoundData = ACF.RoundTypes[Bullet.AmmoType]

		-- Updating old effect with new values
		Bullet.SimFlight = Flight
		Bullet.SimPos = Origin

		if Hit == 1 then
			-- Bullet has reached end of flight, remove old effect
			RoundData.endeffect(Bullet.Effect, Bullet)

			Bullet.Effect.Kill = true
		elseif Hit == 2 then
			-- Bullet penetrated, don't remove old effect
			RoundData.pierceeffect(Bullet.Effect, Bullet)
		elseif Hit == 3 then
			-- Bullet ricocheted, don't remove old effect
			RoundData.ricocheteffect(Bullet.Effect, Bullet)
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

		local Tracer = Crate:GetNWFloat("Tracer") > 0
		local BulletData = {
			Crate = Crate,
			SimFlight = Flight,
			SimPos = Origin,
			SimPosLast = Origin,
			Caliber = Crate:GetNWFloat("Caliber", 10),
			RoundMass = Crate:GetNWFloat("ProjMass", 10),
			FillerMass = Crate:GetNWFloat("FillerMass"),
			WPMass = Crate:GetNWFloat("WPMass"),
			DragCoef = Crate:GetNWFloat("DragCoef", 1),
			AmmoType = Crate:GetNWString("AmmoType", "AP"),
			Tracer = Tracer and ParticleEmitter(Origin) or nil,
			TracerColour = Tracer and Crate:GetColor() or nil,
			Accel = Crate:GetNWVector("Accel", Vector(0, 0, -600)),
			LastThink = CurTime(),
			Effect = self,
		}

		--Add all that data to the bullet table, overwriting if needed
		ACF.BulletEffect[self.Index] = BulletData

		local CustomEffect = hook.Run("ACF_BulletEffect", BulletData.AmmoType)

		if CustomEffect then
			self.ApplyMovement = CustomEffect
		end
	end
end

function EFFECT:Think()
	if not self.Kill and self.CreateTime > CurTime() - 30 then return true end

	local Bullet = self.Index and ACF.BulletEffect[self.Index]

	if Bullet then
		if IsValid(Bullet.Tracer) then
			Bullet.Tracer:Finish()
		end

		ACF.BulletEffect[self.Index] = nil
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

	if Bullet.Tracer and IsValid(Bullet.Tracer) then
		local DeltaPos = Position - Bullet.SimPosLast
		local Length = math.max(DeltaPos:Length() * 2, 1)
		local MaxSprites = 2 --math.min(math.floor(math.max(Bullet.Caliber/5,1)*1.333)+1,5)
		local Light = Bullet.Tracer:Add("sprites/acf_tracer.vmt", Position) -- - DeltaPos )

		if Light then
			local Color = Bullet.TracerColour

			Light:SetAngles(Bullet.SimFlight:Angle())
			Light:SetVelocity(Bullet.SimFlight:GetNormalized()) --Vector() ) --Bullet.SimFlight )
			Light:SetColor(Color.r, Color.g, Color.b)
			Light:SetDieTime(math.Clamp(CurTime() - self.CreateTime, 0.075, 0.15)) -- 0.075, 0.1
			Light:SetStartAlpha(255)
			Light:SetEndAlpha(155)
			Light:SetStartSize(15 * Bullet.Caliber) -- 5
			Light:SetEndSize(1) --15*Bullet.Caliber
			Light:SetStartLength(Length)
			Light:SetEndLength(1) --Length
		end

		for i = 1, MaxSprites do
			local Smoke = Bullet.Tracer:Add("particle/smokesprites_000" .. math.random(1, 9), Position - (DeltaPos * i / MaxSprites))

			if Smoke then
				Smoke:SetAngles(Bullet.SimFlight:Angle())
				Smoke:SetVelocity(Bullet.SimFlight * 0.05)
				Smoke:SetColor(200, 200, 200)
				Smoke:SetDieTime(0.6) -- 1.2
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
	local Bullet = ACF.BulletEffect[self.Index]

	if Bullet then
		self:SetModelScale(Bullet.Caliber * 0.1, 0)
		self:DrawModel()
	end
end