function EFFECT:Init(Data)
	self.Origin = Data:GetOrigin()
	self.DirVec = Data:GetNormal()
	self.Radius = math.max(Data:GetRadius() * 0.02, 1)
	self.Emitter = ParticleEmitter(self.Origin)
	self.ParticleMul = LocalPlayer():GetInfoNum("acf_cl_particlemul", 1)

	for _ = 0, 3 * self.Radius * self.ParticleMul do
		local Smoke = self.Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), self.Origin)

		if Smoke then
			Smoke:SetVelocity((-self.DirVec + VectorRand() / 10) * math.random(50, 130 * self.Radius))
			Smoke:SetLifeTime(0)
			Smoke:SetDieTime(math.Rand(1, 2) * self.Radius / 3)
			Smoke:SetStartAlpha(math.Rand(50, 150))
			Smoke:SetEndAlpha(0)
			Smoke:SetStartSize(2 * self.Radius)
			Smoke:SetEndSize(15 * self.Radius)
			Smoke:SetRoll(math.Rand(150, 360))
			Smoke:SetRollDelta(math.Rand(-0.2, 0.2))
			Smoke:SetAirResistance(300)
			Smoke:SetGravity(Vector(math.random(-5, 5) * self.Radius, math.random(-5, 5) * self.Radius, -450))
			Smoke:SetColor(160, 160, 160)
		end
	end

	for _ = 0, 4 * self.Radius * self.ParticleMul do
		local Debris = self.Emitter:Add("effects/fleck_tile" .. math.random(1, 2), self.Origin)

		if Debris then
			Debris:SetVelocity((self.DirVec + VectorRand() / 10) * math.random(250 * self.Radius, 450 * self.Radius))
			Debris:SetLifeTime(0)
			Debris:SetDieTime(math.Rand(1.5, 3) * self.Radius / 3)
			Debris:SetStartAlpha(255)
			Debris:SetEndAlpha(0)
			Debris:SetStartSize(0.3 * self.Radius)
			Debris:SetEndSize(0.3 * self.Radius)
			Debris:SetRoll(math.Rand(0, 360))
			Debris:SetRollDelta(math.Rand(-3, 3))
			Debris:SetAirResistance(200)
			Debris:SetGravity(Vector(0, 0, -650))
			Debris:SetColor(120, 120, 120)
		end
	end

	for _ = 0, 5 * self.Radius * self.ParticleMul do
		local Embers = self.Emitter:Add("particles/flamelet" .. math.random(1, 5), self.Origin)

		if Embers then
			Embers:SetVelocity((self.DirVec + VectorRand() / 10) * math.random(50 * self.Radius, 300 * self.Radius))
			Embers:SetLifeTime(0)
			Embers:SetDieTime(math.Rand(0.3, 1) * self.Radius / 3)
			Embers:SetStartAlpha(255)
			Embers:SetEndAlpha(0)
			Embers:SetStartSize(1 * self.Radius)
			Embers:SetEndSize(0 * self.Radius)
			Embers:SetStartLength(5 * self.Radius)
			Embers:SetEndLength(0 * self.Radius)
			Embers:SetRoll(math.Rand(0, 360))
			Embers:SetRollDelta(math.Rand(-0.2, 0.2))
			Embers:SetAirResistance(20)
			Embers:SetGravity(Vector(0, 0, -650))
			Embers:SetColor(200, 200, 200)
		end
	end

	self.Emitter:Finish()

	local Effect = EffectData()
	Effect:SetOrigin(self.Origin)
	Effect:SetNormal(self.DirVec)
	Effect:SetScale(self.Radius * 50)
	Effect:SetRadius(0)

	util.Effect("ACF_Explosion", Effect)
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end